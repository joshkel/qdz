-- Qi Dao Zei
-- Copyright (C) 2013 Josh Kelley
--
-- ToME - Tales of Maj'Eyal
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

newEntity{
    define_as = "BASE_LIGHT_ARMOR",
    slot = "BODY",
    type = "armor", subtype="light",
    display = "[", color=colors.UMBER,
    encumber = 15,
    rarity = 5,
    desc = [[A suit of light armour.]],
}

newEntity{ base = "BASE_LIGHT_ARMOR",
    name = "cotton armor",
    color=colors.LIGHT_SLATE,
    level_range = {1, 10},
    cost = 10,
    encumber = 10,
    wielder = {
        combat_def = 1,
        combat_armor = 2,
    },
    desc = [[Armor made from quilted cotton. Although relatively weak, it's cheap and easy to produce.]],
}

newEntity{ base = "BASE_LIGHT_ARMOR",
    name = "leather armor",
    level_range = {1, 10},
    require = { stat = { str=10 }, },
    cost = 10,
    encumber = 15,
    wielder = {
        combat_def = 1,
        combat_armor = 3,
    },
    desc = [[A lightweight suit of leather armor, boiled to harden it.]],
}

