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

newEntity{
    define_as = "BASE_NPC_BAT",
    type = "animal", subtype = "bat",
    display = "b", color=colors.UMBER,
    desc = [[A bat.]],

    -- To quote Angband, bats move somewhat erratically, and quickly.
    global_speed = 1.25,
    random_move = 50,

    ai = "dumb_talented_simple", ai_state = { talent_in=3, },
    stats = { str=4, ski=14, con=6, agi=15, mnd=7 },
    combat_armor = 0
}

-- In Western culture, bats are somewhat sinister.  Not so in Chinese thought.
-- See, e.g., http://goo.gl/j0pWtd
newEntity{ base = "BASE_NPC_BAT",
    name = "forest bat",
    level_range = {1, 4}, exp_worth = 1,
    rarity = 5,
    max_life = resolvers.rngavg(4,6),
    max_qi = resolvers.rngavg(4,6),
    combat = { dam=3 },
    blind_fight = 1,

    desc = [[A common forest-dwelling bat. Forest bats are associated with positive qi and are a symbol of good fortune and happiness. A drawing of five bats symbolizes the Five Blessings: virtue, wealth, health, longevity, and a natural death.]],

    can_absorb = {
        rhand = Talents.T_BLESSING_VIRTUE,
        lhand = Talents.T_BLESSING_WEALTH,
        chest = Talents.T_BLESSING_HEALTH,
        feet = Talents.T_BLESSING_LONGEVITY,
        head = Talents.T_BLESSING_NATURAL_DEATH,
    },
}

-- On the other hand, sinister Western-style bats offer too many gameplay
-- possibilities to ignore.  Vampire bats only live in the New World, so their
-- presence in medieval and Oriental fantasy settings is a bit of an
-- anachronism.
newEntity{ base = "BASE_NPC_BAT",
    name = "cave bat",
    level_range = {2, 6}, exp_worth = 1,
    rarity = 5,
    max_life = resolvers.rngavg(4,8),
    max_qi = resolvers.rngavg(4,8),
    combat = { dam=4 },
    blind_fight = 1,

    desc = [[A deep cave-dwelling bat, rarely seen by surface dwellers. Gloom bats are associated with negative qi and are considered a bad omen. They feed on the blood of humans, mammals, and birds.]],

    can_absorb = {
        rhand = Talents.T_BLOOD_SIP,
        chest = Talents.T_DWELLER_IN_DARKNESS,
        feet = Talents.T_BAT_MOVEMENT,
        head = Talents.T_ECHOLOCATION,
    },
}

