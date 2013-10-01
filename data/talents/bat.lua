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

-- TODO: Should these talents be more effective the more of them you have?

local Map = require("engine.Map")
local Target = require("engine.Target")
local GameUI = require("mod.class.ui.GameUI")

-- Consolidates logic for whether or not someone under the effects of
-- BLESSING_VIRTUE can kill the target.
local virtueCanKill = function(self, target)
    return require("mod.class.interface.Qi").isFocused(self) or target.type == "undead" or target.type == "infernal" 
end

newTalent{
    name = "First Blessing: Virtue",
    short_name = "BLESSING_VIRTUE",
    type = {"qi techniques/right hand", 1},
    mode = "sustained",
    sustain_qi = 5,
    cooldown = 30,

    combat_atk_bonus = 2,
    combat_dam_bonus = 2,

    activate = function(self, t)
        local ret = {}
        self:talentTemporaryValue(ret, "combat_atk", t.combat_atk_bonus)
        self:talentTemporaryValue(ret, "combat_dam", t.combat_dam_bonus)
        return ret
    end,
    deactivate = function(self, t, p)
        return true
    end,

    canKill = virtueCanKill,

    on_kill = function(self, target)
        if virtueCanKill(self, target) then return false end
        target.life = target.die_at + 0.1
        target:setEffect(target.EFF_UNCONSCIOUS, 1, {})
        return true
    end,

    info = function(self, t)
        return flavorText(("Adds %i to your Attack and %i to your normal attacks' damage. Your normal attacks will knock creatures unconscious instead of killing them. Causing the death of a creature will cancel this technique.\n\nThere are two exceptions. First, when attacking profoundly unnatural or evil opponents, such as undead or infernals, you will strike to kill without penalty. Second, focusing your qi gives you sufficient discipline to kill without malice and without disrupting this technique."):format(t.combat_atk_bonus, t.combat_dam_bonus),
            "The first of the Five Blessings is love of virtue. By purging your mind of killing intent, you can fight with clarity and strength of purpose.")
    end
}

newTalent{
    name = "Second Blessing: Wealth",
    short_name = "BLESSING_WEALTH",
    type = {"qi techniques/left hand", 1},
    mode = "passive",
    on_learn = function(self, t)
        self:learnTalent(Talents.T_PICKPOCKET, true)
    end,
    on_unlearn = function(self, t)
        self:unlearnTalent(Talents.T_PICKPOCKET)
    end,
    passives = function(self, t, p)
        self:talentTemporaryValue(p, "money_value_multiplier", t.money_value_multiplier)
    end,

    money_value_multiplier = 0.1,

    info = function(self, t)
        return flavorText(("+1 Pickpocket proficiency. Additionally, the amount of any money that you find (whether by pickpocketing or otherwise) will be increased by %i%%."):format(t.money_value_multiplier * 100),
            "The second of the Five Blessings is said to let you find wealth through good fortune. Of course, sometimes the easiest way to find wealth is in someone else's pockets.")
    end
}

newTalent{
    name = "Third Blessing: Health",
    short_name = "BLESSING_HEALTH",
    type = {"qi techniques/chest", 1},
    cooldown = 12,
    qi = 3,

    reliable = true,

    action = function(self, t)
        local target = self
        local effs = {}

        -- Go through all temporary effects
        -- TODO: As written, this can cure Prone.  Rather silly, although not presently an issue...
        -- Still, we might someday want to distinguish between "health" stuff
        -- (poison, disease, stunned...) and other effects (prone, grappled,
        -- chicken on your head...).
        for eff_id, p in pairs(target.tmp) do
            local e = target.tempeffect_def[eff_id]
            if (e.type == "physical" or e.type == "mental") and e.status == "detrimental" then
                effs[#effs+1] = eff_id
            end
        end

        if #effs > 0 then
            target:removeEffect(rng.tableRemove(effs))
            -- No need to display this; the effect removal has its own message.
            --game.logSeen(self, "%s is cured!", self.name:capitalize())
            return true
        else
            game.logPlayer(self, "There are no status ailments to cure.")
            return false
        end
    end,
    info = function(self, t)
        return flavorText("Cures one lesser physical or mental status ailment, randomly chosen.\n\n"..
            "This technique may be used reliably even when confused.",
            "The third of the Five Blessings symbolized by the bat is health of mind and body.")
    end
}

newTalent{
    name = "Fourth Blessing: Longevity",
    short_name = "BLESSING_LONGEVITY",
    type = {"qi techniques/feet", 1},
    mode = "passive",

    on_pre_change_level = function(self, t)
        -- TODO: Tweak experience values.
        --
        -- If an average dungeon level has 20-30 monsters, and if we say that
        -- the goal of Longevity is to make it easier to dive / speedrun and
        -- skip monsters, then should we grant experience equal to maybe
        -- 1/4 of those? Or should we adjust it based on player level compared
        -- to target level, to make it useful for skipping monsters while
        -- discouraging over-levelling?
        --
        -- This math should be very roughly equal to 5 monsters, at least
        -- until we start messing with experience values.
        --
        -- Also note that this relies on our disallowing going back to previous
        -- levels.  If we allowed that, we'd have to track visited levels, to
        -- avoid grinding for XP.
        local target_level = game.level.level + math.average(game.level.data.level_range)
        local exp_bonus = target_level * 5
        print(("Blessing: Longevity: %i bonus experience"):format(exp_bonus))
        self:gainExp(target_level)
    end,

    info = function(self, t)
        return flavorText("Grants an experience bonus whenever you travel from one dungeon or wilderness area to the next.",
            "Longevity brings wisdom, as long as you have an opportunity to reflect on what you've seen and where you've been.")
    end
}

newTalent{
    name = "Fifth Blessing: Natural Death",
    short_name = "BLESSING_NATURAL_DEATH",
    type = {"qi techniques/head", 1},
    cooldown = 30,
    qi = 10,

    -- This currently allows player free will in choosing whether to break it,
    -- so it makes no sense for NPC use.
    no_npc_use = true,

    getDuration = function(self, t)
        return math.ceil(self:getMnd() / 4)
    end,

    action = function(self, t)
        self:setEffect(self.EFF_CALM_AURA, t.getDuration(self, t), {})
        return true
    end,

    info = function(self, t)
        return flavorText(("Causes all hostilities to cease for %i %s (based on your Mind). Any damage done to creatures around you will cancel this effect."):format(
                t.getDuration(self, t), ("turn"):pluralize()),
            "The fifth of the Five Blessings, a peaceful death of natural causes, is almost too much to dream of for someone in your state. However, by spreading out your qi over the minds of those around you, you can at least gain a few moments' respite.")
    end
}

newTalent {
    name = "Blood Sip",
    type = {"qi techniques/right hand", 1},
    mode = "activated",
    cooldown = 6,
    qi = 4,
    range = 1,

    getPower = function(self, t) return 0.10 end,
    absorb_amount = 0.5,
    getDuration = function(self, t) return 3 end,

    action = function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        self:attackTarget(target, DamageType.PHYSICAL_BLEEDING,
            { power=t.getPower(self, t), duration=t.getDuration(self, t) })
        return true
    end,

    on_bleed = function(self, t, eff, target)
        if core.fov.distance(self.x, self.y, target.x, target.y) <= 1 then
            self:heal(eff.power * t.absorb_amount, self)
            game.level.map:particleEmitter(self.x, self.y, 1, "absorb_blood")

            if not eff.blood_sip_message then
                eff.blood_sip_message = true
                if self.subtype == "bat" then
                    game.logSeen2(self, target, "%s begins to feed on %s's blood.", self:getSrcName():capitalize(), target:getTargetName())
                else
                    game.logSeen2(self, target, "%s begins to draw vitality from %s's blood.", self:getSrcName():capitalize(), target:getTargetName())
                end
            end
        end
    end,

    info = function(self, t)
        local flavor = "Wounds left by a gloom bat bleed freely for a short time. Bats feed off of the blood to replenish their strength."
        if self.subtype ~= "bat" then
            flavor = flavor .. " Your use of the bat's qi lets you absorb vitality directly from your foes' exposed blood."
        end
        return flavorText(("Performs a normal melee attack against an adjacent enemy. "..
            "If it hits, a bleeding wound is inflicted, dealing %i%% of your weapon damage for %i turns.\n\n"..
            "As a passive effect, whenever an adjacent enemy takes bleeding damage from a wound you inflicted, "..
            "you gain %i%% that damage as health."):format(t.getPower(self, t) * 100, t.getDuration(self, t), t.absorb_amount * 100), flavor)
    end,
}

newTalent {
    name = "Batscreech",
    type = {"qi techniques/left hand", 1},
    mode = "activated",
    cooldown = 10,
    qi = 6,
    range = 0,
    radius = 5,
    target = function(self, t) return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=false} end,
    duration = 4,
    message = "@Source@ emits an ear-piercing screech.",

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end

        self:project(tg, x, y, function(px, py, tg, self)
            local target = game.level.map(px, py, Map.ACTOR)
            if not target then return end
            if target:canBe("confusion") and self:skillCheck(self:talentPower(self:getSki()), target:willSave()) then
                target:setEffect(target.EFF_CONFUSED, t.duration, {})
            else
                game.logSeen(target, "%s resists the confusion.", target.name:capitalize())
            end
        end)

        game.level.map:particleEmitter(self.x, self.y, self:getTalentRadius(t), "directional_shout", {life=8, size=2, tx=x-self.x, ty=y-self.y, distorion_factor=0.1, radius=self:getTalentRadius(t), nb_circles=8, rm=0.8, rM=1, gm=0.8, gM=1, bm=0.1, bM=0.2, am=0.6, aM=0.8})

        return true
    end,

    info = function(self, t)
        local flavor
        if self.subtype ~= "bat" then
            flavor = "Through a series of rapid hand gestures, you can focus qi into a screech like that of the bat."
        end
        return flavorText(("Emits a radius %i cone of deafening high-pitched sound that may confuse all who hear it for %i turns. The chance of confusion is based on your Skill compared against opponents' Will saves."):format(self:getTalentRadius(t), t.duration), flavor)
    end,
}

newTalent {
    name = "Dweller in Darkness",
    type = {"qi techniques/chest", 1},
    mode = "passive",

    life_regen = 0.25,

    do_turn = function(self, t)
        local new_life_regen
        if game.level.map.lites(self.x, self.y) then
            new_life_regen = nil
        elseif self.lite > 0 then
            new_life_regen = t.life_regen
        else
            new_life_regen = t.life_regen * 2
        end

        if not new_life_regen then
            if self:hasEffect(self.EFF_DWELLER_IN_DARKNESS) then
                self:removeEffect(self.EFF_DWELLER_IN_DARKNESS, true, true)
            end
        elseif (self:hasEffect(self.EFF_DWELLER_IN_DARKNESS) or {}).life_regen ~= new_life_regen then
            self:setEffect(self.EFF_DWELLER_IN_DARKNESS, 1, { life_regen = new_life_regen }, true)
        end
    end,

    info = function(self, t)
        return ("Adds %f to your life regeneration as long as you're standing in an unlit area (whether or not you're carrying a light source).\n\nIf you're in total darkness (an unlit area and no light source), adds a total of %f to your life regeneration."):format(t.life_regen, t.life_regen * 2)
    end
}

newTalent {
    name = "Flight of the Bat",
    short_name = "BAT_MOVEMENT",
    type = {"qi techniques/feet", 1},
    mode = "sustained",
    sustain_qi = 1,
    cooldown = 5,

    -- 3/4 chance of normal movement means the move bonus should be at least
    -- 4/3 to be worthwhile.  It probably should be even more than that, to
    -- compensate for the headache of randomness and the opportunity cost of
    -- other talents.
    --
    -- TODO: Can we make this any easier on autoexplore?
    movement_speed_bonus = 0.35,
    random_move = 25,

    activate = function(self, t)
        local ret = {}
        self:talentTemporaryValue(ret, "movement_speed", t.movement_speed_bonus)
        self:talentTemporaryValue(ret, "random_move", t.random_move)
        return ret
    end,
    deactivate = function(self, t, p)
        return true
    end,

    info = function(self, t)
        return flavorText(("Increases your movement speed by %i%% but "..
            "causes you to move randomly %i%% of the time.\n\n"..
            "Only movements are affected; you retain full control of your attacks."):format(t.movement_speed_bonus * 100, t.random_move),
            "Like the bat, you have learned to move quickly, but somewhat erratically.")
    end,
}

newTalent {
    name = "Bat-Blind Vision",  -- because "Echolocation" sounds too modern and scientific
    short_name = "ECHOLOCATION",
    type = {"qi techniques/head", 1},
    mode = "passive",

    passives = function(self, t, p)
        self:talentTemporaryValue(p, "blindsense", 1)
        self:talentTemporaryValue(p, "blind_fight", 1)
        if self.doFOV then self:doFOV() end
    end,

    info = function(self, t)
        return flavorText("Adds +1 to your blindsense radius. " .. GameUI.extra_stat_desc.blindsense ..
           "\n\nAlso grants blind-fighting, which negates the flat miss chance for attacking an opponent you can't see.",
           "Despite darkness and their nearly blind vision, bats have a mysterious ability to navigate their surroundings.")
    end,
}

