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
require "engine.Object"
require "engine.interface.ObjectActivable"

local Stats = require("mod.class.interface.ActorStats")
local Talents = require("engine.interface.ActorTalents")
local DamageType = require("engine.DamageType")
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(
    engine.Object,
    engine.interface.ObjectActivable,
    engine.interface.ActorTalents
))

function _M:init(t, no_default)
    t.encumber = t.encumber or 0
    t.traits = t.traits or {}

    engine.Object.init(self, t, no_default)
    engine.interface.ObjectActivable.init(self, t)
    engine.interface.ActorTalents.init(self, t)
end

---Overrides engine.Object.getName to add pluralization.
function _M:getName(t)
    t = t or {}
    local qty = self:getNumber()
    local name = self.name

    if (qty == 1 and not t.force_count) or t.no_count then return name
    else return qty.." "..name:pluralize(qty)
    end
end

function _M:getDesc()
    local color = GameUI.tooltipColor
    local text = GameUI:tooltipTitle(self:getDisplayString(), self.name)
    local wielder = self.wielder or {}
    local combat = self.combat or {}

    text:add(true, color.caption, 'Type: ', color.text)
    if self.type == self.subtype then
        text:add(self.type)
    else
        text:add(self.type, ' (', self.subtype, ')')
    end

    -- Combat statistics
    local add=function(caption, value)
        if value then
            text:add(true, color.caption, caption, ': ', color.text)
            if type(value) == 'table' then
                text:merge(value)
            else
                text:add(tostring(value))
            end
        end
    end
    add('Attack', wielder.combat_atk)
    add('Damage', combat.dam)
    add('Defense', wielder.combat_def)
    add('Armor', wielder.combat_armor)

    -- Modifiers
    if self.wielder then
        local delim = true
        for k, v in pairs(self.wielder) do
            local caption = ({ lite="light radius" })[k]
            if not caption and Stats[k] then caption = Stats[k].name end
            if caption then
                text:add(color.text, delim, v > 0 and color.good or color.bad, ("%+i "):format(v), caption)
                delim = ', '
            end
        end
    end

    -- Requirements.  TODO: Highlight requirements not met in red (?)
    if self.require and type(self.require) == "table" and self.require.stat then
        local delim = ''
        text:add(true, color.caption, 'Requires: ', color.text)
        for k, v in pairs(self.require.stat) do
            text:add(delim, tostring(v), ' ', Stats.stats_def[k].name)
            delim = ', '
        end
    end

    if self.desc then text:add(true, true, color.text, self.desc) end

    -- Usage effects
    if self.use_message then
        text:add(true, true, color.caption, 'Use: ', color.text, self.use_message)
    elseif self.use_talent then
        local ab = self:getTalentFromId(self.use_talent.id)
        -- Hack: We don't necessarily have an Actor, but tooltips are for the
        -- player's benefit, so use the player.
        text:add(true, true, color.caption, 'Use: ', color.text, ab.info(game.player, ab))
    end

    return text
end

function _M:tooltip(x, y)
    local color = GameUI.tooltipColor
    local text = self:getDesc()

    if config.settings.cheat then
        text:add(true, true, color.caption, 'UID: ', color.text, tostring(self.uid))
    end

    return text

    -- TODO? Probably want a TOME-style "You see...more objects"
end

function _M:canAct()
    if self.power_regen or self.use_talent then return true end
    return false
end

function _M:act()
    self:regenPower()
    self:cooldownTalents()
    self:useEnergy()
end

function _M:use(who, typ, inven, item)
    inven = who:getInven(inven)

    if self:wornInven() and not self.wielded and not self.use_no_wear then
        game.logPlayer(who, "You must wear this object to use it!")
        return
    end

    local types = {}
    if self:canUseObject() then types[#types+1] = "use" end

    if not typ and #types == 1 then typ = types[1] end

    if typ == "use" then
        who.last_action = 'use_object'

        local ret = self:useObject(who, inven, item)
        if ret.used then
            if self.use_sound then game:playSoundNear(who, self.use_sound) end
            if not self.use_no_energy then
                -- FIXME: I don't think inven.use_speed does anything.  What *is* inven?
                who:useEnergy(game.energy_to_act * (inven.use_speed or 1))
            end
        end

        who.last_action = nil

        return ret
    end
end

-- A copy-and-paste modification of engine.interface.ObjectActivable.useObject
-- that adds the following:
-- * Optional talent messages
-- * Consumable talent items
function _M:useObject(who, ...)
	-- Make sure the object is registered with the game, if need be
	if not game:hasEntity(self) then game:addEntity(self) end

	local reduce = 100 - util.bound(who:attr("use_object_cooldown_reduce") or 0, 0, 100)
	local usepower = function(power) return math.ceil(power * reduce / 100) end

	if self.use_power then
		if (self.talent_cooldown and not who:isTalentCoolingDown(self.talent_cooldown)) or (not self.talent_cooldown and self.power >= usepower(self.use_power.power)) then
		
			local ret = self.use_power.use(self, who, ...) or {}
			local no_power = not ret.used or ret.no_power
			if not no_power then 
				if self.talent_cooldown then
					who.talents_cd[self.talent_cooldown] = usepower(self.use_power.power)
					local t = who:getTalentFromId(self.talent_cooldown)
					if t.cooldownStart then t.cooldownStart(who, t, self) end
				else
					self.power = self.power - usepower(self.use_power.power)
				end
			end
			return ret
		else
			if self.talent_cooldown or (self.power_regen and self.power_regen ~= 0) then
				game.logPlayer(who, "%s is still recharging.", self:getName{no_count=true})
			else
				game.logPlayer(who, "%s can not be used anymore.", self:getName{no_count=true})
			end
			return {}
		end
	elseif self.use_simple then
		return self.use_simple.use(self, who, ...) or {}
	elseif self.use_talent then
		if (self.talent_cooldown and not who:isTalentCoolingDown(self.talent_cooldown)) or (not self.talent_cooldown and (not self.use_talent.power or self.power >= usepower(self.use_talent.power))) then
		
			local id = self.use_talent.id
			local ab = self:getTalentFromId(id)
			local old_level = who.talents[id]; who.talents[id] = self.use_talent.level or 1

            if self.use_talent.show_talent_message and who.showTalentMessage then who:showTalentMessage(ab) end
			local ret = ab.action(who, ab)

			who.talents[id] = old_level

			if ret then 
				if self.talent_cooldown then
					who.talents_cd[self.talent_cooldown] = usepower(self.use_talent.power)
					local t = who:getTalentFromId(self.talent_cooldown)
					if t.cooldownStart then t.cooldownStart(who, t, self) end
				elseif not self.use_talent.single_use then
					self.power = self.power - usepower(self.use_talent.power)
				end
			end

			return {used=ret, destroy=ret and self.use_talent.single_use}
		else
			if self.talent_cooldown or (self.power_regen and self.power_regen ~= 0) then
				game.logPlayer(who, "%s is still recharging.", self:getName{no_count=true})
			else
				game.logPlayer(who, "%s can not be used anymore.", self:getName{no_count=true})
			end
			return {}
		end
	end
end

