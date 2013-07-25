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

require "engine.class"
require "engine.Projectile"

module(..., package.seeall, class.inherit(engine.Projectile))

function _M:init(t, no_default)
    engine.Projectile.init(self, t, no_default)
end

function _M:makeProject(src, display, def, do_move, do_act, do_stop)
    local p = engine.Projectile.makeProject(self, src, display, def, do_move, do_act, do_stop)

    -- Track the action that created this projectile
    p.last_action = src.last_action

    -- Hack: Turn the engine.projectile into a mod.class.Projectile
    p.__CLASSNAME = _M.name
    setmetatable(p, {__index=_M})

    return p
end

function _M:makeHoming(src, display, def, target, count, on_move, on_hit)
    local p = engine.Projectile.makeHoming(self, src, display, def, target, count, on_move, on_hit)

    -- Track the action that created this projectile
    p.last_action = src.last_action

    -- Hack: Turn the engine.projectile into a mod.class.Projectile
    p.__CLASSNAME = _M.name
    setmetatable(p, {__index=_M})

    return p
end

function _M:act()
    return util.scoped_change(self.src, 'last_action', self.last_action, engine.Projectile.act, self)
end

