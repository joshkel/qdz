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

local Talents = require("engine.interface.ActorTalents")

-- According to Google Translate, "dog-head man" is the literal translation of
-- "kobold."  Even in a Chinese roguelike, it seems, beginning adventurers
-- can't avoid fighting kobolds, although these are closer to their original
-- Germanic folklore than to the D&D cannon fodder.
newEntity{
    define_as = "BASE_NPC_KOBOLD",
    type = "humanoid", subtype = "dog-head man",
    display = "h", color=colors.WHITE,
    desc = [[A small, ugly humanoid. Dog-head men are cunning miners and trapsmiths.]],

    ai = "dumb_talented_simple", ai_state = { talent_in=3, },
    stats = { str=6, ski=12, con=8, agi=11, mnd=9 },
    combat_armor = 0
}

newEntity{ base = "BASE_NPC_KOBOLD",
    name = "dog-head man", color=colors.GREEN,
    level_range = {1, 4}, exp_worth = 1,
    rarity = 4,
    max_life = resolvers.rngavg(5,9),
    combat = { dam=2 },

    can_absorb = Talents.T_POISON_ORE_STRIKE
}

--newEntity{ base = "BASE_NPC_KOBOLD",
--    name = "armoured kobold warrior", color=colors.AQUAMARINE,
--    level_range = {6, 10}, exp_worth = 1,
--    rarity = 4,
--    max_life = resolvers.rngavg(10,12),
--    combat_armor = 3,
--    combat = { dam=5 },
--}
