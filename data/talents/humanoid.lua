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
    range = 6,
    action = function(self, t)
        -- TODO: Implement
        return true
    end,
    info = function(self, t)
        return flavorText(
            "Dog-head men are cunning tricksters and trapsmiths, but one of " ..
            "their simplest methods for discouraging interlopers is to curse " ..
            "a vein of ore, causing it to release poisonous gas when anyone " ..
            "tries to mine it.",
            "Strikes an adjacent section of diggable stone, releasing a cloud "..
            "of poisonous gas that damages anyone in it.")
    end,
}
