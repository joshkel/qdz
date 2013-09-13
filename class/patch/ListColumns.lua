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

local ListColumns = require("engine.ui.ListColumns")

-- This works around a bug that can manifest in the default Birther.
-- Steps to reproduce:
-- 1) Click on the second item in the first list.
-- 2) The second list appears, and the second item is highlighted, but the
--    first tooltip is still shown.
local old_setup_input = ListColumns.setupInput
ListColumns.setupInput = function(self)
    self.prev_sel = 0
    self.mouse_pos = { x = 0, y = 0 }
    old_setup_input(self)
end

