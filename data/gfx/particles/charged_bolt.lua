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

tines = 10
life = 10
nb = life
base_x = 0
base_y = 0

local points = {}

local function make_points()
    local base_x = rng.range(-engine.Map.tile_w / 3, engine.Map.tile_w / 3)
    local base_y = rng.range(-engine.Map.tile_h / 3, engine.Map.tile_h / 3)
    points[#points + 1] = { x=base_x, y=base_y, trail=0 }
    for i = 1, tines do
        local angle = math.rad(360 / tines * (i - 1) + rng.range(-10, 10))
        local dev_angle = angle + math.pi / 2
        local dev = rng.range(-3, 3)
        points[#points + 1] = {
            x=base_x + engine.Map.tile_w / 8 * math.cos(angle) + dev * math.cos(dev_angle),
            y=base_y + engine.Map.tile_h / 8 * math.sin(angle) + dev * math.sin(dev_angle),
            trail=0,
        }
        points[#points + 1] = {
            x=base_x + engine.Map.tile_w / 4 * math.cos(angle),
            y=base_y + engine.Map.tile_h / 4 * math.sin(angle),
            trail=#points - 1,
        }
    end
end

return { engine=core.particles.ENGINE_LINES, generator = function()
    if #points == 0 then make_points() end
    local p = table.remove(points, 1)
    print(("%i, %i"):format(p.x, p.y))
	
    return {
        trail = p.trail,
        life = life,
        size = 2, sizev = 0, sizea = 0,

        x = p.x, xv = 0, xa = 0,
        y = p.y, yv = 0, ya = 0,
        dir = 0, dirv = 0, dira = 0,
        vel = 0, velv = 0, vela = 0,

        r = 0, rv = 0, ra = 0,
        g = rng.range(92, 128)/255, gv = 0, ga = 0,
        b = 1, bv = 0, ba = 0,
        a = 1, av = 0, aa = 0,
    }
end, },
function(self)
    if nb == life then
        self.ps:emit(tines * 2 + 1)
        nb = 0
    end
    nb = nb + 1
end,
tines * 3, "particles_images/beam"
