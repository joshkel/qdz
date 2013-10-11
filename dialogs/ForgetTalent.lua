-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- TE4 - T-Engine 4
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
local ListTalents = require "mod.dialogs.ListTalents"
local Dialog = require "engine.ui.Dialog"
local ListColumns = require "engine.ui.ListColumns"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(ListTalents))

function _M:init(actor, newest_tid)
    self.newest_talent = newest_tid and actor:getTalentFromId(newest_tid) or nil
    actor.hotkey = actor.hotkey or {}

    ListTalents.init(self, actor, "Forget Technique", game.w * 0.7, game.h * 0.7)

    local tut_text
    if self.newest_talent then
        tut_text = tstring{"You have just learned ", self.newest_talent.name, ", but you may only learn "}
    else
        tut_text = tstring{"You may only learn"}
    end
    tut_text:merge{GameUI.tooltipColor.use, tostring(self.actor:getTechniqueLimit()),
        "#LAST# qi techniques at this level. Please choose a technique to forget."}

    self.c_tut = Textzone.new{width=self.iw - 20, height=1, auto_height=true, no_color_bleed=true, text=tut_text}
    self.c_desc = TextzoneList.new{width=math.floor(self.iw / 2 - 10), height=self.ih - self.c_tut.h - 10, scrollbar=true, no_color_bleed=true}

    self:generateList(true, true, function(t) return t.id == newest_tid and ("%s  #LIGHT_GREEN#*new*#LAST#"):format(t.name) or t.name end)

    self.c_list = ListColumns.new{width=math.floor(self.iw / 2 - 10), height=self.ih - self.c_tut.h - 10, sortable=true, scrollbar=true, columns={
        {name="", width={GameUI.one_letter,"fixed"}, display_prop="char", sort="id"},
        {name="Technique", width=80, display_prop="name", sort="name"},
        {name="Status", width=20, display_prop="status", sort="status"},
    }, list=self.list, fct=function(item) self:use(item) end, select=function(item, sel) self:select(item) end}

    self:loadUI{
        {left=0, top=0, ui=self.c_tut},
        {left=0, top=self.c_tut.h + 10, ui=self.c_list},
        {right=0, top=self.c_tut.h + 10, ui=self.c_desc},
        {hcenter=0, top=self.c_tut.h + 5, ui=Separator.new{dir="horizontal", size=self.ih - self.c_tut.h - 15}},
    }
    self:setFocus(self.c_list)
    self:setupUI()

    self.key:addCommands{
        __TEXTINPUT = function(c)
            if self.list and self.list.chars[c] then
                self:use(self.list.chars[c])
            end
        end,
    }

    if newest_tid then
        self.key:addBinds{
            EXIT = function()
                Dialog:yesnoPopup(self.title, ("Give up on learning %s?"):format(self.newest_talent.name), function(ok)
                    if ok then self:finishForget(self.newest_talent) end
                end)
            end,
        }
    end
end

function _M:select(item)
    if item then
        self.c_desc:switchItem(item, item.desc)
    end
end

function _M:use(item)
    if not item or not item.talent then return end

    local talent = self.actor:getTalentFromId(item.talent)
    local msg
    if self.newest_talent then
        msg = ("Unlearn %s so you can learn %s?"):format(talent.name, self.newest_talent.name)
    else
        msg = ("Unlearn %s?"):format(talent.name)
    end

    Dialog:yesnoPopup(self.title, msg, function(ok)
        if ok then self:finishForget(talent) end
    end)
end

function _M:finishForget(talent)
    game:unregisterDialog(self)
    game.logPlayer(self.actor, ("You unlearn %s."):format(talent.name))
    self.actor:unlearnTalent(talent.id)
end

