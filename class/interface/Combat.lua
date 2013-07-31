-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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
                    local s, h = self:attackTargetWith(target, combat)
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
function _M:attackTargetWith(target, combat)
    local atk = self:combatAttack(weapon)
    local def = target:combatDefense()

    if not self:skillCheck(atk, def) and not self:hasEffect(self.EFF_FOCUSED_QI) then
        game.logSeen(target, game.flash.NEUTRAL, "%s misses %s.", self.name:capitalize(), target.name)
        return 1, false
    end

    local dam = combat.dam
    if not self:hasEffect(self.EFF_FOCUSED_QI) then
        dam = rng.range(combat.min_dam or 1, dam)
    end
    dam = dam + self:getStr() / 2 - rng.range(0, target.combat_armor)
    DamageType:get(DamageType.PHYSICAL).projector(self, target.x, target.y, DamageType.PHYSICAL, math.max(0, dam))
    return 1, true
end

function _M:getObjectCombat(o, kind)
    if kind == "unarmed" or kind == "bash" or kind == "kick" then return self.combat end
    if kind == "rhand" then return o.combat end
    if kind == "lhand" then return o.combat end
    return nil
end

function _M:combatAttack(combat)
    return self:getSki() / 2 + (self.level or game.level.level) / 2
end

function _M:combatDefense()
    return self:getAgi() / 2 + (self.level or game.level.level) / 2
end

--- Gets combat for the given inventory slot.
-- @param allow_unarmed If true, then allow unarmed combat if the inventory slot is empty.
function _M:getInvenCombat(inven, allow_unarmed)
    -- User has no inventory slot!
    if not self:getInven(inven) then return nil end

    for i, o in ipairs(self:getInven(inven)) do
        if o.combat then return o.combat end
    end

    if allow_unarmed then
        return self:getObjectCombat(nil, "unarmed")
    end

    return nil
end

