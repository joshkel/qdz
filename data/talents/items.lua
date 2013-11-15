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

                on_stand = function(e, x, y, who)
                    who:setEffect(who.EFF_SMOKE_CONCEALMENT, 1, {})
                end,

                act = function(e)
                    local Map = require "engine.Map"

                    e:useEnergy()

                    if e.duration <= 0 then
                        if e.particles then game.level.map:removeParticleEmitter(e.particles) end
                        game.level.map:remove(e.x, e.y, Map.TERRAIN_CLOUD)
                        game.level:removeEntity(e, true)
                    else
                        e.duration = e.duration - 1
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
        return ("Qi to flow through your physical body, making your skin hard enough to turn aside some attacks. This increases your life by %i (based on your Mind) for %i turns."):format(t.getPower(self, t), t.duration)
    end,
}

newTalent {
    name = "Explosive Tag",
    type = {"basic/items", 1},
    mode = "activated",
    range = 1,
    radius = 1,

    message = function(self, t) return "@Source@ reads an explosive tag. The tag begins to smoke." end,

    getDamage = function(self, t)
        return self:talentDamage(self:getMnd(), 4)
    end,

    action = function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)

        -- Hack: Targeting yourself returns nil for x, y.  Not sure why, but
        -- we'll support it rather than messing with tg parameters to change it.
        -- Also check target == self in case that behavior ever changes.
        if (not x and not y and target) or target == self then
            x, y = target.x, target.y
            target = nil
        end

        if not x or not y then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        if target then
            game.logSeen2(self, target, game.flash.NEUTRAL, "%s attaches an explosive tag to %s.", self:getSrcName():capitalize(), target:getTargetName(self))
        else
            game.logSeen(self, game.flash.NEUTRAL, "%s attaches an explosive tag to the %s.", self:getSrcName():capitalize(), game.level.map(x, y, Map.TERRAIN).name)
        end

        local e = Object.new{
            name = "explosive tag",
            duration = 1,

            act = function(e)
                e:useEnergy()

                if e.duration > 0 then
                    e.duration = e.duration - 1
                    return
                end

                local x, y
                if e.target and not e.target.dead then x, y = e.target.x, e.target.y
                else x, y = e.x, e.y end

                -- FIXME: Because we mess with start_x and start_y, bombing a wall can bleed through to either side of the wall.
                -- FIXME: Finalize damage types, do knockback, etc.
                self:project({type="ball", radius=self:getTalentRadius(t), talent=t, start_x=x, start_y=y},
                    x, y, DamageType.FIRE, t.getDamage(self, t))

                game.level.map:particleEmitter(x, y, self:getTalentRadius(t), "explosion", { radius=self:getTalentRadius(t) })
                game.level:removeEntity(e, true)
            end,
        }

        -- This is a bit tricky.  If we don't mess with energy at all, then
        -- the bomb's turns occur simultaneously with the player, so it's
        -- semi-random whether they occur before or after.
        --
        -- By setting the bomb halfway through the turn, we always give the
        -- player a whole turn, but we also give most enemies a turn, so the
        -- player can't (e.g.) bomb an enemy then step away without giving the
        -- enemy a chance to follow.
        e.energy.value = game.energy_to_act / 2

        e.target = target
        e.x, e.y = x, y
        game.level:addEntity(e)

        return true
    end,

    info = function(self, t)
        return ("A paper containing the character for \"explode,\" when prepared using a special assassin's technique and charged with qi, creates an effective bomb. When activated, it can be attached to an opponent or the floor. After 1 turn, it detonates, dealing %i fire and physical damage (based on your Mind) and causing knockback in a %i radius."):format(t.getDamage(self, t), t.radius)
    end,
}


