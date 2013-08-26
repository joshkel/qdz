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

newEntity{
    define_as = "BASE_POTION",
    type = "consumable", subtype="potion",
    display = "!", color=colors.BLUE,
    encumber = 1,
    rarity = 5,
    name = "a generic potion",
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
            -- FIXME: Correct arguments?
            who:heal(10, self)
            game.log(("%s's wounds heal."):format(who.name))
            return {used = true, destroy = true}
        end
    }
}
