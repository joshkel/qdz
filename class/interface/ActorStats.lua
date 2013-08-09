-- Qi Dao Zei
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

require "engine.interface.ActorStats"

module(..., package.seeall, class.inherit(
    engine.interface.ActorStats
))

---Overrides engine.interface.ActorStats to add some additional details
function _M:defineStat(name, short_name, default_value, min, max, desc, gain_msg, lose_msg)
    engine.interface.ActorStats:defineStat(name, short_name, default_value, min, max, desc)
    table.merge(self.stats_def[short_name], {
        gain_msg = gain_msg,
        lose_msg = lose_msg
    })
end
