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

-- TODO: Tooltip should show how long it takes to dig (especially if you don't have Mining)

newEntity{
    define_as = "BASE_DIGGER",
    slot = "RHAND",
    type = "tool", subtype="digger",
    display = "\\", color=colors.SLATE,
    encumber = 8,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    desc = [[A digging implement.]],
    
    digspeed = 10,
    use_no_wear = true,
    use_no_energy = true, -- energy cost is handled by wait() below

    use_simple = {
        name = "dig",
        use = function(self, who)
            who._force_digger = self
            local result = who:useTalent(who.T_MINING)
            who._force_digger = nil
            return {used=result}
        end,
    },

    use_message = function(self, who)
        -- NOTE: Dig speed logic has partial duplication with T_MINING
        local t = who:getTalentFromId(who.T_MINING)
        if not who:knowTalent(who.T_MINING) then
            return ("Digs a section of stone or earth. Using this tool without Mining proficiency takes %i turns."):format(self.digspeed * t.no_proficiency_penalty)
        else
            return ("Digs a section of stone or earth. This takes %i turns (based on your effective Mining proficiency)."):format(t.getEffectiveDigSpeed(who, t, self))
        end
    end,
}

newEntity{ base = "BASE_DIGGER",
    name = "pickaxe",
    level_range = {1, 10},
    cost = 5,
    combat = {
        dam = 5,
    },
    desc = [[A pickaxe. Although designed for mining, it can be used as a weapon in a pinch.]]
}

