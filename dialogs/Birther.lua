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

require "engine.class"
local Birther = require "engine.Birther"
local Button = require "engine.ui.Button"
local Dialog = require "engine.ui.Dialog"
local ListColumns = require "engine.ui.ListColumns"
local Separator = require "engine.ui.Separator"
local Textzone = require "engine.ui.Textzone"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(Birther))

function _M:init(title, actor, order, at_end, quickbirth, w, h)
    self.quickbirth = quickbirth
    self.actor = actor
    self.order = order

    local need_name = game.player_name == "player"
    if not need_name then
        self.at_end = at_end
    else
        self.at_end = function()
            game:registerDialog(require("mod.dialogs.BirtherGetName").new(actor, function(text)
                game:setPlayerName(text)
                actor.name = text
                at_end()
            end, function()
                util.showMainMenu()
            end))
        end
    end

    if not title then title = need_name and "Character Creation" or "Character Creation: "..actor.name end
    Dialog.init(self, title, w or 600, h or 400)

    self.descriptors = {}
    self.descriptors_by_type = {}

    self.c_step_desc = Textzone.new{width=self.iw - 10, height=1, auto_height=true, no_color_bleed=true, text=[[
Choose your character.
]]}

    self.c_tut = Textzone.new{width=math.floor(self.iw / 2 - 10), height=1, auto_height=true, no_color_bleed=true, text=[[
Keyboard: #00FF00#up key/down key#FFFFFF# to select an option; #00FF00#Enter#FFFFFF# to accept; #00FF00#Backspace#FFFFFF# to go back.
Mouse: #00FF00#Left click#FFFFFF# to accept; #00FF00#right click#FFFFFF# to go back.
]]}

    self.c_random = Button.new{text="Random", width=math.floor(self.iw / 2 - 40), fct=function() self:randomSelect() end}
    self.c_desc = Textzone.new{width=math.floor(self.iw / 2 - 10), height=self.ih - self.c_step_desc.h - self.c_tut.h - 20, scrollbar=true, no_color_bleed=true, text=""}

    self.c_list = ListColumns.new{width=math.floor(self.iw / 2 - 10), height=self.ih - self.c_step_desc.h - 10 - self.c_random.h, scrollbar=true, all_clicks=true, columns={
        {name="", width={GameUI.one_letter,"fixed"}, display_prop="char"},
        {name="", width=100, display_prop="display_name"},
    }, list={}, fct=function(item, sel, button, event)
        self.sel = sel
        if (event == "key" or event == "button") and button == "left" then self:next()
        elseif event == "button" and button == "right" then self:prev()
        end
    end, select=function(item, sel) self.sel = sel self:select(item) end}

    self.cur_order = 1
    self.sel = 1

    self:loadUI{
        {left=0, top=self.c_step_desc.h, ui=self.c_list},

        -- This needs to be at index 2 for compatibility with the base Birther class
        {right=0, top=self.c_step_desc.h, ui=self.c_desc}, 
        {right=0, bottom=0, ui=self.c_tut},

        {left=0, bottom=0, ui=self.c_random},
        {hcenter=0, top=self.c_step_desc.h, ui=Separator.new{dir="horizontal", size=self.ih - 10}},

        {left=0, top=0, ui=self.c_step_desc},
    }
    self:setFocus(self.c_list)
    self:setupUI()

    self.key:addCommands{
        _BACKSPACE = function() self:prev() end,
        _ESCAPE = function() self:prev() end,
        __TEXTINPUT = function(c)
            if self.list and self.list.chars[c] then
                self.c_list.sel = self.list.chars[c]
                self.sel = self.list.chars[c]
                self:next()
            end
        end,
    }
end

-- Override engine.Birther.selectType to add an overall description of this step.
function _M:selectType(type)
    engine.Birther.selectType(self, type)
    if self.step_names.detail[type] then
        self.c_step_desc.text = self.step_names.detail[type]
        self.c_step_desc:generate()
    end
end

-- Override engine.Birther.prev to permit escaping back to the main menu
function _M:prev()
    local prev_order = self.cur_order
    engine.Birther.prev(self)
    if prev_order == self.cur_order then util.showMainMenu() end
end
