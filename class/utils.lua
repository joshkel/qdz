-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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

function string.describe_range(from, to)
    return from == to and tostring(from) or ("%i-%i"):format(from, to)
end

--- Rounds a number, rounding .5 away from 0.  See http://lua-users.org/wiki/SimpleRound
function math.round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

