-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
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

newBirthDescriptor{
    type = "background",
    name = "Peasant",
    desc = {
        [[You were a peasant - a farmer, miner, or similar - before you were forced to flee into the wilderness. Your life strengthened your body but left little time for developing your mind.]],
        [[#LIGHT_BLUE#Str 16 / Ski 12 / Con 15 / Agi 10 / Mnd 8]]
    },

    stats = {
        str = 6,
        ski = 2,
        con = 5,
        agi = 0,
        mnd = -2
    }
}

newBirthDescriptor{
    type = "background",
    name = "Artisan",
    desc = {
        [[You were a craftsperson, a skilled laborer in one of the larger towns or cities of the Empire. Such a profession valued skill and precision more than brute strength or book learning.]],
        [[#LIGHT_BLUE#Str 10 / Ski 14 / Con 11 / Agi 14 / Mnd 12]]
    },

    stats = {
        str = 0,
        ski = 4,
        con = 1,
        agi = 4,
        mnd = 2
    }
}

newBirthDescriptor{
    type = "background",
    name = "Scholar",
    desc = {
        [[You worked as a scholar or scribe, employed either by one of the Imperial bureaucracy or by one of the merchants who wheedle their way into the social order.]],
        [[#LIGHT_BLUE#Str 8 / Ski 14 / Con 11 / Agi 12 / Mnd 16]]
    },

    stats = {
        str = -2,
        ski = 4,
        con = 1,
        agi = 2,
        mnd = 6
    }
}

newBirthDescriptor{
    type = "background",
    name = "Wanderer",
    desc = {
        [[You were a wanderer of some sorts: a novice monk, beggar, scavenger, or vagabond who traveled from one town to another, outside of the normal social order. Your travels have left you with a breadth and balance of experience that few in the Empire possess.]],
        [[#LIGHT_BLUE#Str 12 / Ski 12 / Con 13 / Agi 12 / Mnd 12]]
    },

    stats = {
        str = 2,
        ski = 2,
        con = 3,
        agi = 2,
        mnd = 2
    }
}

-- We could add "Custom", but it seems too much complexity for too little benefit.

