-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- ToME - Tales of Maj'Eyal
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

require "engine.class"
require "mod.class.ui.SimpleListDialog"

module(..., package.seeall, class.inherit(mod.class.ui.SimpleListDialog))

function _M:init()
    mod.class.ui.SimpleListDialog.init(self, "Debug Menu - Create Item")
end

function _M:useItem(item)
    local o = game.zone:makeEntityByName(game.level, "object", item.index)
    if not o then
        game.log("Failed to create item.")
    else
        game.level.map:addObject(game.player.x, game.player.y, o)
    end
end

function _M:generateListContents()
    local list = {}

    for i, v in ipairs(game.zone.object_list) do
        if v.name then
            list[#list+1] = {name=v.name, index=i}
        end
    end

    return list
end
