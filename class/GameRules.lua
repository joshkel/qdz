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

-- Game rules constants and helpers
--
-- Of course, many of the rules and mechanics are embedded in code (especially
-- Combat.lua and Actor.lua), but this will hopefully be a convenient place to
-- keep values for tweaking.
module(..., package.seeall, class.make)

_M.extra_stat_desc = {
    blindsense = "Blindsense lets you detect creatures (but not necessarily stealthed or invisible creatures) and major terrain features within a certain radius."
}

_M.concealment_miss = 25
_M.blind_miss = 50

-- Base life scales expontially with level.
-- Every point of Con modifies the base by 5%.
_M.dam_level_mod = 1.1
function _M:damStatMod(stat)
    return 1 + (stat - 10) * 0.05
end

function _M:damScale(level, stat)
    return math.pow(dam_level_mod, level - 1) * (stat and self:damStatMod(stat) or 1)
end

-- Approximate amount by which *base* damage and armor (before dam_level_mod)
-- is expected to scale per level.
_M.item_dam_per_level = 0.5

-- Qi scales linearly with level and Mind.
_M.qi_per_level = 1
_M.qi_per_mnd = 1

