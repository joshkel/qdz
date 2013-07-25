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

--- Debugging utility function: Attempts to print obj, regardless of what obj is.
function util.inspect(name, obj)
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

--- Temporarily sets t[field] to value, then calls f(...)
function util.scoped_change(t, field, value, f, ...)
    local old_value = t[field]
    t[field] = value
    
    local result = f(...)
    
    t[field] = old_value
    return result
end

