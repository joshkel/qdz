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
version = {0,4,1}
engine = {1,1,3,"te4"}
description = [[
An Oriental-themed fantasy roguelike. Fight creatures from folklore and legend and absorb their qi to gain new abilities while fleeing the sinister minions of the Empire and its warlocks.

Qi (pronounced “chee”) is the life energy that flows through all beings and throughout the universe. You are a qi daozei – a “qi rogue” – born with the ability to absorb others' life energy. Your kind is feared and persecuted by the Empire, so for years you've hidden your gifts and tried to live a normal life among the citizenry. Now you've been discovered and must fight your way through caverns and wilderness to escape to safety, knowing that the magics and minions of the Empire are quickly closing in...
]]
starter = "mod.load"
no_get_name = true

allow_userchat = true

show_funfacts = true
load_tips = {
    { image="/data/gfx/characters/right-red.png", text=[[Right-hand techniques are useful in hand-to-hand combat. To learn a right-hand technique, focus qi, then kill an enemy with a normal melee attack.]] },
    { image="/data/gfx/characters/left-blue.png", text=[[Left-hand techniques are useful for ranged and indirect attacks. To learn a left-hand technique, focus qi, then kill an enemy with an off-hand melee attack, ranged weapon, or special item.]] },
    { image="/data/gfx/characters/chest-yellow.png", text=[[Chest techniques provide defense and enhancement. To learn a chest technique, focus qi, then kill an enemy with a bash.]] },
    { image="/data/gfx/characters/foot-green.png", text=[[Foot techniques grant movement and mobility. To learn a foot technique, focus qi, then kill an enemy with a kick.]] },
    { image="/data/gfx/characters/head-grey.png", text=[[Head techniques can have a variety of effects. To learn a head technique, focus qi, then kill an enemy with another qi technique.]] },
    { image="/data/gfx/characters/five-gold.png", text=[[Absorbing qi strengthens your mind and body as well as granting new techniques. Your stats are based on what kinds of qi you absorb.]] },
    { image="/data/gfx/characters/focus-blue.png", text=[[While focused, your qi imbues everything you do. Poison, projectiles, and other effects can all carry your qi even after your own focus has ended.]] },
    { image="/data/gfx/characters/yin-black.png", text=[[Some beings can attack with pure negative qi, which can destroy your own qi even as it wracks your body.]] },

    -- Story / fluff.  Disabled until more of the story is developed.
    -- { text=[[The emperor's eunuch advisors are the true power within the land. Thoroughly corrupt, they maintain power through a network of spies and agents. Many of them are accomplished sorcerers.]] },
}

background_name = {
    "peach_festival" -- https://en.wikipedia.org/wiki/File:Freer_019.jpg
}

profile_stats_fields = { "techniques" }
profile_defs = {
    techniques = { {tid="index:string:30"},
        receive=function(data, save) save.techniques = save.techniques or {} save.techniques[data.tid] = true end,
        export=function(env) for k, v in pairs(env.techniques) do add{tid=k, nb=v} end end }
}

