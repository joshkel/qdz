-- Qi Dao Zei
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

newEntity{
    define_as = "BASE_LIGHT",
    slot = "LIGHT",
    type = "light", subtype="light",
    display = "~",
    encumber = 2,
    desc = [[A light source]],
}

newEntity{ base = "BASE_LIGHT",
    name = "paper lantern", color=colors.LIGHT_SLATE,
    desc = [[A small lantern made of paper stretched over a bamboo frame, containing a wick and small container of oil.]],
    level_range = {1, 20},
    rarity = 7,
    cost = 1,
    material_level = 1,

    wielder = {
        lite = 2,
    },
}

