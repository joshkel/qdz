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

load("/data/general/npcs/kobold.lua")
load("/data/general/npcs/insect.lua")

local Talents = require("engine.interface.ActorTalents")

newEntity{
    define_as = "LEAST_MINION",
    name = "Least Minion", unique=true,
    type = "infernal", subtype = "minion",
    display = "u", color=colors.RED,
    desc = [[Although shorter than a human, this creature's muscles, horns and claws make it seem twice as massive. Such creatures act as the dumb muscle of the underworld; although one of the weakest of the infernals, it is still stronger than most mortals. It must have been quickly summoned by Imperial warlocks and bound here to block your escape.]],
    ai = "dumb_talented_simple", ai_state = { talent_in=3, },
    max_life = 50,
    max_qi = 40,
    combat = {
        dam=10,

        melee_project={
            [DamageType.NEGATIVE_QI] = resolvers.mbonus(10, 2)
        }
    },
    stats = { str=18, ski=16, con=18, agi=16, mnd=8 },
    combat_armor = 4,

    can_absorb = {
        any = Talents.T_INFERNAL_POWER
    },

    on_die = function(self, who)
        require("engine.ui.Dialog"):simpleLongPopup("Victory", [[You breathe a sigh of relief as the infernal collapses to the ground and dissolves in a cloud of foul-smelling negative qi. You've earned a brief respite from the Imperial pursuit, but you stlil have many miles to go.]], 600)
    end
}

