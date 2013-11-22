-- TE4 - T-Engine 4
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

require "engine.class"
local Dialog = require "engine.ui.Dialog"
local List = require "engine.ui.List"
local Button = require "engine.ui.Button"
local Textzone = require "engine.ui.Textzone"
local Textbox = require "engine.ui.Textbox"
local Separator = require "engine.ui.Separator"

module(..., package.seeall, class.inherit(Dialog))

function _M:init()
	Dialog.init(self, "Main Menu", 250, 400, math.floor((game.w - 300)), 50)
	self.__showup = false
	self.absolute = true

	local l = {}
	self.list = l
	l[#l+1] = {name="New Game", fct=function() game:registerDialog(require("mod.dialogs.NewGame").new()) end}
	l[#l+1] = {name="Load Game", fct=function() game:registerDialog(require("mod.dialogs.LoadGame").new()) end}
	l[#l+1] = {name="View High Scores", fct=function() game:registerDialog(require("mod.dialogs.ViewHighScores").new()) end}
	l[#l+1] = {name="Addons", fct=function() game:registerDialog(require("mod.dialogs.Addons").new()) end}
	l[#l+1] = {name="Options", fct=function()
		local menu menu = require("engine.dialogs.GameMenu").new{
			"resume",
			"keybinds_all",
			"video",
			"sound",
		}
		game:registerDialog(menu)
	end}
	l[#l+1] = {name="Exit", fct=function() game:onQuit() end}
	if config.settings.cheat then l[#l+1] = {name="Reboot", fct=function() util.showMainMenu() end} end

	self.c_version = Textzone.new{auto_width=true, auto_height=true, text=("#{bold}##B9E100#T-Engine4 version: %d.%d.%d"):format(engine.version[1], engine.version[2], engine.version[3])}

	self.c_list = List.new{width=self.iw, nb_items=#self.list, list=self.list, fct=function(item) end, font={"/data/font/DroidSans-Bold.ttf", 16}}

	self.base_uis = {
		{left=0, top=0, ui=self.c_list},
		{right=0, top=0, absolute=true, ui=self.c_version},
	}

	self:updateUI()	
end

function _M:updateUI()
	local uis = table.clone(self.base_uis)

	if profile.auth then
		self:uiStats(uis)
	else
		self:uiLogin(uis)
	end

	self:loadUI(uis)
	self:setupUI(false, true)
	self.key:addBind("LUA_CONSOLE", function()
		if config.settings.cheat then
			game:registerDialog(require("engine.DebugConsole").new())
		end
	end)
	self.key:addBind("SCREENSHOT", function() game:saveScreenshot() end)
end

function _M:uiLogin(uis)
	local str = Textzone.new{auto_width=true, auto_height=true, text="#GOLD#Online Profile"}
	local bt = Button.new{text="Login", width=50, fct=function() self:login() end}
	self.c_login = Textbox.new{title="Username: ", text="", chars=20, max_len=20, fct=function(text) self:login() end}
	self.c_pass = Textbox.new{title="Password: ", size_title=self.c_login.title, text="", chars=20, max_len=20, hide=true, fct=function(text) self:login() end}

	uis[#uis+1] = {left=10, bottom=bt.h + self.c_login.h + self.c_pass.h + str.h, ui=Separator.new{dir="vertical", size=self.iw - 20}}
	uis[#uis+1] = {hcenter=0, bottom=bt.h + self.c_login.h + self.c_pass.h, ui=str}
	uis[#uis+1] = {left=0, bottom=bt.h + self.c_pass.h, ui=self.c_login}
	uis[#uis+1] = {left=0, bottom=bt.h, ui=self.c_pass}
	uis[#uis+1] = {hcenter=0, bottom=0, ui=bt}
end

function _M:uiStats(uis)
	self.logged_url = "http://te4.org/users/"..profile.auth.page
	local str1 = Textzone.new{auto_width=true, auto_height=true, text="#GOLD#Online Profile#WHITE#"}
	local str2 = Textzone.new{auto_width=true, auto_height=true, text="View online: #LIGHT_BLUE##{underline}#"..self.logged_url.."#LAST##{normal}#", fct=function() util.browserOpenUrl(self.logged_url) end}

	local logoff = Textzone.new{text="#LIGHT_BLUE##{underline}#Logout", auto_height=true, width=50, fct=function() self:logout() end}

	uis[#uis+1] = {left=10, bottom=logoff.h + str2.h + str1.h, ui=Separator.new{dir="vertical", size=self.iw - 20}}
	uis[#uis+1] = {hcenter=0, bottom=logoff.h + str2.h, ui=str1}
	uis[#uis+1] = {left=0, bottom=logoff.h, ui=str2}
	uis[#uis+1] = {right=0, bottom=0, ui=logoff}
end

function _M:login()
	if self.c_login.text:len() < 2 then
		Dialog:simplePopup("Username", "Your username is too short")
		return
	end
	if self.c_pass.text:len() < 4 then
		Dialog:simplePopup("Password", "Your password is too short")
		return
	end
	game:createProfile({create=false, login=self.c_login.text, pass=self.c_pass.text})
end

function _M:logout()
	profile:logOut()
	self:on_recover_focus()
end

function _M:on_recover_focus()
	game:unregisterDialog(self)
	local d = new()
	game:registerDialog(d)
end
