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
    name = "Mining",
    type = {"basic/proficiencies", 1},
    findBest = function(self, t)
        local best = nil
        local find = function(inven)
            for item, o in ipairs(inven) do
                if o.digspeed and (not best or o.digspeed < best.digspeed) then best = o end
            end
        end
        for inven_id, inven in pairs(self.inven) do find(inven) end
        return best
    end,
    points = 5,
    no_npc_use = true,
    no_energy = true, -- energy cost is handled by diggers.lua's wait()
    action = function(self, t)
        local best = t.findBest(self, t)
        if not best then game.logPlayer(self, "You require a mining tool to dig.") return end
        return best:useObject(self)
    end,
    info = function(self, t)
        -- TODO: Permit Mining to work without a digger?
        -- I'm not positive it will be worth a talent slot otherwise.
        local best = t.findBest(self, t)
        local result = "Mining lets you use a pickaxe or similar tool to dig stone and earth.\n\n"
        if best then
            result = result .. ("Digging with your %s takes %d turns (based on your proficiency level and best mining tool available)."):format(best.name, best.getEffectiveDigSpeed(self))
        else
            result = result .. "You currently have no mining tools."
        end
        return result
    end,
}
