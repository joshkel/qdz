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

local Stats = require "mod.class.interface.ActorStats"
local Particles = require "engine.Particles"
local Qi = require "mod.class.interface.Qi"

local function merge_pow_dur(old_eff, new_eff)
    local old_dam = old_eff.power * old_eff.dur
    local new_dam = new_eff.power * new_eff.dur
    old_eff.dur = math.ceil((old_eff.dur + new_eff.dur) / 2)
    old_eff.power = (old_dam + new_dam) / old_eff.dur
end

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
    on_merge = function(self, old_eff, new_eff)
        merge_pow_dam(old_eff, new_eff)
        return old_eff
    end
}

newEffect{
    name = "POISON",
    desc = "Poisoned",
    type = "physical",
    status = "detrimental",
    parameters = { power=1 },
    long_desc = function(self, eff) return ("%s is poisoned, taking %.1f damage per turn."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, err) return "#Target# is poisoned!", "+Poison" end,
    on_lose = function(self, err) return "#Target# recovers from the poison.", "-Poison" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.POISON).projector(eff.src or self, self.x, self.y, DamageType.POISON, eff.power)
        Qi.postCall(eff, saved)
    end,
    on_merge = function(self, old_eff, new_eff)
        merge_pow_dam(old_eff, new_eff)
        return old_eff
    end
}

newEffect{
    name = "PRONE",
    desc = "Prone",
    type = "physical",
    status = "detrimental",
    on_gain = function(self, err) return "#Target# is knocked down!", "+Prone" end,
    on_lose = function(self, err) return "#Target# stands up.", "-Prone" end,
    on_merge = function(self, old_eff, new_eff)
        -- Merging has no effect, to prevent repeated knockdowns from stunlocking
        -- a creature.
        return old_eff
    end,
    activate = function(self, eff)
        -- TODO: Should prone status grant knockback resistance?
        eff.tmpid = self:addTemporaryValue("prone", 1)
        eff.defid = self:addTemporaryValue("plus_defense", -4)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("prone", eff.tmpid)
        self:removeTemporaryValue("plus_defense", eff.defid)
    end,
}

newEffect{
    name = "CHARGED",
    desc = "Charged",
    type = "physical",
    status = "beneficial",

    -- This effect never times out.  Its "duration" shows the amount of charge.
    decrease = 0,

    long_desc = function(self, eff) return ("%s has amassed %i %s of electrical charge, which will be discharged on its next attack."):format(self.name:capitalize(), eff.power, string.pluralize("point", math.floor(eff.power))) end, -- FIXME: his / her, not its, here and in on_gain

    -- This can be gained and lost on every attack, which is noisy.
    -- Try this as a compromise for now.
    --on_gain = function(self, err) return "#Target# begins to charge electricity.", "+Charged" end,
    on_lose = function(self, err) return "#Target#'s electrical charge dissipates.", "-Charged" end,

    activate = function(self, eff)
        --FIXME: Particles
        --eff.particle = self:addParticles(Particles.new("focused_qi", 1))
    end,
    deactivate = function(self, eff)
        --self:removeParticles(eff.particle)
    end,
    on_merge = function(self, old_eff, new_eff)
        old_eff.power = old_eff.power + new_eff.power
        return old_eff
    end,

    add_power = function(self, eff, amount, max_power)
        eff.power = math.min(eff.power + amount, max_power)
        eff.dur = math.max(1, math.floor(eff.power) - 1)
    end,
}

