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

newBirthDescriptor{
    type = "base",
    name = "base",
    desc = {
    },
    experience = 1.0,

    body = { INVEN = 10, RHAND = 1, LHAND = 1, BODY = 1, FEET = 1, HEAD = 1, LIGHT = 1 },

    copy = {
        max_level = 30,
        max_life = 10,
        max_qi = 10,

        resolvers.equip {
            {type="weapon", subtype="staff", name="staff", ego_change=-1000},
            {type="light", subtype="light", name="paper lantern", ego_change=-1000},
        }
    },
    
    talents = {
        [ActorTalents.T_FOCUS_QI] = 1,
        [ActorTalents.T_BASH] = 1,
        [ActorTalents.T_KICK] = 1,
        [ActorTalents.T_OFF_HAND_ATTACK] = 1,
    }
}

load("/data/birth/sexes.lua")
load("/data/birth/backgrounds.lua")

