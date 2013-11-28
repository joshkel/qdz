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

local Map = require "engine.Map"
local Stats = require "mod.class.interface.ActorStats"
local Particles = require "engine.Particles"
local Qi = require "mod.class.interface.Qi"
local GameRules = require "mod.class.GameRules"

local function merge_pow_dur(old_eff, new_eff)
    local old_dam = old_eff.power * old_eff.dur
    local new_dam = new_eff.power * new_eff.dur
    old_eff.dur = math.ceil((old_eff.dur + new_eff.dur) / 2)
    old_eff.power = (old_dam + new_dam) / old_eff.dur
end

newEffect{
    name = "FOCUSED_QI",
    desc = "Focused Qi",
    type = "physical",  -- ???
    status = "beneficial",
    long_desc = function(self, eff) return ("%s's qi aura is focused, causing %s attacks to always hit and do maximum damage."):format(self.name:capitalize(), string.his(self)) end,
    on_gain = function(self, err) return ("#Target# focuses %s qi."):format(string.his(self)), "+Qi focus" end,
    on_lose = function(self, err) return "#Target#'s qi focus dissipates.", "-Qi focus" end,
    activate = function(self, eff)
        eff.particle = self:addParticles(Particles.new("focused_qi", 1))
    end,
    deactivate = function(self, eff)
        self:removeParticles(eff.particle)
    end,
}

newEffect{
    name = "SMOKE_CONCEALMENT",
    desc = "Smoke Concealment",
    type = "other",
    status = "neutral",

    decrease = 0,

    long_desc = function(self, eff) return ("Smoke obscures %s's vision and others' view of %s, granting a %i%% miss chance on attacks by or against %s."):format(self.name:capitalize(), string.him(self), GameRules.concealment_miss, string.him(self)) end,
    on_gain = function(self, err) return "#Target# is concealed by the smoke.", "+Concealment" end,
    on_lose = function(self, err) return "#Target# is no longer concealed by the smoke.", "-Concealment" end,
    activate = function(self, eff)
        eff.tmpid1 = self:addTemporaryValue("concealment", 1)
        eff.tmpid2 = self:addTemporaryValue("concealment_attack", 1)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("concealment", eff.tmpid1)
        self:removeTemporaryValue("concealment_attack", eff.tmpid2)
    end,

    on_timeout = function(self, eff)
        if not game.level.map(self.x, self.y, Map.TERRAIN_CLOUD) then self:removeEffect(self.EFF_SMOKE_CONCEALMENT) end
    end,
}

newEffect{
    name = "BODY_HARDENING",
    desc = "Body Hardening",
    type = "physical",
    status = "beneficial",

    -- This effect is based on D20's implementation of temporary hit points
    long_desc = function(self, eff) return ("%s's body is hardened by the flow of qi, adding %i temporary life. When this effect ends, %s life will drop back to %i (unless already reduced below that)."):format(self.name:capitalize(), eff.power, string.his(self), eff.start_life) end,
    on_gain = function(self, err) return "#Target#'s body hardens.", "+Body Hardening" end,
    on_lose = function(self, err) return "#Target#'s body returns to normal .", "-Body Hardening" end,
    activate = function(self, eff)
        eff.start_life = self.life
        eff.tmpid = self:addTemporaryValue("max_life", eff.power)
        self.life = self.life + eff.power
    end,
    deactivate = function(self, eff)
        self.life = math.min(self.life, eff.start_life)
        self:removeTemporaryValue("max_life", eff.tmpid)
    end,
}

newEffect{
    name = "ACIDBURN",
    desc = "Burning from acid",
    type = "physical",
    status = "detrimental",
    parameters = { power=1, damage_message_passive=true },
    on_gain = function(self, err) return "#Target# is covered in acid!", "+Acid" end,
    on_lose = function(self, err) return "#Target# is free from the acid.", "-Acid" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.ACID).projector(eff.src or self, self.x, self.y, DamageType.ACID, eff.power)
        Qi.postCall(eff, eff.src, saved)
    end,
    on_merge = function(self, old_eff, new_eff)
        merge_pow_dur(old_eff, new_eff)
        return old_eff
    end,
}

newEffect{
    name = "POISON",
    desc = "Poisoned",
    type = "physical",
    status = "detrimental",
    parameters = { power=1, damage_message_passive=true },
    long_desc = function(self, eff) return ("%s is poisoned, taking %i damage per turn."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, err) return "#Target# is poisoned!", "+Poison" end,
    on_lose = function(self, err) return "#Target# recovers from the poison.", "-Poison" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.POISON).projector(eff.src or self, self.x, self.y, DamageType.POISON, eff.power)
        Qi.postCall(eff, saved)
    end,
    on_merge = function(self, old_eff, new_eff)
        merge_pow_dur(old_eff, new_eff)
        return old_eff
    end,
}

newEffect{
    name = "BLEEDING",
    desc = "Bleeding",
    type = "physical",
    status = "detrimental",
    parameters = { power=1, damage_message_passive=true },
    long_desc = function(self, eff) return ("%s is bleeding, taking %.1f damage per turn."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, err) return ("#Target# bleeds from %s injuries."):format(string.his(self)), "+Bleeding" end,
    on_lose = function(self, err) return "#Target#'s bleeding stops.", "-Bleeding" end,
    on_timeout = function(self, eff)
        local saved = Qi.preCall(eff)
        DamageType:get(DamageType.BLEEDING).projector(eff.src or self, self.x, self.y, DamageType.BLEEDING, eff.power)

        if eff.src and eff.src:knowTalent(eff.src.T_BLOOD_SIP) then
            local t = eff.src:getTalentFromId(eff.src.T_BLOOD_SIP)
            t.on_bleed(eff.src, t, eff, self)
        end

        Qi.postCall(eff, saved)
    end,
    on_merge = function(self, old_eff, new_eff)
        merge_pow_dur(old_eff, new_eff)
        return old_eff
    end,
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
        -- TODO: Should prone or unconscious status grant knockback resistance?
        eff.tmpid = self:addTemporaryValue("prone", 1)
        eff.defid = self:addTemporaryValue("combat_def", -4)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("prone", eff.tmpid)
        self:removeTemporaryValue("combat_def", eff.defid)
    end,
}

-- Unconscious is special; it's planned to only be inflicted under special
-- circumstances, as an alternative to death. It's therefore okay if it's
-- abnormally dangerous.
newEffect{
    name = "UNCONSCIOUS",
    desc = "Unconscious",
    type = "physical",
    status = "detrimental",

    decrease = 0,

    on_gain = function(self, err) return "#Target# is is knocked out.", "+Unconscious" end,
    on_lose = function(self, err) return "#Target# regains consciousness.", "-Unconscious" end,
    long_desc = function(self, eff) return ("%s is unconscious until %s wounds start to heal."):format(self.name:capitalize(), string.his(self)) end,

    activate = function(self, eff)
        eff.tmpid = self:addTemporaryValue("unconscious", 1)
        eff.defid = self:addTemporaryValue("combat_def_zero", 1)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("unconscious", eff.tmpid)
        self:removeTemporaryValue("combat_def_zero", eff.defid)
    end,

    on_timeout = function(self, eff)
        -- Requiring life 2 means ~8 turns unconsciousness for default life regen.
        -- That's probably about right for the Blessing: Virtue talent.
        if self.life >= 2 then
            self:removeEffect(self.EFF_UNCONSCIOUS)
            -- It's implausible for a creature to spring up and jump back into
            -- combat.
            self.energy.value = self.energy.value - game.energy_to_act
        end
    end,
}

newEffect{
    name = "CHARGED",
    desc = "Charged",
    type = "physical",
    status = "beneficial",

    decrease = 0,

    long_desc = function(self, eff) return ("%s has amassed %i %s of electrical charge, which will be discharged on %s next attack."):format(self.name:capitalize(), eff.power, string.pluralize("point", math.floor(eff.power)), string.his(self)) end,

    -- This can be gained and lost on every attack, which is noisy.
    -- Try this as a compromise for now.
    -- Note that on_gain's current message would be inaccurate for Electrostatic Capture.
    --on_gain = function(self, err) return "#Target# begins to charge electricity.", "+Charged" end,
    on_lose = function(self, err) return "#Target#'s electrical charge dissipates.", "-Charged" end,

    activate = function(self, eff)
        eff.particle = self:addParticles(Particles.new("charged", 1, {power = eff.power}))
    end,
    deactivate = function(self, eff)
        self:removeParticles(eff.particle)
    end,
    on_merge = function(self, old_eff, new_eff)
        old_eff.power = old_eff.power + new_eff.power
        return old_eff
    end,

    add_power = function(self, eff, amount, max_power)
        max_power = max_power or math.huge
        if eff.power < max_power then
            eff.power = math.min(eff.power + amount, max_power)

            self:removeParticles(eff.particle)
            eff.particle = self:addParticles(Particles.new("charged", 1, {power = eff.power}))
        end
    end,
}

newEffect{
    name = "CALM_AURA",
    desc = "Aura of Calm",
    type = "mental",
    status = "beneficial",
    long_desc = function(self, eff) return ("An aura of calm surrounds %s, causing hostilities to cease in the area."):format(self.name) end,
    on_gain = function(self, err) return "An aura of calm emanates from #target#.", "+Aura of Calm" end,
    on_lose = function(self, err) return "The aura of calm dissipates.", "-Aura of Calm" end,

    activate = function(self, eff)
        -- Reset NPCs' targets.  Otherwise, they follow the player around
        -- like a puppy dog.
        for uid, e in pairs(game.level.entities) do
            print(e.name)
            if e.setTarget and e ~= game.player then
                e:setTarget(nil)
            end
        end
    end,

    -- The rest of Aura of Calm's effects are implemented in Actor.onTakeHit and Actor.reactionToward
}

newEffect{
    name = "DWELLER_IN_DARKNESS",
    desc = "Dweller in Darkness",
    type = "physical",  -- ???
    status = "beneficial",

    -- Adding / removing this effect is handled by T_DWELLER_IN_DARKNESS's do_turn.
    decrease = 0,

    long_desc = function(self, eff) return ("%s finds respite in the shadows and will recover faster from injuries."):format(self.name:capitalize()) end,
    on_gain = function(self, eff) return "#Target# slides into the comforting shadows.", "+Dweller in Darkness" end,
    on_lose = function(self, eff) return ("#Target# cringes a bit when %s enters the light."):format(string.he(self)), "-Dweller in Darkness" end,

    activate = function(self, eff)
        eff.lifeid = self:addTemporaryValue("life_regen", eff.life_regen)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("life_regen", eff.lifeid)
    end,    
}

newEffect{
    name = "CONFUSED",
    desc = "Confused",
    type = "mental",
    status = "detrimental",

    long_desc = function(self, eff) return ("%s is confused and suffers a %i%% chance each turn of moving randomly or attacking a random adjacent creature (whether friend or foe)."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, eff) return "#Target# is confused!", "+Confused" end,
    on_lose = function(self, eff) return "#Target# seems more lucid.", "-Confused" end,

    activate = function(self, eff)
        eff.power = eff.power or 50
        eff.confid = self:addTemporaryValue("confused", eff.power)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("confused", eff.confid)
    end,
}

newEffect{
    name = "HEAT_CARAPACE",
    desc = "Heat Carapace",
    type = "physical",
    status = "beneficial",

    long_desc = function(self, eff) return ("%s's skin is hardened by flames, adding %i to natural armor."):format(self.name:capitalize(), eff.power) end,
    on_gain = function(self, eff) return ("#Target#'s %s is hardened by the flames."):format(self.body_parts.skin), "+Heat Carapace" end,
    on_lose = function(self, eff) return ("#Target#'s %s is no longer fire-hardened."):format(self.body_parts.skin), "-Heat Carapace" end,

    activate = function(self, eff)
        eff.armorid = self:addTemporaryValue("combat_natural_armor", eff.power)
    end,
    deactivate = function(self, eff)
        self:removeTemporaryValue("combat_natural_armor", eff.armorid)
    end,    
}

