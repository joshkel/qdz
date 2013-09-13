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

local Talents = require "engine.interface.ActorTalents"

--- Resolves equipment creation for an actor
function resolvers.equip(t)
    return {__resolver="equip", __resolve_last=true, t}
end
--- Actually resolve the equipment creation
function resolvers.calc.equip(t, e)
    -- Iterate of object requests, try to create them and equip them
    for i, filter in ipairs(t[1]) do
        local o = game.zone:makeEntity(game.level, "object", filter, nil, true)
        if o then
            if e:wearObject(o, true, false) == false then
                e:addObject(e.INVEN_INVEN, o)
            end

            game.zone:addEntity(game.level, o, "object")
        end
    end
    -- Delete the origin field
    return nil
end

