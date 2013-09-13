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

local DirectPath = require "engine.DirectPath"
local Map = require "engine.Map"

DirectPath.isValid = function(self, nx, ny, use_has_seen)
    return (not use_has_seen or self.map.has_seens(nx, ny)) and self.map:isBound(nx, ny) and not self.map:checkEntity(nx, ny, Map.TERRAIN, "block_move", self.actor, nil, true)
end

-- See my Astar.lua.  Note that I completely reimplement DirectPath:calc, which
-- doesn't have forbid_diagonals support at all.
DirectPath.calc = function(self, sx, sy, tx, ty, use_has_seen, forbid_diagonals)
    if use_has_seen and self.actor:attr("forbid_diagonals") then
        forbid_diagonals = true
    end
    print(("DirectPath.calc monkey patch called: forbid_diagonals=%s"):format(tostring(forbid_diagonals)))
    
    local path = {}
    local l = line.new(sx, sy, tx, ty)
    local ox, oy = sx, sy
    local nx, ny = l()
    while nx and ny do
        if forbid_diagonals and not util.isHex() and nx ~= ox and ny ~= oy then
            if self:isValid(nx, oy, use_has_seen) then
                path[#path+1] = {x=nx, y=oy}
            elseif self:isValid(ox, ny, use_has_seen) then
                path[#path + 1] = {x=ox, y=ny}
            else
                break
            end
        end

        if self:isValid(nx, ny, use_has_seen) then
            path[#path+1] = {x=nx, y=ny}
        else
            break
        end

        ox, oy = nx, ny
        nx, ny = l()
    end
    return path
end

