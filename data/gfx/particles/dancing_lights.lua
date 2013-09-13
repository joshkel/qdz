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

base_size = 48

local count = math.sqrt(delta_x * delta_x + delta_y * delta_y) * 2
local x_inc = delta_x / (count - 1)
local y_inc = delta_y / (count - 1)
local nb = 0

return { generator = function()
    local x = x_inc * tile_w * (nb + 0.5)
    local y = y_inc * tile_h * (nb + 0.5)

    return {
        trail = false,
        life = 20,
        size = math.sqrt(tile_w * tile_w + tile_h * tile_h) * 1.2, sizev = 0, sizea = 0,

        x = x + rng.range(-8, 8), xv = 0, xa = 0,
        y = y + rng.range(-8, 8), yv = 0, ya = 0,
        dir = 0, dirv = 0, dira = 0,
        vel = 0, velv = 0, vela = 0,

        r = 1, rv = 0, ra = 0,
        g = rng.range(128, 255)/255, gv = 0, ga = 0,
        b = rng.range(10, 255)/255,  bv = 0, ba = 0,
        a = rng.range(70, 255)/255,  av = -0.1, aa = 0,
    }
end, },
function(self)
    if nb <= count then nb = nb + 1; self.ps:emit(1) end
end,
count * 2
