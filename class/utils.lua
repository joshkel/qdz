-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
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

require("engine.utils")

--- Debugging utility function: Attempts to print obj, whatever it is.
function util.inspect(name, obj)
    if not obj then name, obj = "obj", name end
    print(("DEBUG: %s is a %s"):format(name, type(obj)))
    if type(obj) == "table" then
        if #obj and #obj ~= 0 then
            table.iprint(obj, "  ")
        else
            table.print(obj, "  ")
        end
    else
        print(tostring(obj))
    end
end

--- Temporarily applies the fields and values within t to obj, returning obj's previous values.
function util.apply_temp_change(obj, t)
    local saved = {}
    for k, v in pairs(t) do
        saved[k] = obj[k]
        obj[k] = v
    end
    return saved
end

function util.revert_temp_change(obj, t, saved)
    for k, v in pairs(t) do
        obj[k] = saved[k]
    end
end

--- Temporarily applies the fields and values within t to obj, then calls f(...)
function util.scoped_change(obj, t, f, ...)
    local saved
    if obj then 
        saved = util.apply_temp_change(obj, t)
    end

    local result = f(...)

    if obj then
        util.revert_temp_change(obj, t, saved)
    end

    return result
end

-- Helper function: Munges the source coordinates of a projection from
-- x, y to src_x, src_y so that they're valid.
--
-- This is useful to have the projection start and end at x, y if possible
-- while handling the special case of x, y being a wall (in which case we
-- need extra handling to ensure that the projection isn't centered on the
-- wall, potentially bleeding through to either side).
--
-- Assumes that x, y and src_x, src_y are only one square apart.
--
-- This doesn't really belong in utils, but I don't know where it does belong.
function util.mungeProjectSource(x, y, src_x, src_y)
    local Map = require("engine.Map")
    local is_valid = function(x, y) return not game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") or game.level.map:checkEntity(x, y, Map.TERRAIN, "pass_projectile") end

    -- If destination coordinates are valid, then use those.
    if is_valid(x, y) then return x, y end

    -- Try to find source coordinates "far away" from the destination.
    -- Check to the left and right of the source.
    local coords = util.adjacentCoords(src_x, src_y)
    local sides = util.dirSides(util.getDir(x, y, src_x, src_y), src_x, src_y)
    local result = {}
    for i, v in ipairs({'left', 'right'}) do
        if is_valid(unpack(coords[sides[v]])) then table.insert(result, coords[sides[v]]) end
    end
    if #result ~= 0 then
        result = rng.table(result)
        return result[1], result[2]
    end

    -- Fall back to source coordinates if necessary.
    return src_x, src_y
end

function string.describe_range(from, to, space)
    if from == to then
        return tostring(from)
    elseif space then
        return("%i - %i"):format(from, to)
    else
        return("%i-%i"):format(from, to)
    end
end

string.vowels = { a=true, e=true, i=true, o=true, u=true }

--- Simplistic pluralization function.  Special cases will be added as needed.
function string.pluralize(s, n)
    if n == 1 then
        return s
    elseif string.vowels[s:sub(-1)] then
        return s .. "es"
    else
        return s .. "s"
    end
end

--- Adds an indefinite article to s.  Special cases will be added as needed.
--- See also T-Engine's string.a_an.
function string.a(s)
    if string.vowels[s:sub(1, 1)] then
        return "an " .. s
    else
        return "a " .. s
    end
end

--- See also T-Engine's string.his_her.
function string.his(t)
    if t.male then return "his"
    elseif t.female then return "her"
    else return "its"
    end
end

function string.he(t)
    if t.male then return "he"
    elseif t.female then return "she"
    else return "it"
    end
end

function string.him(t)
    if t.male then return "him"
    elseif t.female then return "her"
    else return "it"
    end
end

--- See also T-Engine's string.his_her_self.
function string.himself(t)
    if t.male then return "himself"
    elseif t.female then return "herself"
    else return "itself"
    end
end

--- From http://lua-users.org/wiki/StringRecipes
function string.startsWith(s, start)
    return string.sub(s, 1, string.len(start)) == start
end

--- From http://lua-users.org/wiki/StringRecipes
function string.endsWith(s, ending)
    return ending == '' or string.sub(s, -string.len(ending)) == ending
end

--- Rounds a number, rounding .5 away from 0.  See http://lua-users.org/wiki/SimpleRound
function math.round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

--- Sums the values in t
function math.sum(t)
    local sum = 0
    for i, v in ipairs(t) do
        sum = sum + v
    end
    return sum
end

--- Averages the values in t
function math.average(t)
    return math.sum(t) / #t
end

utf8 = {
    ldquo = "\xe2\x80\x9c",
    rdquo = "\xe2\x80\x9d",
}
