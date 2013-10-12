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

name = "Qi Daozei"
long_name = "Qi Daozei"
short_name = "qdz"
author = { "Castler", "joshkel@gmail.com" }
homepage = "http://te4.org/games/qdz"
version = {0,1,0}
engine = {1,0,4,"te4"}
description = [[
An Oriental-themed fantasy roguelike. Fight creatures from folklore and legend and absorb their qi to gain new abilities while fleeing the sinister minions of the Empire and its warlocks.

Qi (pronounced “chee”) is the life energy that flows through all beings and throughout the universe. You are a qi daozei – a “qi rogue” – born with the ability to absorb others' life energy. Your kind is feared and persecuted by the Empire, so for years you've hidden your gifts and tried to live a normal life among the citizenry. Now you've been discovered and must fight your way through caverns and wilderness to escape to safety, knowing that the magics and minions of the Empire are quickly closing in...
]]
starter = "mod.load"
-- TODO: no_get_name = true

allow_userchat = true
-- FIXME: show_funfacts = true, load_tips = {}

background_name = {
    "peach_festival" -- https://en.wikipedia.org/wiki/File:Freer_019.jpg
}

profile_stats_fields = { "techniques" }
profile_defs = {
    techniques = { {tid="index:string:30"},
        receive=function(data, save) save.techniques = save.techniques or {} save.techniques[data.tid] = true end,
        export=function(env) for k, v in pairs(env.techniques) do add{tid=k, nb=v} end end }
}

