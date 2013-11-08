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

-- NOTE: Duplication between this and charged_bolt_hit

local points = {}

local function make_points()
    local angle1 = math.rad(rng.range(0, 360))
    local angle2 = angle1 + math.rad(rng.range(-15, 15)) + math.pi
    local life = rng.range(10, 20)
    points = {{
            x = engine.Map.tile_w * math.cos(angle1) * rng.float(0.2, 0.4),
            y = engine.Map.tile_h * math.sin(angle1) * rng.float(0.2, 0.4),
            life = life,
        }, {
            x = engine.Map.tile_w * rng.float(-0.2, 0.2),
            y = engine.Map.tile_h * rng.float(0.2, 0.2),
            life = life,
            prev = 0
        }, {
            x = engine.Map.tile_w * math.cos(angle2) * rng.float(0.2, 0.4),
            y = engine.Map.tile_h * math.sin(angle2) * rng.float(0.2, 0.4),
            life = life,
            prev = 1
        }
    }
end

return { engine=core.particles.ENGINE_LINES, generator = function()
    if #points == 0 then make_points() end
    local p = table.remove(points, 1)
    return {
        trail = p.prev,
        life = p.life,
        size = 3, sizev = 0, sizea = 0,

        x = p.x, xv = 0, xa = 0,
        y = p.y, yv = 0, ya = 0,
        dir = 0, dirv = 0, dira = 0,
        vel = 0, velv = 0, vela = 0,

        r = 0, rv = 0, ra = 0,
        g = 0x3c/255, gv = 0, ga = 0,
        b = 1, bv = 0, ba = 0,
        a = 1, av = 0, aa = 0
    }
end, },
function(self)
    if not self.nb and rng.chance(3) then self.nb = 200 end
    self.nb = (self.nb or 0) + 1
    if self.nb >= 200 / power then
        self.nb = 0
        self.ps:emit(3)
    end
end,
20 * 3,
nil,
true
