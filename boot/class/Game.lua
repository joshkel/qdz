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

require "engine.class"
require "engine.GameEnergyBased"
require "engine.interface.GameSound"
require "engine.interface.GameMusic"
require "engine.interface.GameTargeting"
require "engine.KeyBind"

local Module = require "engine.Module"
local Dialog = require "engine.ui.Dialog"
local MainMenu = require "mod.dialogs.MainMenu"
local Shader = require "engine.Shader"

module(..., package.seeall, class.inherit(engine.GameEnergyBased, engine.interface.GameMusic, engine.interface.GameSound))

-- Tell the engine that we have a fullscreen shader that supports gamma correction
support_shader_gamma = true

function _M:init()
	engine.interface.GameMusic.init(self)
	engine.interface.GameSound.init(self)
	engine.GameEnergyBased.init(self, engine.KeyBind.new(), 100, 100)
	self.profile_font = core.display.newFont("/data/font/DroidSerif-Italic.ttf", 14)

	local background_name = {"module"}
	
	self.background = core.display.loadImage("/data/gfx/background/"..util.getval(background_name)..".png")
	if self.background then
		self.background_w, self.background_h = self.background:getSize()
		self.background, self.background_tw, self.background_th = self.background:glTexture()
	end

	self.normal_key = self.key
	core.game.setRealtime(0)

	self:loaded()
	profile:currentCharacter("Main Menu", "Main Menu")
end

function _M:loaded()
	engine.GameEnergyBased.loaded(self)
	engine.interface.GameMusic.loaded(self)
	engine.interface.GameSound.loaded(self)
end

function _M:run()
	self.log = function(style, ...) end
	self.logSeen = function(e, style, ...) end
	self.logPlayer = function(e, style, ...) end
	self:createFBOs()
	self:setGamma(config.settings.gamma_correction / 100)

	-- Ok everything is good to go, activate the game in the engine!
	self:setCurrent()

	-- Setup display
	self:registerDialog(MainMenu.new())

	-- Run the current music if any
	self:playMusic("whatever.ogg")

	if not self.firstrunchecked then
		-- Check first time run for online profile
		self.firstrunchecked = true
		self:checkFirstTime()
	end

	if self.s_log then
		local w, h = self.s_log:getSize()
		self.mouse:registerZone(self.w - w, self.h - h, w, h, function(button)
			if button == "left" then util.browserOpenUrl(self.logged_url) end
		end, {button=true})
	end

	-- Setup FPS
	core.game.setFPS(config.settings.display_fps)
end

--- Called when screen resolution changes
function _M:checkResolutionChange(w, h, ow, oh)
	return true
end

function _M:createFBOs()
	self.full_fbo = core.display.newFBO(self.w, self.h)
	if self.full_fbo then self.full_fbo_shader = Shader.new("full_fbo") if not self.full_fbo_shader.shad then self.full_fbo = nil self.full_fbo_shader = nil end end
end

function _M:getPlayer()
	return {}
end

function _M:tick()
	engine.Game.tick(self)
	return true
end

function _M:display(nb_keyframes)
	-- If switching resolution, blank everything but the dialog
	if self.change_res_dialog then engine.GameEnergyBased.display(self, nb_keyframes) return end

	if self.full_fbo then self.full_fbo:use(true) end

	if self.background then
		local x, y = 0, 0
		local w, h = self.w, self.h
		if w > h then
			h = w * self.background_h / self.background_w
			y = (self.h - h) / 2
		else
			w = h * self.background_w / self.background_h
			x = (self.w - w) / 2
		end
		self.background:toScreenFull(x, y, w, h, w * self.background_tw / self.background_w, h * self.background_th / self.background_h)
	end
	engine.GameEnergyBased.display(self, nb_keyframes)
	if self.full_fbo then self.full_fbo:use(false) self.full_fbo:toScreen(0, 0, self.w, self.h, self.full_fbo_shader.shad) end
end

--- Ask if we really want to close, if so, save the game first
function _M:onQuit()
	if self.is_quitting then return end
	self.is_quitting = Dialog:yesnoPopup("Quit", "Really exit T-Engine/ToME?", function(ok)
		self.is_quitting = false
		if ok then core.game.exit_engine() end
	end, "Quit", "Continue")
end

profile_help_text = [[#LIGHT_GREEN#T-Engine4#LAST# allows you to sync your player profile with the website #LIGHT_BLUE#http://te4.org/#LAST#

This allows you to:
* Play from several computers without having to copy unlocks and achievements.
* Keep track of your modules progression, kill count, ...
* Cool statistics for each module to help sharpen your gameplay style
* Help the game developers balance and refine the game

You will also have a user page on http://te4.org/ where you can show off your achievements to your friends.
This is all optional, you are not forced to use this feature at all, but the developers would thank you if you did as it will
make balancing easier.
Online profile requires an internet connection, if not available it will wait and sync when it finds one.]]

function _M:checkFirstTime()
	if not profile.generic.firstrun then
		profile:checkFirstRun()
		local text = "Thanks for downloading T-Engine/ToME.\n\n"..profile_help_text
		Dialog:yesnocancelLongPopup("Welcome to T-Engine", text, 600, function(ret, cancel)
			if cancel then return end
			if not ret then
				local dialogdef = {}
				dialogdef.fct = function(login) self:setPlayerLogin(login) end
				dialogdef.name = "login"
				dialogdef.justlogin = true
				game:registerDialog(require('mod.dialogs.ProfileLogin').new(dialogdef, game.profile_help_text))
			else
				local dialogdef = {}
				dialogdef.fct = function(login) self:setPlayerLogin(login) end
				dialogdef.name = "creation"
				dialogdef.justlogin = false
				game:registerDialog(require('mod.dialogs.ProfileLogin').new(dialogdef, game.profile_help_text))
			end
		end, "Register new account", "Log in existing account", "Maybe later")
	end
end

function _M:createProfile(loginItem)
	if not loginItem.create then
		self.auth_tried = nil
		profile:performlogin(loginItem.login, loginItem.pass)
		profile:waitFirstAuth()
		if profile.auth then
			Dialog:simplePopup("Profile logged in!", "Your online profile is active now...", function() end )
		else
			Dialog:simplePopup("Login failed!", "Check your login and password or try again in in a few moments.", function() end )
		end
		return
	else
		self.auth_tried = nil
		profile:newProfile(loginItem.login, loginItem.name, loginItem.pass, loginItem.email)
		profile:waitFirstAuth()
		if profile.auth then
			Dialog:simplePopup(self.justlogin and "Logged in!" or "Profile created!", "Your online profile is active now...", function() end )
		else
			Dialog:simplePopup("Profile creation failed!", "Try again in in a few moments, or try online at http://te4.org/", function() end )
		end
	end
end

--- Receives a profile event
-- Overloads to detect auth
function _M:handleProfileEvent(evt)
	evt = engine.GameEnergyBased.handleProfileEvent(self, evt)
	if evt.e == "Auth" then
		local d = self.dialogs[#self.dialogs]
		if d and d.__CLASSNAME == "mod.dialogs.MainMenu" then
			d:on_recover_focus()
		end
	end
	return evt
end
