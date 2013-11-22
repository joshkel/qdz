-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- ToME - Tales of Middle-Earth
-- Copyright (C) 2009, 2010, 2011, 2012 Nicolas Casalini
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

-- This file loads the game module, and loads data
local KeyBind = require "engine.KeyBind"
local UIBase = require "engine.ui.Base"

local n = core.noise.new(2)
_2DNoise = n:makeTexture2D(64, 64)

-- Customize the UI - copied from QDZ's load.lua and GameUI.lua
UIBase.font = core.display.newFont("/data/font/DroidSans.ttf", 14)
UIBase.font_h = UIBase.font:lineSkip()
UIBase.font_mono = core.display.newFont("/data/font/DroidSansMono.ttf", 14)
UIBase.font_mono_w = UIBase.font_mono:size(" ")
UIBase.font_mono_h = UIBase.font_mono:lineSkip()
UIBase.font_bold = core.display.newFont("/data/font/DroidSans-Bold.ttf", 14)
UIBase.font_bold_h = UIBase.font_bold:lineSkip()

UIBase:setTextShadow(0.6)

-- Usefull keybinds
KeyBind:load("move,hotkeys,inventory,actions,interface,debug")

local VideoOptions = require("engine.dialogs.VideoOptions")
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

return {require "mod.class.Game" }
