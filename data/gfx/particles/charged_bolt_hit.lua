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

-- NOTE: Duplication between this and charged

local points = {}
local count = 4

local function make_points(count)
    local r = math.sqrt(engine.Map.tile_w * engine.Map.tile_w + engine.Map.tile_h * engine.Map.tile_h) / 2

    for i = 1, count do
        local angle = math.rad(360 / count * (i - 1) + rng.range(-20, 20))
        local this_r = r * rng.float(0.4, 0.8)
        local a1 = angle + math.rad(rng.range(20, 30))
        local a2 = angle - math.rad(rng.range(20, 30))
        local life = rng.range(10, 20)
        local dev = rng.range(-3, 3)

        points[#points + 1] = {
            x = this_r * math.cos(a1),
            y = this_r * math.sin(a1),
            life = life,
            trail = -1,
        }
        points[#points + 1] = {
            x = this_r * math.cos(angle) + dev * math.cos(angle),
            y = this_r * math.sin(angle) + dev * math.sin(angle),
            life = life,
            trail = #points - 1,
            dir = angle,
            vel = rng.float(-0.5, 0.5),
        }
        points[#points + 1] = {
            x = this_r * math.cos(a2),
            y = this_r * math.sin(a2),
            life = life,
            trail = #points - 1,
        }
    end
end

make_points(count)

return { engine=core.particles.ENGINE_LINES, generator = function()
    local p = table.remove(points, 1)
    return {
        trail = p.trail,
        life = p.life,
        size = 3, sizev = 0, sizea = 0,

        x = p.x, xv = 0, xa = 0,
        y = p.y, yv = 0, ya = 0,
        dir = p.dir, dirv = 0, dira = 0,
        vel = p.vel, velv = 0, vela = 0,

        r = 0, rv = 0, ra = 0,
        g = 0x3c/255, gv = 0, ga = 0,
        b = 1, bv = 0, ba = 0,
        a = 1, av = 0, aa = 0
    }
end, },
function(self)
    self.nb = (self.nb or 0) + 1
    if self.nb <= count then
        self.ps:emit(3)
    end
end,
3 * count, "particles_images/beam"
