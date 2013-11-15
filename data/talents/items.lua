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

local Map = require "engine.Map"
local Object = require "mod.class.Object"
local Particles = require "engine.Particles"

newTalent {
    name = "Smoke Bomb",
    type = {"basic/items", 1},
    mode = "activated",
    range = 5,
    radius = 1,
    duration = 4,
    target = function(self, t) return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), nowarning=true, stop_block=true, talent=t, display={display='*', color=colors.LIGHT_GRAY}, name="smoke bomb"} end,

    message = function(self, t) return "@Source@ throws a smoke bomb." end,

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end

        self:projectile(tg, x, y, function(px, py)
            -- Based on ToME's Creeping Dark
            local e = Object.new{
                name = "smoke cloud",
                x = px, y = py,
                duration = t.duration - 1,  -- Subtract 1 to sync cloud duration with creator's turns
                block_sight = true,

                on_stand = function(self, x, y, who)
                    who:setEffect(who.EFF_SMOKE_CONCEALMENT, 1, {})
                end,

                act = function(self)
                    local Map = require "engine.Map"

                    self:useEnergy()

                    if self.duration <= 0 then
                        if self.particles then game.level.map:removeParticleEmitter(self.particles) end
                        game.level.map:remove(self.x, self.y, Map.TERRAIN_CLOUD)
                        game.level:removeEntity(self, true)
                    else
                        self.duration = self.duration - 1
                    end
                end,
            }
            game.level:addEntity(e)
            game.level.map(px, py, Map.TERRAIN_CLOUD, e)

            e.particles = Particles.new("smoke_cloud", 1, {})
            e.particles.x, e.particles.y = px, py
            game.level.map:addParticleEmitter(e.particles)

            local actor = game.level.map(px, py, Map.ACTOR)
            if actor then e:on_stand(px, py, actor) end
        end)

        return true
    end,

    info = function(self, t)
        return ("Creates a smoke cloud of radius %i lasting %i turns. The smoke blocks line of sight and grants concealment to everyone in it."):format(t.radius, t.duration)
    end,
}

newTalent {
    name = "Body Hardening",
    type = {"basic/items", 1},
    mode = "activated",
    duration = 6,

    getPower = function(self, t)
        return self:talentDamage(self:getMnd(), 1, 2)
    end,

    action = function(self, t)
        self:setEffect(self.EFF_BODY_HARDENING, t.duration, { power=t.getPower(self, t) })
        return true
    end,

    info = function(self, t)
        return ("Qi to flow through your physical body, making your skin hard enough to turn aside some attacks. This increases your life by %i for %i turns."):format(t.getPower(self, t), t.duration)
    end,
}

