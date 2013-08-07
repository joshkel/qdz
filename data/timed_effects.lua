-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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

local Stats = require "engine.interface.ActorStats"
local Particles = require "engine.Particles"
local Qi = require "mod.class.interface.Qi"

newEffect{
    name = "FOCUSED_QI",
    desc = "Focused Qi",
    type = "physical", -- TODO?
    status = "beneficial",
    long_desc = function(self, eff) return ("%s's qi aura is focused, causing its attacks to always hit and do maximum damage."):format(self.name:capitalize()) end,
    on_gain = function(self, err) return "#Target# focuses its qi.", "+Qi focus" end, -- FIXME: his / her, not its
    on_lose = function(self, err) return "#Target#'s qi focus dissipates.", "-Qi focus" end,
    activate = function(self, eff)
        eff.particle = self:addParticles(Particles.new("focused_qi", 1))
    end,
    deactivate = function(self, eff)
        self:removeParticles(eff.particle)
    end,
}

newEffect{
    name = "ACIDBURN",
    desc = "Burning from acid",
    type = "physical",
    status = "detrimental",
    parameters = { power=1 },
    on_gain = function(self, err) return "#Target# is covered in acid!", "+Acid" end,
    on_lose = function(self, err) return "#Target# is free from the acid.", "-Acid" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.ACID).projector(eff.src or self, self.x, self.y, DamageType.ACID, eff.power)
        Qi.postCall(eff, eff.src, saved)
    end,
}

newEffect{
    name = "POISON",
    desc = "Poisoned",
    type = "physical",
    status = "detrimental",
    parameters = { power=1 },
    long_desc = function(self, eff) return ("%s is poisoned, taking %i damage per turn."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, err) return "#Target# is poisoned!", "+Poison" end,
    on_lose = function(self, err) return "#Target# recovers from the poison.", "-Poison" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.POISON).projector(eff.src or self, self.x, self.y, DamageType.POISON, eff.power)
        Qi.postCall(eff, saved)
    end,
}

