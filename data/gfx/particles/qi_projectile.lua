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

local nb = 0

-- This particle effect creates a sort of qi wake around a qi-focused projectile.
return { generator = function()
    -- Determine angle of movement for the projectile
    local move_a
    if proj_x == src_x then
        move_a = proj_y > src_y and math.pi * 0.5 or math.pi * 1.5
    else
        move_a = math.atan((proj_y - src_y) / (proj_x - src_x))
    end

    local size = rng.range(1, 8)
    local r = (engine.Map.tile_w + engine.Map.tile_h) / 2 / 3
    local x = r * math.cos(move_a) - size / 2
    local y = r * math.sin(move_a) - size / 2
    
    -- Move 120+ degrees to one side or the other of move_a
    local dir_a
    if rng.percent(50) then
        dir_a = 2.6 * math.pi / 3 * rng.table{1, -1} + move_a
    else
        dir_a = rng.float(2.6, 3) * math.pi / 3 * rng.table{1, -1} + move_a
    end

    return {
        trail = 1,
        life = rng.range(10, 15),
        size = rng.range(3, 5), sizev = 0, sizea = 0,

        x = x, xv = 0, xa = 0,
        y = y, yv = 0, ya = 0,
        dir = dir_a, dirv = 0, dira = 0,
        vel = 1, velv = 0, vela = 0,

        r = 0, rv = 0, ra = 0,
        g = 0, gv = 0, ga = 0,
        b = rng.range(10, 30)/255,  bv = rng.range(0, 10)/100, ba = 0,
        a = rng.range(70, 255)/255, av = 0, aa = 0,
    }
end, },
function(self)
    self.ps:emit(2)
end
