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

local Talents = require "engine.interface.ActorTalents"

newEntity{
    define_as = "BASE_POTION",
    type = "consumable", subtype="potion",
    display = "!", color=colors.BLUE,
    encumber = 1,
    rarity = 5,
    stacking = true,
    use_verb = "Drink",
    desc = [[Potions may have a variety of effects.]]
}

newEntity{
    base = "BASE_POTION",
    name = "minor healing potion",
    level_range = {1, 10},
    cost = 5,
    use_simple = {
        name = "minor healing",
        use = function(self, who)
            who:heal(10, self)
            game.log(("%s's wounds heal."):format(who.name))
            return {used = true, destroy = true}
        end
    }
}

newEntity{
    define_as = "BASE_THROWN_ITEM",
    type = "consumable", subtype = "thrown item",
    display = "°",
    encumber = 1,
    rarity = 5,
    stacking = true,
    use_verb = "Throw",
}

newEntity{
    base = "BASE_THROWN_ITEM",
    name = "smoke bomb",
    level_range = {1, 10},
    color = colors.LIGHT_SLATE,
    cost = 5,
    --talent_cooldown = Talents.T_SMOKE_BOMB,
    use_talent = { id = Talents.T_SMOKE_BOMB, show_talent_message = true, single_use = true },
    desc = [[When thrown, this assassin's tool releases a thick cloud of smoke, obscuring sight.]]
}

newEntity{
    define_as = "BASE_SCROLL",
    type = "consumable", subtype="scroll",
    display = "?", color=colors.WHITE,
    encumber = 1,
    rarity = 5,
    stacking = true,
    use_verb = "Read",
    desc = [[A scroll containing a verse, invocation, or calligraphy. When read, it bursts into flame, releasing the power in its writing.]]
}

newEntity{
    base = "BASE_SCROLL",
    name = "meditation scroll",
    level_range = {1, 50},
    color = { r = 175, g = 175, b = 255 },
    cost = 5,
    use_talent = { id = Talents.T_FOCUS_QI, single_use = true },
    use_no_energy = true,
    desc = [[A section of verse penned by monks to aid in their meditations. When read, the echoes of their past meditations allow you to instantly focus your own qi.]],
}

