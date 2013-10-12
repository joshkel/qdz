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
require "mod.class.Actor"
local ActorAI = require "engine.interface.ActorAI"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(mod.class.Actor, engine.interface.ActorAI))

function _M:init(t, no_default)
    mod.class.Actor.init(self, t, no_default)
    ActorAI.init(self, t)
end

function _M:act()
    -- Do basic actor stuff
    if not mod.class.Actor.act(self) then return end

    -- Compute FOV, if needed
    self:doFOV()

    -- Let the AI think .... beware of Shub !
    -- If AI did nothing, use energy anyway
    self:doAI()
    if not self.energy.used then self:useEnergy() end
end

function _M:doFOV()
    self:computeFOV(self.sight or 20)
end

--- Called by ActorLife interface
-- We use it to pass aggression values to the AIs
function _M:onTakeHit(value, src)
    if not self.ai_target.actor and src.targetable then
        self.ai_target.actor = src
    end

    return mod.class.Actor.onTakeHit(self, value, src)
end

function _M:tooltip()
    local color = GameUI.tooltipColor
    local text = mod.class.Actor.tooltip(self)

    -- Sample code for displaying available qi techniques in tooltips.
    -- Disabled for now; it makes the tooltips too verbose.
    --[[if self.can_absorb then
        local absorb_count = #table.keys(self.can_absorb)
        text:add(true, color.caption, 'Available Qi Techniques')
        for i, v in pairs(Qi.slots_order) do
            if self.can_absorb[v] then
                text:add(true, color.caption, Qi.slots_def[v].desc:capitalize(), ': ', color.text, self:getTalentFromId(self.can_absorb[v]).name)
            end
        end
    end]]

    if config.settings.cheat then
        text:add(true, color.caption, 'Target: ', color.text, self.ai_target.actor and self.ai_target.actor.name or "none")
        text:add(true, color.caption, 'UID: ', color.text, tostring(self.uid))
    end

    return text
end

function _M:aiCanPass(x, y)
    if self:attr("forbid_diagonals") and self.x ~= x and self.y ~= y then return false end
    return ActorAI.aiCanPass(self, x, y)
end

