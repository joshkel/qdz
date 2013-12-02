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

require "engine.ui.Dialog"

module(..., package.seeall, class.inherit(
    engine.ui.Dialog
))

function _M:mouseTooltip(text, _, _, _, w, h, x, y)
    self:mouseZones({
        { x=x, y=y+(self.hoffset or 0), w=w, h=h, fct=function(button) game:tooltipDisplayAtMap(game.w, game.h, text) end},
    }, true)
end

function _M:drawString(s, text, w, h, tooltip)
    draw_area = {s:drawColorStringBlended(self.font, text, w, h, 255, 255, 255, true)}
    if tooltip then
        self:mouseTooltip(tooltip:toString(), unpack(draw_area))
    end
end
