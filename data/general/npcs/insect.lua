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
local DamageType = require("engine.DamageType")

newEntity{
    define_as = "BASE_NPC_INSECT",
    type = "insect",

    ai = "dumb_talented_simple", ai_state = { talent_in=3, },

    body_parts = {
        skin = "exoskeleton",
    },
}

newEntity{ base = "BASE_NPC_INSECT",
    name = "grid bug",
    type = "insect", subtype = "grid bug",
    display = "x", color=colors.PURPLE,
    desc = [[A strange, four-legged alien insectoid creature. It advances towards you in odd zig-zag motions, electricity crackling over its body.]],

    stats = { str=1, ski=14, con=6, agi=10, mnd=4 },

    level_range = {1, 4}, exp_worth = 1,
    rarity = 4,
    max_life = resolvers.rngavg(4,6),
    max_qi = resolvers.rngavg(4,6),
    combat = {
        dam=1,
        melee_project={
            [DamageType.LIGHTNING] = resolvers.mbonus(10, 2)
        }
    },
    combat_armor = 0,

    forbid_diagonals = 1,

    resolvers.talents{
        [Talents.T_ELECTROSTATIC_CAPTURE]={base=1},
    },

    can_absorb = {
        rhand = Talents.T_CAPACITIVE_APPENDAGE,
        lhand = Talents.T_CHARGED_BOLT,
        chest = Talents.T_ELECTROSTATIC_CAPTURE, -- Or conduct electricity to nearby foes?  Or gain a speed boost?
        feet = Talents.T_GEOMAGNETIC_ORIENTATION,
        head = Talents.T_ELECTROLUMINESCENCE,
    }
}

-- TODO: Fire ants are tougher than grid bugs, should be worth more exp, once I figure all that out
newEntity{ base = "BASE_NPC_INSECT",
    name = "fire ant",
    type = "insect", subtype = "fire ant",
    display = "a", color=colors.FIREBRICK,
    desc = [[An enormous ant, not much smaller than a human. Heat shimmers over its carapace and smoke escapes from its mandibles.]],

    stats = { str=8, ski=10, con=10, agi=8, mnd=4 },

    level_range = {1, 4}, exp_worth = 1,
    rarity = 4,
    max_life = resolvers.rngavg(4,6),
    max_qi = resolvers.rngavg(4,6),
    combat = {
        dam=2,
        melee_project={
            [DamageType.FIRE] = resolvers.mbonus(10, 0)
        }
    },
    resists = {
        [DamageType.FIRE] = 2, -- TODO: Higher value here?  Or less drop-off for stacking resistances?
    },
    combat_natural_armor = 4,

    resolvers.talents{
        [Talents.T_FIRE_SLASH]={base=1},
        [Talents.T_HEAT_CARAPACE]={base=1},
    },

    can_absorb = {
        rhand = Talents.T_FIRE_SLASH,
        lhand = Talents.T_BURNING_HAND,
        chest = Talents.T_HEAT_CARAPACE,
        feet = Talents.T_ANT_BURDEN,
        head = Talents.T_HIVE_MIND,
    }
}

