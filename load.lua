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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

-- This file loads the game module, and loads data
local KeyBind = require "engine.KeyBind"
local DamageType = require "engine.DamageType"
local ActorStats = require "engine.interface.ActorStats"
local ActorResource = require "engine.interface.ActorResource"
local ActorTalents = require "engine.interface.ActorTalents"
local ActorAI = require "engine.interface.ActorAI"
local ActorLevel = require "engine.interface.ActorLevel"
local ActorTemporaryEffects = require "engine.interface.ActorTemporaryEffects"
local Birther = require "engine.Birther"

-- Useful keybinds
KeyBind:load("move,hotkeys,inventory,actions,interface,debug")

-- Damage types
DamageType:loadDefinition("/data/damage_types.lua")

-- Talents
ActorTalents:loadDefinition("/data/talents.lua")

-- Timed Effects
ActorTemporaryEffects:loadDefinition("/data/timed_effects.lua")

-- Actor resources
ActorResource:defineResource("Power", "power", nil, "power_regen", "Power represent your ability to use special talents.")

-- Actor stats
ActorStats:defineStat("Strength",     "str", 10, 1, 100, "Raw physical strength. This affects your melee damage and carrying capacity. Strength is associated with the right hand.")
ActorStats:defineStat("Skill",        "ski", 10, 1, 100, "Skill indicates your fine motor control and physical and mental dexterity. It affects your accuracy (especially with ranged weapons) and your aptitude with several skills. Skill is associated with the left hand.")
ActorStats:defineStat("Constitution", "con", 10, 1, 100, "Constitution represents your overall health and endurance. It determines your maximum life. Constitution is associated with the heart.")
ActorStats:defineStat("Agility",      "agi", 10, 1, 100, "Agility gives your gross motor skills and overall quickness. It affects your ability to dodge as well as your overall speed. Agility is associated with the feet.")
ActorStats:defineStat("Mind",         "mnd", 10, 1, 100, "Mind covers your intelligence, insight, and strength of will. Numerous special abilities derive their power from your mind. Mind is associated with the head.")

-- Actor AIs
ActorAI:loadDefinition("/engine/ai/")

-- Birther descriptor
Birther:loadDefinition("/data/birth/descriptors.lua")

return {require "mod.class.Game" }
