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

--- Checks what to do with the target
-- Talk? Attack? Displace?
function _M:bumpInto(target)
    local speed

    local reaction = self:reactionToward(target)
    if reaction < 0 then
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
            for i, o in ipairs(self:getInven(self.INVEN_RHAND)) do
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

function _M:attackTargetWith(target, combat)
    local dam = combat.dam + self:getStr() - target.combat_armor
    DamageType:get(DamageType.PHYSICAL).projector(self, target.x, target.y, DamageType.PHYSICAL, math.max(0, dam))
    return 1, true
end

function _M:getObjectCombat(o, kind)
    if kind == "unarmed" or kind == "bash" or kind == "kick" then return self.combat end
    if kind == "rhand" then return o.combat end
    if kind == "lhand" then return o.combat end
    return nil
end

