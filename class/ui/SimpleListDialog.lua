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
require "engine.ui.Dialog"
local List = require "engine.ui.List"

module(..., package.seeall, class.inherit(engine.ui.Dialog))

-- Simple Dialog + List combo.  Subclasses should implement the following:
-- * useItem - called when an item is chosen
-- * generateListContents - called at creation to populate the list
-- * selectItem - optional; provides tooltip, hover help, etc.
--
-- If generateListContents populates list.chars, or if opt.enable_hotkeys,
-- then hotkeys are enabled, and pressing the corresponding character will
-- select (if opt.hotkeys_select_only) or select and use (if not) the
-- corresponding item.
function _M:init(name, opt)
    opt = opt or {}
    self:generateList(opt.enable_hotkeys)

    local w = self.font_bold:size(name)
    engine.ui.Dialog.init(self, name, 1, 100)

    local list = List.new{width=math.max(w, self.max) + 10, nb_items=math.min(15, #self.list), scrollbar=#self.list>15, list=self.list,
        fct=function(item) self:use(item) end, select=function(item, sel) if self.selectItem then self:selectItem(item, sel) end end }

    self:loadUI{
        {left=0, top=0, ui=list},
    }

    self:setupUI(true, true)

    self.mouse:reset()
    self.mouse:registerZone(0, 0, game.w, game.h, function(button, x, y, xrel, yrel, bx, by, event) if (button == "left" or button == "right") and event == "button" then self.key:triggerVirtual("EXIT") end end)
    self.mouse:registerZone(self.display_x, self.display_y, self.w, self.h, function(button, x, y, xrel, yrel, bx, by, event) if button == "right" and event == "button" then self.key:triggerVirtual("EXIT") else self:mouseEvent(button, x, y, xrel, yrel, bx, by, event) end end)
    self.key:addBinds{ EXIT = function() game:unregisterDialog(self) end, }

    if self.list.chars then    
        self.key:addCommands{
            __TEXTINPUT = function(c)
                if self.list and self.list.chars[c] then
                    if opt.hotkeys_select_only then
                        list:select(self.list.chars[c])
                    else
                        self:use(self.list[self.list.chars[c]])
                    end
                end
            end,
        }
    end
end

function _M:on_register()
    if self.list.chars then
        game:onTickEnd(function() self.key:unicodeInput(true) end)
    end
end

function _M:unload()
    engine.ui.Dialog.unload(self)
    self.exited = true
end

function _M:use(item)
    if not item then return end
    game:unregisterDialog(self)

    self:useItem(item)
end

function _M:generateList(enable_hotkeys)
    local list = self:generateListContents()

    if enable_hotkeys then
        list.chars = {}
        for i, v in ipairs(list) do
            local c = string.lower(v.name:sub(1,1))
            list.chars[c] = list.chars[c] or i
        end
    end

    self.max = 0
    self.maxh = 0
    for i, v in ipairs(list) do
        local w, h = self.font:size(v.name)
        self.max = math.max(self.max, w)
        self.maxh = self.maxh + h
    end

    self.list = list
end
