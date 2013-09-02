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

local Astar=require("engine.Astar")

-- Monkey-patch Astar: Assume that, whenever use_has_seen is true, we also
-- need to obey the user's unique movement restrictions.
--
-- The alternative to this monkey patch would be to override PlayerMouse:mouseMove,
-- duplicating its entire functionality to replace a couple of lines.
local old_astar_calc = Astar.calc
Astar.calc = function(self, sx, sy, tx, ty, use_has_seen, heuristic, add_check, forbid_diagonals)
    if use_has_seen and self.actor:isTalentActive(self.actor.T_GEOMAGNETIC_ORIENTATION) then
        forbid_diagonals = true
    end
    print(("Astar.calc monkey patch called: forbid_diagonals=%s"):format(tostring(forbid_diagonals)))
    return old_astar_calc(self, sx, sy, tx, ty, use_has_seen, heuristic, add_check, forbid_diagonals)
end
