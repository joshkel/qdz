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

local Map = require("engine.Map")

newTalent{
    name = "Acid Spray",
    type = {"qi abilities/right hand", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = 6,
    action = function(self, t)
        local tg = {type="ball", range=self:getTalentRange(t), radius=1, talent=t}
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end
        self:project(tg, x, y, DamageType.ACID, 1 + self:getSki(), {type="acid"})
        return true
    end,
    info = function(self, t)
        return "Zshhhhhhhhh!"
    end,
}

newTalent {
    name = "Poison Ore Strike",
    type = {"qi abilities/right hand", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = 1,
    radius = 1,
    getDuration = function(self, t) return 5 end,
    getDamage = function(self, t) return 5 end,
    getDirectDamage = function(self, t) return t.getDamage(self, t) * 3 end,
    target = function(self, t)
         return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), nowarning=true, nolock=true, talent=t}
    end,
    action = function(self, t)
        -- FIXME: Immediate bonus damage if a creature is struck directly in the wall
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        --[[local feat = game.level.map(x, y, Map.TERRAIN)
        if not feat then return nil end
        if not feat.dig or not feat.is_stone then
            game.logPlayer(self, "You must select a section of diggable stone to poison.")
            return nil
        end]]

        if target then
            self:project({type="hit", range=self:getTalentRange(t), talent=t},
                x, y, DamageType.POISON, t.getDamage(self, t) * 3)
        end

        self:project(tg, x, y, function(px, py)
            local pfeat = game.level.map(px, py, Map.TERRAIN)
            if pfeat.can_pass and pfeat.can_pass.pass_wall then return end

            local target = game.level.map(px, py, Map.ACTOR)
            if target and self:reactionToward(target) >= 0 then return end

            game.level.map:addEffect(self,
                px, py, t.getDuration(self, t),
                DamageType.POISON_GAS, t.getDamage(self, t),
                0,        -- radius 0 for individual clouds
                5, nil,   -- dir (5 for ball effect), angle
                engine.Entity.new{alpha=100, display='', color_br=30, color_bg=180, color_bb=60})
        end)

        return true
    end,
    info = function(self, t)
        return flavorText(
            ("Strikes an adjacent section of diggable stone, releasing clouds "..
            "of poisonous gas in a radius of %i. The gas clouds "..
            "last %i turns and do %i damage each turn.\n\n"..
            "If this directly hits a creature within the stone, it also "..
            "deals %i damage to the creature."):format(
                self:getTalentRadius(t), t.getDuration(self, t), t.getDamage(self, t), t.getDirectDamage(self, t)),
            "Dog-head men are cunning tricksters and trapsmiths, but one of " ..
            "their simplest methods for discouraging interlopers is to curse " ..
            "a vein of ore, causing it to release poisonous gas when anyone " ..
            "tries to mine it.")
    end,
}
