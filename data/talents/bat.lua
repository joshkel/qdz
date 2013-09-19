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

--[[newTalent{
    name = "First Blessing: Virtue",
    short_name = "BLESSING_VIRTUE",
    type = {"qi techniques/right hand", 1},
}]]

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
        return flavorText("+1 Pickpocket proficiency. Additionally, the amount of any money that you find (whether by pickpocketing or otherwise) will be increased by 10%.",
            "The second of the Five Blessings is said to let you find wealth through good fortune. Of course, sometimes the easiest way to find wealth is in soneone else's pockets.")
    end
}

newTalent{
    name = "Third Blessing: Health",
    short_name = "BLESSING_HEALTH",
    type = {"qi techniques/chest", 1},
    cooldown = 12,
    qi = 3,
    action = function(self, t)
        local target = self
        local effs = {}

        -- Go through all temporary effects
        -- TODO: As written, this can cure Prone.  Rather silly, although not presently an issue...
        -- Still, we might someday want to distinguish between "health" stuff
        -- (poison, disease, etc.) and other effects (prone, grappled, on fire?).
        for eff_id, p in pairs(target.tmp) do
            local e = target.tempeffect_def[eff_id]
            if e.type == "physical" and e.status == "detrimental" then
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
        return [[Cures one physical status ailment, randomly chosen.]]
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

--[[newTalent{
    name = "Fifth Blessing: Natural Death",
    short_name = "BLESSING_NATURAL_DEATH",
    type = {"qi techniques/mind", 1},
}]]

