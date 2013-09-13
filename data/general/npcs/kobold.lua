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

local Talents = require("engine.interface.ActorTalents")

-- According to Google Translate, "dog-head man" is the literal translation of
-- "kobold."  Even in a Chinese game, it seems, beginning adventurers can't
-- avoid fighting kobolds, although these are closer to their original
-- Germanic folklore than to the D&D cannon fodder.
newEntity{
    define_as = "BASE_NPC_KOBOLD",
    type = "humanoid", subtype = "dog-head",
    display = "h", color=colors.WHITE,
    desc = [[A small, ugly humanoid. Dog-head men are cunning miners and trapsmiths.]],

    ai = "dumb_talented_simple", ai_state = { talent_in=3, },
    stats = { str=6, ski=12, con=8, agi=11, mnd=9 },
    combat_armor = 0
}

newEntity{ base = "BASE_NPC_KOBOLD",
    name = "dog-head man", color=colors.GREEN,
    level_range = {1, 6}, exp_worth = 1,
    rarity = 4,
    max_life = resolvers.rngavg(5,9),
    max_qi = resolvers.rngavg(4,6),
    combat = { dam=5 },

    resolvers.talents{
        [Talents.T_POISONED_DART]={base=1},
    },

    can_absorb = {
        rhand = Talents.T_POISON_ORE_STRIKE,
        lhand = Talents.T_POISONED_DART,      -- or Poisoned Arrow?  Trap Rune?
        chest = Talents.T_DOG_HEAD_MINING,    -- or Trap Sense?  Earth Affinity?  Poison Resistance?  Some fire ability?
        feet = Talents.T_DANCING_LIGHTS,      -- or mining?
        head = Talents.T_MINING_LIGHT,
    },
}

