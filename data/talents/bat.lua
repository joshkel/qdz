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

--[[newTalent{
    name = "First Blessing: Virtue",
    type = {"qi techniques/right hand", 1},
}]]

--[[newTalent{
    name = "Second Blessing: Wealth",
    type = {"qi techniques/left hand", 1},
}]]

newTalent{
    name = "Third Blessing: Health",
    short_name = 'THIRD_BLESSING_HEALTH',
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

--[[newTalent{
    name = "Fourth Blessing: Longevity",
    type = {"qi techniques/feet", 1},
}]]
--[[newTalent{
    name = "Fifth Blessing: Natural Death",
    type = {"qi techniques/mind", 1},
}]]

