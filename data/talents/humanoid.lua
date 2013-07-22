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

-----------------------------------------------------------------------------
-- Dog-head talents

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
         return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), nowarning=true, nolock=true, pass_terrain=true, talent=t}
    end,
    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        local feat = game.level.map(x, y, Map.TERRAIN)
        if not feat then return nil end
        if not feat.dig or not feat.is_stone then
            game.logPlayer(self, "You must select a section of diggable stone to poison.")
            return nil
        end

        if target then
            self:project({type="hit", range=self:getTalentRange(t), talent=t},
                x, y, DamageType.POISON, t.getDamage(self, t) * 3)
        end

        self:project(tg, x, y, function(px, py)
            if game.level.map:checkEntity(px, py, engine.Map.TERRAIN, "block_move") and not game.level.map:checkEntity(px, py, engine.Map.TERRAIN, "pass_projectile") then return end

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

newTalent {
    name = "Dog-Head Mining",
    short_name = "DOG_HEAD_MINING",
    type = {"qi abilities/chest", 1},
    points = 1,
    mode = "passive",
    on_learn = function(self, t)
        self:learnTalent(Talents.T_MINING, true)
    end,
    on_unlearn = function(self, t)
        self:unlearnTalent(Talents.T_MINING)
    end,

    count = 3,
    chance = 50,

    info = function(self, t)
        -- FIXME: Implement ability to find treasure
        return flavorText(("+1 Mining proficiency. The first %i squares you mine "..
            "on each level have a %i chance of containing gold or gems."):format(
                t.count, t.chance),
            "The dog-head have an instinctive ability to find the richest ore veins, "..
            "such that it often seems to observers that they can swing their pickaxes "..
            "anywhere they want and find treasure.")
    end
}

newTalent {
    name = "Dancing Lights",
    type = {"qi abilities/feet", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = function(self, t) return self.lite or 0 end,
    target = function(self, t)
         return {type="hit", range=self:getTalentRange(t), nowarning=true, nolock=true, talent=t}
    end,
    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local orig_x, orig_y = self.x, self.y
        local x, y = self:getTarget(tg)

        if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
            game.logSeen(self, "You cannot dance there.")
            return false
        end

		local tx, ty = util.findFreeGrid(x, y, 0, true, {[Map.ACTOR]=true})
        if not tx or not ty then
            game.logSeen(self, "You cannot dance there.")
            return false
        end

        if not self:teleportRandom(tx, ty, 0) then
            game.logSeen(self, "The technique fails!")
        else
            self:resetMoveAnim()

            -- Not sure the exact relationship between speed / blur and the
            -- dancing_lights particle effect, but these values seem to work
            -- well enough.
            self:setMoveAnim(orig_x, orig_y, 8, 5)

            game.level.map:particleEmitter(orig_x, orig_y, 0, "dancing_lights",
                { delta_x = self.x - orig_x, delta_y = self.y - orig_y })
        end

        return true
    end,
    info = function(self, t)
        return flavorText(("Transforms into a ball of light that immediately moves"..
            "to a given location within %i squares, where you reappear. "..
            "The range is determined by your light radius.").format(self:getTalentRange(t)),
            "Dog-head men have some small affinity with fire; they can "..
            "transform their bodies into floating flames that resemble the "..
            "lanterns in their mining helmets and travel quickly in this form.")
    end,
}

