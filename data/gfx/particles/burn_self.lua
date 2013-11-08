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

-- NOTE: A combination of burning_hand and focused_qi.  radius and sradius come
-- from burning_hand, even though the terminology isn't quite right here.
-- start_radius, x, and y are based on focused_qi.
local nb = 10
local radius = 0.5
local life = radius * 2
local start_radius = 15

return { generator = function()
    local sradius = (radius + 0.5) * (engine.Map.tile_w + engine.Map.tile_h) / 2
    local a = math.rad(270)
    local r = 0
    local x = rng.range(-start_radius, start_radius)
    local y = start_radius - math.abs(math.sin(x / start_radius) * start_radius / 2)
    local static = rng.percent(40)
    local vel = sradius * ((24 - nb * 1.4) / 24) / life
    local size = 12 - (12 - nb) * 0.7

    return {
        trail = 1,
        life = life,
        size = size, sizev = 0, sizea = 0,

        x = x - size / 2, xv = 0, xa = 0,
        y = y - size / 2, yv = 0, ya = 0,
        dir = a, dirv = 0, dira = 0,
        vel = rng.float(vel * 0.6, vel * 1.2), velv = 0, vela = 0,

        r = rng.range(200, 255)/255,   rv = 0, ra = 0,
        g = rng.range(100, 150)/255,   gv = 0.005, ga = 0.0005,
        b = rng.range(0, 10)/255,      bv = 0, ba = 0,
        a = rng.range(25, 220)/255,    av = static and -0.034 or 0, aa = 0.005,
    }
end, },
function(self)
    if nb > 0 then
        local i = math.min(nb, 6)
        i = (i * i) * radius
        self.ps:emit(i)
        nb = nb - 1
    end
end,
30*radius*7*12,
"particle_cloud"
