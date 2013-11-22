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

local VideoOptions=require("engine.dialogs.VideoOptions")

-- Patch VideoOptions to censor the "censor boot" option. :-)
-- It doesn't apply to QDZ, so there's no sense in displaying it.
local old_generateList = VideoOptions.generateList
VideoOptions.generateList = function(self)
    old_generateList(self)
    for i, v in pairs(self.list) do
        if string.match(v.name:toString(), "Censor boot") then
            table.remove(self.list, i)
            return
        end
    end
end

