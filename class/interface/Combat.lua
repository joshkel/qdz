-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- ToME - Tales of Middle-Earth
-- Copyright (C) 2009, 2010, 2011, 2012, 2013 Nicolas Casalini
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

require "engine.class"
local DamageType = require "engine.DamageType"
local Map = require "engine.Map"
local Target = require "engine.Target"
local Talents = require "engine.interface.ActorTalents"
local Qi = require "mod.class.interface.Qi"
local GameRules = require "mod.class.GameRules"

--- Interface to add ToME combat system
module(..., package.seeall, class.make)

--- Represents any kind of skill check: attack versus defense, etc.  Not
--- combat-specific, although it seems simplest to keep it here with related
--- mechanics.
---
--- This currently uses a logistic distribution.  See
--- http://en.wikipedia.org/wiki/Logistic_distribution and
--- http://stackoverflow.com/a/3955904/25507.  A logistic distribution is
--- similar to the standard distribution but has heavier tails (i.e., slower
--- than exponential dropoff).  Logistic and normal distributions are both
--- examples of sigmoid distributions.
function _M:skillCheck(skill, difficulty)
    -- A logistic distribution is defined by two parameters: scale and mean.
    -- Use skill for the mean.  Use a scale (analogous to standard deviation) of
    -- 5 to give results somewhat similar to D20.
    local val = rng.float(0, 1)
    local result = skill + 5 * math.log(val / (1 - val))

    -- Limit values to +/- 100 * s so that we don't have to deal with infinity
    -- elsewhere in the code.
    result = math.min(result, skill + 5 * 100)
    result = math.max(result, skill - 5 * 100)

    print(("Skill check: %f against %f, %f chance of success, result %f, %s"):format(
        skill, difficulty, self:skillChanceOfSuccess(skill, difficulty), result,
        result >= difficulty and "SUCCESS" or "FAILURE"))

    return result >= difficulty, result
end

--- Gets the chance of success for the given skillCheck, as a percentage,
--- without considering the +/- 100 limit in skillCheck.
function _M:skillChanceOfSuccess(skill, difficulty)
    return 50 + 50 * math.tanh((skill - difficulty) / (2 * 5))
end

--- Several talents express their effectiveness as a percentage level; this
--- function calculates that percentage level.  E.g., for a base percentage of
--- 50, this results in a percentage of 50 at talent 1, 75 at talent 2, etc.
function _M:talentPercentage(talent, base_percentage, stat)
    stat = stat or 10
    return (1 - math.pow(1 - base_percentage / 100, self:getTalentLevel(talent) * stat / 10)) * 100
end

function _M:movementSpeed()
    return 1 / self.movement_speed
end

--- Gets resistances for the given damage type. Resistances are a tuple
--- giving a flat amount to subtract then a multiple for the remainder.
function _M:combatResist(type)
    if not self.resists[type] then return 0, 1 end
    return self.resists[type], math.pow(0.9, self.resists[type])
end

--- Modifies the given combat table by mod (another table), returning the modified
--- combat table.
function _M:combatMod(combat, mod)
    local result = table.clone(combat)
    for k, v in pairs(mod) do
        if type(v) == 'number' then 
            result[k] = (result[k] or 0) + v
        end
    end
    return result
end

--- Checks what to do with the target.
--- Talk? Attack? Displace?
---
--- NOTE that this may be called by AI functions and so on (while checking
--- "block_move"), so be careful what it does.
function _M:bumpInto(target)
    local reaction = self:reactionToward(target)

    -- Walk past unconscious foes instead of continuing to brutalize them.
    if self:isTalentActive(self.T_BLESSING_VIRTUE) and not self:getTalentFromId(self.T_BLESSING_VIRTUE).canKill(self, target) and target:hasEffect(target.EFF_UNCONSCIOUS) then
        reaction = 0
    end

    if reaction < 0 or (self:attr("confused") and rng.percent(self.confused)) then
        -- FIXME: Need more detail (lhand versus rhand)
        self.last_action = 'attack'
        local speed = self:attackTarget(target)
        self.last_action = nil
        if not speed then return end
        self:useEnergy(game.energy_to_act * speed)
    elseif reaction >= 0 then
        if self.move_others then
            if target.move_others and self ~= game.player then return end

            -- Displace
            game.level.map:remove(self.x, self.y, Map.ACTOR)
            game.level.map:remove(target.x, target.y, Map.ACTOR)
            game.level.map(self.x, self.y, Map.ACTOR, target)
            game.level.map(target.x, target.y, Map.ACTOR, self)
            self.x, self.y, target.x, target.y = target.x, target.y, self.x, self.y
            self:useEnergy(game.energy_to_act * self:movementSpeed())
            self.did_use_energy = true
        end
    end
end

--- Makes the death happen!
function _M:attackTarget(target, damtype, damargs, mult)
    local speed
    local hit

    -- TODO: Too much duplication, both in the following code and in alternate methods of attack (kick, bash, ...)

    if not speed then
        if self:getInven(self.INVEN_RHAND) then
            for i, o in ipairs(self:getInven(self.INVEN_RHAND)) do
                if o.combat and not target.dead then
                    local s, h = self:attackTargetWith(target, o.combat, damtype, damargs, mult)
                    speed = math.max(speed or 0, s)
                    hit = hit or h
                end
            end
        end
        if self:getInven(self.INVEN_LHAND) then
            for i, o in ipairs(self:getInven(self.INVEN_LHAND)) do
                if o.combat and not target.dead then
                    local s, h = self:attackTargetWith(target, o.combat, damtype, damargs, (mult or 1) * self:getOffHandMult(o.combat))
                    speed = math.max(speed or 0, s)
                    hit = hit or h
                end
            end
        end
    end

    if not speed then
        if self.combat and not target.dead then
            local s, h = self:attackTargetWith(target, self.combat, damtype, damargs, mult)
            speed = math.max(speed or 0, s)
            hit = hit or h
        end
    end

    return speed, hit
end

---Attempts to attack target using the given combat information.
---Returns speed, hit
function _M:attackTargetWith(target, combat, damtype, damargs, mult)
    damtype = damtype or DamageType.PHYSICAL
    mult = mult or 1

    local atk = self:combatAttack(combat)
    local def = target:combatDefense()
    local is_melee = not combat or combat.type ~= "thrown"

    target:checkAngered(self)

    if not Qi.isFocused(self) then
        local miss          -- Message to display on melee miss; doubles as a boolean flag
        local missile_miss  -- Custom message to display on missile miss, if any
        if not (self:canReallySee(target) or self:attr("blind_fight") or rng.percent(GameRules.blind_miss)) then
            miss = "%s attacks blindly and misses %s."
        elseif not self:attr("blind_fight") and (self:attr("concealment_attack") or target:attr("concealment")) and not rng.percent(GameRules.concealment_miss) then
            -- NOTE that we assume that concealment is always due to smoke.
            miss = "%s misses %s in the smoke."
            missile_miss = miss
        elseif not self:skillCheck(atk, def) then
            miss = "%s misses %s."
        end
        if miss then
            if is_melee then
                game.logSeenAny({self, target}, game.flash.NEUTRAL, miss, self:getSrcName():capitalize(), target:getTargetName(self))
            else
                game.logSeen(target, game.flash.NEUTRAL, missile_miss or "%s misses %s.", self:getSrcName():capitalize(), target:getTargetName(self))
            end
            return 1, false
        end
    end

    local dam = self:combatDamage(combat) * mult

    if damargs then
        damargs.dam = dam
    else
        damargs = dam
    end

    -- Special case: First Blessing: Virtue (part 1)
    local prev_on_kill = self.on_kill
    local blessing_virtue_active = self:isTalentActive(self.T_BLESSING_VIRTUE) and not self:getTalentFromId(self.T_BLESSING_VIRTUE).canKill(self, target)
    if blessing_virtue_active then self.on_kill = self:getTalentFromId(self.T_BLESSING_VIRTUE).on_kill end

    DamageType:get(damtype).projector(self, target.x, target.y, damtype, damargs)

    -- Melee project
    if is_melee then
        if not target.dead and combat and combat.melee_project then for typ, dam in pairs(combat.melee_project) do
            if dam > 0 then
                DamageType:get(typ).projector(self, target.x, target.y, typ, dam)
            end
        end end
        if not target.dead then for typ, dam in pairs(self.melee_project) do
            if dam > 0 then
                DamageType:get(typ).projector(self, target.x, target.y, typ, dam)
            end
        end end
    end

    -- Special case: First Blessing: Virtue (part 2)
    -- Note that this placement means later talents may subvert
    -- Blessing: Virtue's technical pacifism.  This is intentional.
    if blessing_virtue_active then self.on_kill = prev_on_kill end

    -- Special case: Charged / Capacitive Appendage
    if is_melee and self:hasEffect(self.EFF_CHARGED) then
        local eff = self:hasEffect(self.EFF_CHARGED)
        if not target.dead and math.floor(eff.power) > 0 then
            DamageType:get(DamageType.LIGHTNING).projector(self, target.x, target.y, DamageType.LIGHTNING, eff.power)
        end
        self:removeEffect(self.EFF_CHARGED)
    end

    return 1, true
end

function _M:fortSave()
    return math.floor(self:getCon() / 2 + self.level / 2) + (self.fort_save or 0)
end

function _M:refSave()
    return math.floor(self:getAgi() / 2 + self.level / 2) + (self.ref_save or 0)
end

function _M:willSave()
    return math.floor(self:getMnd() / 2 + self.level / 2) + (self.will_save or 0)
end

function _M:combatAttack(combat)
    return math.floor(self:getSki() / 2 + self.level / 2) + (combat.attack or 0) + (self.combat_atk or 0)
end

function _M:combatDefense()
    if self:attr("combat_def_zero") then
        return 0
    else
        return math.floor(self:getAgi() / 2 + self.level / 2) + (self.combat_def or 0)
    end
end

function _M:combatDamage(combat)
    local min_dam, dam = self:combatDamageRange(combat)
    if Qi.isFocused(self) then
        return dam
    else
        return rng.range(min_dam, dam)
    end
end

function _M:combatStat(dammod)
    if not dammod then return self:getStr() end

    local stat = 0
    for k, v in pairs(dammod) do
        stat = stat + self:getStat(k) * v
    end
    return stat
end

function _M:combatDamageRange(combat, mult)
    local scale = GameRules:damScale(self.level, self:combatStat(combat.dammod))
    local min = combat.dam + (self.combat_dam or 0)
    local max = min + (combat.damrange or combat.dam / 2)
    return math.round(min * scale * (mult or 1)), math.round(max * scale * (mult or 1))
end

function _M:combatArmor()
    local min, max = self:combatArmorRange()
    return rng.range(min, max)
end

function _M:combatArmorRange()
    local scale = GameRules:damScale(self.level)
    -- Natural armor is more reliable than untrained external armor.
    return math.round((self.combat_natural_armor or 0) / 2 * scale), math.round(((self.combat_natural_armor or 0) + (self.combat_armor or 0)) * scale)
end

--- Gets a "talent power", in the same scale as values used for combatAttack,
--- combatDefense, skillCheck, etc.
function _M:talentPower(stat)
    return math.floor(stat / 2 + self.level / 2)
end

-- Determines the damage for a talent.  pow should use the same range as a
-- weapon damage.
function _M:talentDamage(stat, pow, mult)
    return math.round(pow * GameRules:damScale(self.level, stat) * (mult or 1))
end

function _M:getOffHandMult(combat, mult)
    return 0.5
end

--- Gets combat for the given inventory slot.
-- @param allow_unarmed If true, then allow unarmed combat if the inventory slot is empty.
function _M:getInvenCombat(inven, allow_unarmed)
    -- User has no inventory slot!
    if not self:getInven(inven) then return nil end

    for i, o in ipairs(self:getInven(inven)) do
        if o.combat then return o.combat, o end
    end

    if allow_unarmed then
        return self.combat
    end

    return nil
end

--- Is the actor wielding a weapon two-handed?
function _M:isInvenTwoHanded()
    if not self:getInven(self.INVEN_RHAND) then return false end
    for i, o in ipairs(self:getInven(self.INVEN_RHAND)) do
        if o.slot_forbid == "LHAND" then return o end
    end
    return false
end

--- Similar to getInvenCombat, but contains logic specific to the
-- OFF_HAND_ATTACK talent.
function _M:getOffHandCombat()
    -- TODO: This will need to be reworked if we ever permit the main weapon to be wielded in the left hand
    -- TODO: Shield jab?
    local combat, obj = self:getInvenCombat(self.INVEN_LHAND, true)

    -- Special case: opposite end of a double weapon
    if not obj then
        local r_combat, r_obj = self:getInvenCombat(self.INVEN_RHAND, false)
        if r_obj and r_obj.traits.double then
            return r_combat, r_obj
        end
    end

    return combat, obj
end

