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
local Qi = require "mod.class.interface.Qi"

newTalent {
    name = "Smoke Bomb",
    type = {"basic/items", 1},
    mode = "activated",
    -- Item talent: no need for qi cost or cooldown
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
    -- Item talent: no need for qi cost or cooldown
    duration = 6,

    getPower = function(self, t)
        return self:talentDamage(self:getMnd(), 10)
    end,

    action = function(self, t)
        self:setEffect(self.EFF_BODY_HARDENING, t.duration, { power=t.getPower(self, t) })
        return true
    end,

    info = function(self, t)
        return ("Qi flows through your physical body, making your skin hard enough to turn aside some attacks. This increases your life by %i (based on your Mind) for %i turns."):format(t.getPower(self, t), t.duration)
    end,
}

newTalent {
    name = "Explosive Tag",
    type = {"basic/items", 1},
    mode = "activated",
    -- Item talent: no need for qi cost or cooldown
    range = 1,
    radius = 1,

    message = function(self, t) return "@Source@ reads an explosive tag. The tag begins to smoke." end,

    getDamage = function(self, t)
        return self:talentDamage(self:getMnd(), 12)
    end,

    action = function(self, t)
        -- Setting a bomb at your feet is risky but legal, so nowarning.
        local tg = {type="hit", range=self:getTalentRange(t), nowarning=true}
        local x, y, target = self:getTarget(tg)

        -- Targeting self should actually plant the bomb at your feet.
        if target == self then
            target = nil
        end

        if not x or not y then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        if target then
            game.logSeen({self, target}, game.flash.NEUTRAL, "%s attaches an explosive tag to %s.", self:getSrcName():capitalize(), target:getTargetName(self))
        else
            game.logSeen(self, game.flash.NEUTRAL, "%s attaches an explosive tag to the %s.", self:getSrcName():capitalize(), game.level.map(x, y, Map.TERRAIN).name)
        end

        -- The logic here gets confusing, because there are several coordinates
        -- we're dealing with:
        -- * The target x and y of the bomb. The bomb may be attached to a grid
        --   (e.x and e.y are target x and y), or it may be attached to an
        --   Actor (e.target gives the actor, so use e.target.x and e.target.y).
        -- * The source (self) x and y when the bomb was set. This is used when
        --   projecting the explosion. (If we don't use this, and if the bomb is
        --   set on a wall, then it can bleed through to either side of the
        --   wall.)
        -- * The source (self) x and y when the bomb goes off. This is a hack to
        --   ensure that the bomb causes knockback, even at its epicenter.
        --   (Imagine it as the player setting a bomb on an enemy's chest; even
        --   if the player then teleports to the other side of the enemy, the
        --   enemy will turn to face, and the blast will knock the enemy away
        --   from the player.)

        local e = Object.new{
            name = "explosive tag",
            duration = 1,
            damage_message_passive = true,
            talent = t,

            act = function(e)
                local DamageType = require "engine.DamageType"
                local Qi = require "mod.class.interface.Qi"
                local self = e.src
                local t = e.talent

                e:useEnergy()

                if e.duration > 0 then
                    e.duration = e.duration - 1
                    return
                end

                local x, y
                if e.target then x, y = e.target.x, e.target.y
                else x, y = e.x, e.y end

                local start_x, start_y = util.mungeProjectSource(x, y, e.src_orig_x, e.src_orig_y)

                game.logSeen({x=x, y=y}, "The tag explodes!")
                if e.target then
                    e.target:removeParticles(e.particles)
                else
                    game.level.map:removeParticleEmitter(e.particles)
                end

                local saved = Qi.preCall(e)
                self:project({type="ball", radius=self:getTalentRadius(t), talent=t, start_x=start_x, start_y=start_y},
                    x, y, DamageType.EXPLOSION, { dam=t.getDamage(self, t), distance=t.radius+1, src_x=x, src_y=y, alt_src_x=self.x, alt_src_y=self.y })
                Qi.postCall(e, saved)

                game.level.map:particleEmitter(x, y, self:getTalentRadius(t), "explosion", { radius=self:getTalentRadius(t) })
                game.level:removeEntity(e, true)
            end,
        }

        e.target = target
        e.x, e.y = x, y
        e.src_orig_x, e.src_orig_y = self.x, self.y

        -- TODO: Particles are too hard to see atop a wall grid, and there are no tooltips.
        e.particles = Particles.new("bomb_fuse", 1, {})
        if e.target then
            e.target:addParticles(e.particles)
        else
            e.particles.x, e.particles.y = x, y
            game.level.map:addParticleEmitter(e.particles)
        end

        -- Add the bomb *after* the target (if any), to ensure that the target
        -- gets two moves to respond.  This means that if, e.g., the player
        -- tags an enemy then tries to step away, the enemy can follow before
        -- the bomb detonates.
        -- FIXME: Not quite perfect. Putting a tag on terrain if no enemies have died gives you two turns???
        game.level:addEntity(e, target)

        Qi.saveSourceInfo(self, e)

        return true
    end,

    info = function(self, t)
        return ("Attaches an explosive tag to an adjacent opponent or terrain. After 1 turn, the tag detonates, dealing %i fire and physical damage (based on your Mind) and causing knockback in a %i radius."):format(t.getDamage(self, t), t.radius)
    end,
}

