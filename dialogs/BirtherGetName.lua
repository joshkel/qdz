-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local Button = require "engine.ui.Button"
local Textbox = require "engine.ui.Textbox"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(action, cancel)
    self.action = action
    self.cancel = cancel
    self.min = 2
    self.max = 25

    Dialog.init(self, "Character Creation", 320, 110)

    local c_box = Textbox.new{title="Enter your character's name: ", text="", chars=30, max_len=self.max, fct=function(text) self:okclick() end}
    self.c_box = c_box
    local ok = require("engine.ui.Button").new{text="Accept", fct=function() self:okclick() end}
    local cancel = require("engine.ui.Button").new{text="Cancel", fct=function() self:cancelclick() end}

    self:loadUI{
        {left=0, top=0, padding_h=10, ui=c_box},
        {left=0, bottom=0, ui=ok},
        {right=0, bottom=0, ui=cancel},
    }
	self:setFocus(c_box)
    self:setupUI(true, true)

    self.key:addBinds{
        EXIT = function() if self.cancel then self.cancel() end game:unregisterDialog(self) end,
    }
end

function _M:okclick()
    local name = self.c_box.text

    if name:len() < self.min or name:len() > self.max then
        Dialog:simplePopup("Error", ("Must be between %i and %i characters."):format(self.min, self.max))
        return
    end

    self:checkNew(name, function()
        game:unregisterDialog(self)
        self.action(name)
    end)
end

function _M:cancelclick()
    self.key:triggerVirtual("EXIT")
end

function _M:checkNew(name, fct)
	local savename = name:gsub("[^a-zA-Z0-9_-.]", "_")
	if fs.exists(("/save/%s/game.teag"):format(savename)) then
		Dialog:yesnoPopup("Overwrite character?", "There is already a character with this name, do you want to overwrite it?", function(ret)
			if not ret then fct() end
		end, "No", "Yes")
	else
		fct()
	end
end

