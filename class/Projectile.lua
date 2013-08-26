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
require "engine.Projectile"
local Qi = require "mod.class.interface.Qi"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(engine.Projectile))

function _M:init(t, no_default)
    engine.Projectile.init(self, t, no_default)
end

function _M:maybeAddQiParticles(src, def, display)
    -- TODO: qi_projectile is a cooler effect, but most projectiles move so fast
    -- that you can't see it, so we add qi_trail too, at least for now...
    if src.hasEffect and src:hasEffect(src.EFF_FOCUSED_QI) then
        if not display.particle then display.particle = "qi_projectile" end
        if not display.trail then display.trail = "qi_trail" end
    end
    return display
end

function _M:makeProject(src, display, def, do_move, do_act, do_stop)
    local p = engine.Projectile.makeProject(self, src, self:maybeAddQiParticles(src, def, display), def, do_move, do_act, do_stop)

    -- Hack: Turn the engine.projectile into a mod.class.Projectile
    -- This is a workaround for http://forums.te4.org/viewtopic.php?f=45&t=38519
    -- TODO: It somehow breaks saving games...
    p.__CLASSNAME = _M.name
    setmetatable(p, {__index=_M})

    Qi.saveSourceInfo(src, p)

    return p
end

function _M:makeHoming(src, display, def, target, count, on_move, on_hit)
    local p = engine.Projectile.makeHoming(self, src, display, def, target, count, on_move, on_hit)

    -- Hack: Turn the engine.projectile into a mod.class.Projectile.  See makeProject.
    p.__CLASSNAME = _M.name
    setmetatable(p, {__index=_M})

    Qi.saveSourceInfo(src, p)

    return p
end

function _M:act()
    return Qi.call(self, engine.Projectile.act, self)
end

--- Move animation (code based on ToME's).
-- TODO: Animating projectiles in T-Engine works poorly because they're so short-lived.
function _M:move(x, y, force)
    local ox, oy = self.x, self.y

    local moved = engine.Projectile.move(self, x, y, force)
    if moved and not force and ox and oy and (ox ~= self.x or oy ~= self.y) then
        self:setMoveAnim(ox, oy, 3, self.project and self.project.def and self.project.def.typ.blur_move)
    end

    return moved
end

function _M:tooltip(x, y)
    local color = GameUI.tooltipColor
    local text = GameUI:tooltipTitle('Projectile: '..self.name)

    if config.settings.cheat then
        text:add(true, color.caption, "UID: ", color.text, tostring(self.uid))
    end

    return text
end

