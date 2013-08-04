-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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

require "engine.class"
local Talents = require "engine.interface.ActorTalents"

--- Interface to add ToME archery combat system
module(..., package.seeall, class.make)

--- Static function that saves a source's qi state to an intermediate effect
--- so that the intermediate effect can properly trigger absorb.
function _M:saveSourceInfo(from, to)
    if from.intermediate then
        _M:saveSourceInfo(from.intermediate, to)
        return
    end

    to.last_action = from.last_action

    -- Allow focused_qi state to carry over from previous applications, if relevant.
    if not to.focused_qi and from.focused_qi or (from.hasEffect and from:hasEffect(from.EFF_FOCUSED_QI)) then
        to.focused_qi = true
    end
end

function _M:callIntermediate(intermediate, src, f, ...)
    return util.scoped_change(src, { intermediate=intermediate }, f, ...)
end

