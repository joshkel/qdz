-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
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

local Entity=require("engine.Entity")

-- Patch Entity to work around http://forums.te4.org/viewtopic.php?f=44&t=39309
local old_setMoveAnim = Entity.setMoveAnim
Entity.setMoveAnim = function(self, oldx, oldy, speed, blur, twitch_dir, twitch)
    if next(self.__particles) ~= nil then
        blur = 0
    end
    return old_setMoveAnim(self, oldx, oldy, speed, blur, twitch_dir, twitch)
end

