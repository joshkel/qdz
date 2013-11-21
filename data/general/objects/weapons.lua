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

-- Long staff.  Known in China as "gun."
newEntity{
    define_as = "BASE_STAFF",
    slot = "RHAND",
    slot_forbid = "LHAND",
    type = "weapon", subtype="staff",
    display = "\\", color=colors.UMBER,
    encumber = 4,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    traits = { double = true },
    desc = [[A staff.]],
}

newEntity{ base = "BASE_STAFF",
    name = "staff",
    level_range = {1, 10},
    cost = 1,
    combat = {
        dam = 6,
    },
    desc = [[A simple wooden staff, useful for self defense.  Staffs are known as “the grandfather of all weapons.”]]
}

-- Ji (Chinese halberd).  Reportedly the favored weapon of Lu Bu.
newEntity{
    define_as = "BASE_HALBERD",
    slot = "RHAND",
    slot_forbid = "LHAND",
    type = "weapon", subtype="polearm",
    display = "/", color=colors.SLATE,
    encumber = 12,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    desc = [[A polearm.]],
}

newEntity{ base = "BASE_HALBERD",
    name = "horse halberd",
    level_range = {1, 10},
    require = { stat = { str=13 }, },
    cost = 5,
    combat = {
        dam = 10,
    },
    desc = [[A polearm with a spear head for thrusting, a single crescent-shaped blade below the spear head for sweeping and cutting, and a red horsehair tassel tied just below the blade.]]
}

-- Dao.  Also known as broadsword in some translations.
newEntity{
    define_as = "BASE_SABER",
    slot = "RHAND",
    type = "weapon", subtype="saber",
    display = "|", color=colors.SLATE,
    encumber = 4,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    desc = [[A saber.]],
}

newEntity{ base = "BASE_SABER",
    name = "saber",
    level_range = {1, 10},
    cost = 5,
    combat = {
        dam = 7,
    },
    desc = [[A slightly curved, single-edged sword, made for slashing and chopping. As one of the most common weapons in the Imperial army, it's known as “the general of all weapons.”]]
}

-- Jian
newEntity{
    define_as = "BASE_SWORD",
    slot = "RHAND",
    type = "weapon", subtype="sword",
    display = "|", color=colors.SLATE,
    encumber = 4,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    desc = [[A sword.]],
}

newEntity{ base = "BASE_SWORD",
    name = "straight sword",
    level_range = {1, 10},
    require = { stat = { ski=12 }, },
    cost = 5,
    combat = {
        dam = 8,
    },
    desc = [[A straight, narrow, double-edged sword. Considered an elegant and refined weapon, it's known as “the gentleman of all weapons.”]]
}

-- Chinese daggers are known as bi shou, although there appears to be little
-- to distinguish them from daggers of other regions.
newEntity{
    define_as = "BASE_DAGGER",
    slot = "RHAND", offslot = "LHAND",
    type = "weapon", subtype="dagger",
    display = "|", color=colors.SLATE,
    encumber = 1,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    desc = [[Small, sharp, and pointy.]],
}

newEntity{ base = "BASE_DAGGER",
    name = "dagger",
    level_range = {1, 10},
    cost = 5,
    combat = {
        dam = 3,
    },
}

