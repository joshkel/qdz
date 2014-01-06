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

require "engine.class"
require "engine.World"
require "engine.interface.WorldAchievements"
local Savefile = require "engine.Savefile"

module(..., package.seeall, class.inherit(engine.World, engine.interface.WorldAchievements))

function _M:init()
    engine.World.init(self)
end

function _M:run()
    self:loadAchievements()
end

--- Requests the world to save
function _M:saveWorld(no_dialog)
    -- savefile_pipe is created as a global by the engine
    savefile_pipe:push("", "world", self)
end

