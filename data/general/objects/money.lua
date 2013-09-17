-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
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

local GameUI = require("mod.class.ui.GameUI")

newEntity{
    define_as = "BASE_MONEY",
    type = "money", subtype="money",
    display = "$", color=colors[GameUI.money_color],
    encumber = 0,
    rarity = 5,
    identified = true,
    desc = GameUI.money_desc,
    on_prepickup = function(self, who, id)
        who:incMoney(self.money_value)
        game.logPlayer(who, "You pick up %i gold pieces.", self.money_value)
        -- Remove from the map
        game.level.map:removeObject(who.x, who.y, id)
        return true
    end,
    -- FIXME: Actually implement auto_pickup (?)
    auto_pickup = true,
}

newEntity{ base = "BASE_MONEY", define_as = "MONEY_SMALL",
    name = "gold pieces",
    add_name = " (#MONEY#)",
    level_range = {1, 50},
    resolvers.generic(function(e)
        e.money_value = math.round(rng.avg(4, 10))
    end)
}

newEntity{ base = "BASE_MONEY", define_as = "MONEY_BIG",
    name = "huge pile of gold pieces",
    add_name = " (#MONEY#)",
    level_range = {30, 50},
    color=colors.GOLD,
    rarity = 15,
    resolvers.generic(function(e)
        e.money_value = math.round(rng.avg(15, 35))
    end)
}

