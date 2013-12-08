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
-- TODO: See if we can fix this properly
local old_setMoveAnim = Entity.setMoveAnim
Entity.setMoveAnim = function(self, oldx, oldy, speed, blur, twitch_dir, twitch)
    if next(self.__particles) ~= nil then
        blur = 0
    end
    return old_setMoveAnim(self, oldx, oldy, speed, blur, twitch_dir, twitch)
end

-- Patch addTemporaryValue to not lose original values for "last", "lowest", and "highest"
-- methods.  See http://forums.te4.org/viewtopic.php?f=44&t=39488
local old_addTemporaryValue = Entity.addTemporaryValue
Entity.addTemporaryValue = function(self, prop, v, noupdate)
    -- Note that, for simplicity, we only support properties directly under self.
    if type(prop) == "string" then
        local base = self
        local method = self.temporary_values_conf[prop] or "add"
        if method == "highest" then
            base["__thighest_"..prop] = base["__thighest_"..prop] or {[0]=base[prop]}
        elseif method == "lowest" then
            base["__tlowest_"..prop] = base["__tlowest_"..prop] or {[0]=base[prop]}
        elseif method == "last" then
            base["__tlast_"..prop] = base["__tlast_"..prop] or {[0]=base[prop]}
        end
    end

    return old_addTemporaryValue(self, prop, v, noupdate)
end

