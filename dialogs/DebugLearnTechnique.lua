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
local Talents = require "engine.interface.ActorTalents"

module(..., package.seeall, class.inherit(mod.class.ui.SimpleListDialog))

function _M:init()
    mod.class.ui.SimpleListDialog.init(self, "Debug Menu - Learn Technique")
end

function _M:useItem(item)
    local player = game.player
    local id = item.id
    
    if player:knowTalent(id) then
        game.log("You already know this technique.")
    else
        local t = Talents:getTalentFromId(id)
        game.log(("You learn %s."):format(t.name))
        player:learnTalent(id, true)
    end
end

function _M:selectItem(item, sel)
    local t = Talents:getTalentFromId(item.id)
    game.tooltip:displayAtMap(nil, nil, game.w, game.h, game.player:getTalentFullDescription(t), true)
end

function _M:generateListContents()
    local list = {}

    for id, t in pairs(Talents.talents_def) do
        if t.type[1]:startsWith("qi techniques/") or t.type[1]:startsWith("infernal qi/") then
            list[#list+1] = {name=t.name, id=id}
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)

    return list
end

