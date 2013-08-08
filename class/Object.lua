-- Qi Dao Zei
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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"
require "engine.Object"
require "engine.interface.ObjectActivable"

local Stats = require("engine.interface.ActorStats")
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

    engine.Object.init(self, t, no_default)
    engine.interface.ObjectActivable.init(self, t)
    engine.interface.ActorTalents.init(self, t)
end

function _M:tooltip(x, y)
    local color = GameUI.tooltipColor
    local text = GameUI:tooltipTitle(self:getDisplayString(), self.name)

    text:add(true, color.caption, 'Type: ', color.text)
    if self.type == self.subtype then
        text:add(self.type)
    else
        text:add(self.type, ' (', self.subtype, ')')
    end

    -- General item statistics
    if self.wielder then
        local delim = ''
        text:add(true)
        for k, v in pairs(self.wielder) do
            text:add(color.text, delim, v > 0 and color.good or color.bad, ("%+i"):format(v), ({ lite="light radius" })[k] or Stats[k].name)
            delim = ', '
        end
    end

    -- Weapon statistics
    if self.combat then text:add(true, color.caption, 'Damage: ', color.text, tostring(self.combat.dam)) end

    -- Requirements
    if self.require and type(self.require) == "table" and self.require.stat then
        local delim = ''
        text:add(true, color.caption, 'Requires: ', color.text)
        for k, v in pairs(self.require.stat) do
            text:add(delim, tostring(v), ' ', Stats.stats_def[k].name)
            delim = ', '
        end
    end

    if self.desc then text:add(true, true, color.text, self.desc) end

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
        local ret = {self:useObject(who, inven, item)}
        if ret[1] then
            if self.use_sound then game:playSoundNear(who, self.use_sound) end
            if not self.use_no_energy then
                -- FIXME: I don't think inven.use_speed does anything.  What *is* inven?
                who:useEnergy(game.energy_to_act * (inven.use_speed or 1))
            end
        end
        return unpack(ret)
    end
end

