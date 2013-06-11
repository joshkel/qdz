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

newBirthDescriptor{
    type = "base",
    name = "base",
    desc = {
    },
    experience = 1.0,

    body = { INVEN = 10, RHAND = 1, LHAND = 1, BODY = 1, FEET = 1, HEAD = 1 },

    copy = {
        max_level = 10,
        lite = 4,
        max_life = 25,
    },
    
    talents = {
        [ActorTalents.T_FOCUS_QI] = 1,
        [ActorTalents.T_BASH] = 1,
        [ActorTalents.T_KICK] = 1,
    }
}

