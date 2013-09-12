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

newTalent{
    name = "Infernal Power",
    type = {"infernal qi/power", 1},
    mode = "passive",
    points = 1,

    silent_absorb = true,

    on_learn = function(self, t)
        game.logPlayer(self, "You feel a rush of power as you absorb the infernal qi into your soul!")
        self:resetToFull()
        if not self.actors_max_level or self.level < self.actors_max_level then
            self:gainExp(self:getExpChart(self.level + 1))
        end
        self:unlearnTalent(t.id)
    end,

    info = function(self, t)
        return [[By absorbing qi from a defeated infernal, you may gain an immediate experience bonus.]]
    end
}

