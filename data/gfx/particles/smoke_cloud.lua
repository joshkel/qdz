-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- ToME - Tales of Maj'Eyal
-- Copyright (C) 2009, 2010, 2011 Nicolas Casalini
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

-- Based on ToME's creeping_dark

return { generator = function()
    local size = 12
    local sizev = 0.3
    local sizea = -0.05
    local halfSize = size / 2

    return {
        trail = 1,
        life = 35,
        size = size, sizev = sizev, sizea = sizea,

        x = rng.range(-engine.Map.tile_w * 0.5 - halfSize, engine.Map.tile_w * 0.5 - halfSize), xv = -sizev/2, xa = -sizea/2,
        y = rng.range(-engine.Map.tile_h * 0.5 - halfSize, engine.Map.tile_h * 0.5 - halfSize), yv = -sizev/2, ya = -sizea/2,

        dir = 0, dirv = 0, dira = 0,
        vel = 0, velv = 0, vela = 0,

        r = 200 / 255,  rv = 0, ra = 0,
        g = 200 / 255,  gv = 0, ga = 0,
        b = 200 / 255,  bv = 0, ba = 0,
        a = rng.range(64, 120) / 255,  av = -1 / 255, aa = 0
    }
end, },
function(self)
    self.ps:emit(2)
end,
100

