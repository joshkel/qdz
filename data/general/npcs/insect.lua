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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local Talents = require("engine.interface.ActorTalents")
local DamageType = require("engine.DamageType")

newEntity{
    name = "grid bug",
    type = "insect", subtype = "grid bug",
    display = "x", color=colors.PURPLE,
    desc = [[A strange, four-legged alien insectoid creature. It advances towards you in odd zig-zag motions, electricity crackling over its body.]],

    ai = "dumb_talented_simple", ai_state = { talent_in=3, },
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
        chest = Talents.T_ELECTROSTATIC_CAPTURE,
        feet = Talents.T_GEOMAGNETIC_ORIENTATION,
        head = Talents.T_ELECTROLUMINESCENCE,
    }
}

