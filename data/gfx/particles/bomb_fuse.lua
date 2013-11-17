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

-- Based on ToME's creeping_dark.  See also smoke_cloud.

local nb = 0

return { generator = function()
    local size = 3
    local sizev = 0.3
    local xv = rng.float(-0.5, 0.5)

    return {
        trail = 1,
        life = 15,
        size = size, sizev = sizev, sizea = 0,

        x = 0, xv = xv + -sizev/2, xa = -xv / 20,
        y = rng.float(0.2, 0.4) * engine.Map.tile_h / 2 - size/2, yv = -sizev/2 - 1, ya = 0,

        dir = 0, dirv = 0, dira = 0,
        vel = 0, velv = 0, vela = 0,

        r = 200 / 255,  rv = 0, ra = 0,
        g = 200 / 255,  gv = 0, ga = 0,
        b = 200 / 255,  bv = 0, ba = 0,
        a = rng.range(64, 120) / 255,  av = -1 / 255, aa = 0
    }
end, },
function(self)
    if nb == 0 then self.ps:emit(1) end
    nb = nb + 1
    if nb == 3 then nb = 0 end
end,
100

