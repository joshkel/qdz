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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
require "engine.ui.Dialog"
local List = require "engine.ui.List"
local Talents = require "engine.interface.ActorTalents"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

function _M:init()
    self:generateList()

    local name = "Debug Menu - Absorb Qi"
    local w = self.font_bold:size(name)
    engine.ui.Dialog.init(self, name, 1, 100)

    local list = List.new{width=math.max(w, self.max) + 10, nb_items=math.min(15, #self.list), scrollbar=#self.list>15, list=self.list, fct=function(item) self:use(item) end}

    self:loadUI{
        {left=0, top=0, ui=list},
    }

    self:setupUI(true, true)

    self.mouse:reset()
    self.mouse:registerZone(0, 0, game.w, game.h, function(button, x, y, xrel, yrel, bx, by, event) if (button == "left" or button == "right") and event == "button" then self.key:triggerVirtual("EXIT") end end)
    self.mouse:registerZone(self.display_x, self.display_y, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event) if button == "right" and event == "button" then self.key:triggerVirtual("EXIT") else self:mouseEvent(button, x, y, xrel, yrel, bx, by, event) end end)
    self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end, }
end

function _M:unload()
    engine.ui.Dialog.unload(self)
    self.exited = true
end

function _M:use(item)
    if not item then return end
    game:unregisterDialog(self)

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

function _M:generateList()
    local list = {}

    for id, t in pairs(Talents.talents_def) do
        if t.type[1]:startsWith("qi techniques/") then
            list[#list+1] = {name=t.name, id=id}
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)

    self.max = 0
    self.maxh = 0
    for i, v in ipairs(list) do
        local w, h = self.font:size(v.name)
        self.max = math.max(self.max, w)
        self.maxh = self.maxh + h
    end

    self.list = list
end
