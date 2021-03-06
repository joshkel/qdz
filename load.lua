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

-- This file loads the game module, and loads data

require("mod.class.utils")

-- Load monkey patches for core T-Engine code
require("mod.class.patch.Astar")
require("mod.class.patch.Dialog")
require("mod.class.patch.DirectPath")
require("mod.class.patch.Entity")
require("mod.class.patch.VideoOptions")

local KeyBind = require "engine.KeyBind"
local DamageType = require "engine.DamageType"
local ActorStats = require "mod.class.interface.ActorStats"
local ActorResource = require "engine.interface.ActorResource"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorAI = require "engine.interface.ActorAI"
local ActorLevel = require "engine.interface.ActorLevel"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local ActorInventory = require "engine.interface.ActorInventory"
local Birther = require "engine.Birther"
local Map = require "engine.Map"

local UIBase = require "engine.ui.Base"
local GameUI = require "mod.class.ui.GameUI"

-- Customize the UI
UIBase.font = core.display.newFont(GameUI.font_name, GameUI.font_size)
UIBase.font_h = UIBase.font:lineSkip()
UIBase.font_mono = core.display.newFont(GameUI.mono_font_name, GameUI.font_size)
UIBase.font_mono_w = UIBase.font_mono:size(" ")
UIBase.font_mono_h = UIBase.font_mono:lineSkip()
UIBase.font_bold = core.display.newFont("/data/font/DroidSans-Bold.ttf", GameUI.font_size)
UIBase.font_bold_h = UIBase.font_bold:lineSkip()

-- Useful keybinds
KeyBind:load("move,hotkeys,inventory,actions,interface,debug")
KeyBind:defineAction{
    default = { "sym:_d:true:false:false:false" },
    type = "DEBUG_MODE",
    group = "debug",
    name = "Debug Mode",
    only_on_cheat = true,
}

-- Damage types
DamageType:loadDefinition("/data/damage_types.lua")

-- Talents
ActorTalents:loadDefinition("/data/talents.lua")

-- Timed Effects
ActorTemporaryEffects:loadDefinition("/data/timed_effects.lua")

-- Actor resources
ActorResource:defineResource("Qi", "qi", nil, "qi_regen", ("Qi (pronounced %schee%s) is the life energy that flows throughout the universe. By channeling qi, beings can perform a variety of techniques and feats."):format(utf8.ldquo, utf8.rdquo))

-- Actor stats
ActorStats:defineStat("Strength",     "str", 10, 1, 100, "Raw physical strength. This affects your melee damage and carrying capacity and is associated with qi of the right hand.", "You feel stronger.", "You feel weaker.")
ActorStats:defineStat("Skill",        "ski", 10, 1, 100, "Skill indicates your fine motor control and physical and mental dexterity. It affects your accuracy. It is associated with qi of the left hand.", "You feel more skillful.", "You feel less skillful.")
ActorStats:defineStat("Constitution", "con", 10, 1, 100, "Constitution represents your overall health and endurance. It determines your maximum life and fortitude and is associated with the qi of your chest.", "You feel tougher.", "You feel more frail.")
ActorStats:defineStat("Agility",      "agi", 10, 1, 100, "Agility gives your overall balance and quickness. It affects your ability to dodge and your reflexes. It is associated with the qi of your feet.", "You feel quicker.", "You feel more sluggish.")
ActorStats:defineStat("Mind",         "mnd", 10, 1, 100, "Mind covers your intelligence, insight, and strength of will. It affects your willpower; additionally, numerous special techniques derive their effectiveness from your mind. Mind is associated with the qi of your head.", "You feel wiser.", "You feel less wise.")

-- Actor AIs
ActorAI:loadDefinition("/engine/ai/")
ActorAI:loadDefinition("/mod/ai/")

-- Actor Inventory
ActorInventory:defineInventory("RHAND", "Right hand", true, "Your right hand, generally used for your main weapon")
ActorInventory:defineInventory("LHAND", "Left hand", true, "Your left hand, usable for a shield or lighter weapon")
ActorInventory:defineInventory("HEAD", "Head", true, "Helmets or other headgear")
ActorInventory:defineInventory("BODY", "Body", true, "Armor to protect your body")
ActorInventory:defineInventory("FEET", "Feet", true, "Sandals, boots, or other footwear")
ActorInventory:defineInventory("LIGHT", "Light source", true, "A light source")

-- Additional entities resolvers
dofile("/mod/resolvers.lua")
 
-- Birther descriptor
Birther:loadDefinition("/data/birth/descriptors.lua")

-- Map additions - currently too minimal to go in their own file
Map.TERRAIN_CLOUD = Map.TERRAIN + 3

return { require "mod.class.Game" }
