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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
local DamageType = require "engine.DamageType"
local Map = require "engine.Map"
local Target = require "engine.Target"
local Talents = require "engine.interface.ActorTalents"
local Qi = require "mod.class.interface.Qi"

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

    print(("Skill check: %f against %f, %f chance of success, result %f"):format(
        skill, difficulty, self:skillChanceOfSuccess(skill, difficulty), result))

    return result >= difficulty, result
end

--- Gets the chance of success for the given skill check, as a percentage,
--- without considering the +/- 100 limit in skillCheck.
function _M:skillChanceOfSuccess(skill, difficulty)
    return 50 + 50 * math.tanh((skill - difficulty) / (2 * 5))
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
        result[k] = (result[k] or 0) + v
    end
    return result
end

--- Checks what to do with the target
-- Talk? Attack? Displace?
function _M:bumpInto(target)
    local speed

    local reaction = self:reactionToward(target)
    if reaction < 0 then
        -- FIXME: Need more detail (lhand versus rhand)
        self.last_action = 'attack'
        speed = self:attackTarget(target)
        self.last_action = nil
        if not speed then return end
    elseif reaction >= 0 then
        if self.move_others then
            -- Displace
            game.level.map:remove(self.x, self.y, Map.ACTOR)
            game.level.map:remove(target.x, target.y, Map.ACTOR)
            game.level.map(self.x, self.y, Map.ACTOR, target)
            game.level.map(target.x, target.y, Map.ACTOR, self)
            self.x, self.y, target.x, target.y = target.x, target.y, self.x, self.y
            speed = self:movementSpeed()
        end
    end

    self:useEnergy(game.energy_to_act * (speed or 1))
end

--- Makes the death happen!
function _M:attackTarget(target)
    local speed
    local hit

    -- TODO: Too much duplication, both in the following code and in alternate methods of attack (kick, bash, ...)

    if not speed then
        if self:getInven(self.INVEN_RHAND) then
            for i, o in ipairs(self:getInven(self.INVEN_RHAND)) do
                local combat = self:getObjectCombat(o, "rhand")
                if combat then
                    local s, h = self:attackTargetWith(target, combat)
                    speed = math.max(speed or 0, s)
                    hit = hit or h
                end
            end
        end
        if self:getInven(self.INVEN_LHAND) then
            for i, o in ipairs(self:getInven(self.INVEN_LHAND)) do
                local combat = self:getObjectCombat(o, "lhand")
                if combat then
                    local s, h = self:attackTargetWith(target, combat, nil, nil, self:getOffHandMult(combat))
                    speed = math.max(speed or 0, s)
                    hit = hit or h
                end
            end
        end
    end

    if not speed then
        local combat = self:getObjectCombat(o, "unarmed")
        if combat then
            local s, h = self:attackTargetWith(target, combat)
            speed = math.max(speed or 0, s)
            hit = hit or h
        end
    end

    return speed
end

---Attempts to attack target using the given combat information.
---Returns speed, hit
function _M:attackTargetWith(target, combat, damtype, damargs, mult)
    damtype = damtype or DamageType.PHYSICAL
    mult = mult or 1

    local atk = self:combatAttack(combat)
    local def = target:combatDefense()
    local is_melee = not combat or combat.type ~= "thrown"

    if not self:skillCheck(atk, def) and not Qi.isFocused(self) then
        game.logSeen(target, game.flash.NEUTRAL, "%s misses %s.", self.name:capitalize(), target.name)
        return 1, false
    end

    local dam = self:combatDamage(combat) * mult
    dam = dam - target:combatArmor() -- TODO? As implemented, this armor ignores damtype - should it?
    dam = math.max(0, math.round(dam))

    if damargs then
        damargs.dam = dam
    else
        damargs = dam
    end

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

function _M:getObjectCombat(o, kind)
    if kind == "unarmed" then return self.combat end
    if kind == "rhand" then return o.combat end
    if kind == "lhand" then return o.combat end

    -- Bash damage is based on unarmed damage, subtract basic punch damage but modify by constitution.
    -- (The bigger you are, the more it hurts someone when you run into them.)
    -- TODO: Add damage-on-hit
    if kind == "bash" then return self:combatMod(self:getObjectCombat(nil, "unarmed"), { dam= -self.BASE_UNARMED_DAMAGE + math.round(self:getCon() / 2) }) end

    -- Kick damage is unarmed damage modified by agility.
    -- TODO: Probably actually want to do str * .5 + agi * .5 + unarmed, or something like that...
    if kind == "kick" then return self:combatMod(self:getObjectCombat(nil, "unarmed"), { dam= math.round(self:getAgi() / 3) }) end

    return nil
end

function _M:combatAttack(combat)
    return math.floor(self:getSki() / 2 + self.level / 2) + (combat.attack or 0) + (self.combat_atk or 0)
end

function _M:combatDefense()
    return math.floor(self:getAgi() / 2 + self.level / 2) + (self.combat_def or 0)
end

function _M:combatDamage(combat)
    local min_dam, dam = self:combatDamageRange(combat)
    if Qi.isFocused(self) then
        return dam
    else
        return rng.range(min_dam, dam)
    end
end

function _M:combatDamageRange(combat, mult)
    local bonus = math.round(self:getStr() / 2)
    local min, max = (combat.min_dam or 1) + bonus, combat.dam + bonus
    return math.round(min * (mult or 1)), math.round(max * (mult or 1))
end

function _M:combatArmor()
    return rng.range(0, self.combat_armor or 0)
end

-- Determines the damage for a talent
-- TODO: This will need tweaking during development; for now, I'm going to try
-- scaling by level, since it won't get equipment bonuses like weapons.
function _M:talentDamage(stat, pow, mult)
    return math.round((stat / 2 + self.level / 2 + pow) * (mult or 1))
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
        return self:getObjectCombat(nil, "unarmed")
    end

    return nil
end

