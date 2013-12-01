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

newTalent{
    name = "Sweep",
    type = {"basic/weapons", 1},
    cooldown = 6,
    requires_target = true,
    range = 1,
    message = function(self, t) return ("@Source@ sweeps %s staff."):format(string.his(self)) end,

    attack = function(self, t, target, combat, mult)
        local speed, hit = self:attackTargetWith(target, combat)
        if hit and not target.dead then
            if not target:canBe("knockback") then
                game.logSeen(target, ("%s stands its ground!"):format(target.name:capitalize()))
            elseif self:isCrit(target) or self:skillCheck(self:combatAttack(combat), target:combatDefense()) then
                -- TODO: Replace that skillCheck with some kind of combat maneuver check or saving throw.  Ditto for Kick.
                target:setEffect(target.EFF_PRONE, 1, {})
            end
        end
        return speed, hit
    end,
    action = meleeTalent(function(self, t, target)
        local combat = self:findCombat(function(combat, o) return o.subtype == "staff" end)
        if not combat then
            game.logPlayer(self, "You can only use Sweep with a staff equipped.")
            return nil
        end

        -- FIXME: Use speed
        t.attack(self, t, target, combat)
        return true
    end),

    info = function(self, t)
        return [[Sweeps your staff, doing normal damage and attempting to knock the enemy down. (With a critical hit, knockdown is guaranteed.)]]
    end,
}

newTalent{
    name = "Spinning Halberd",
    type = {"basic/weapons", 1},
    cooldown = 10,
    requires_target = true,
    range = 1,
    radius = 1,
    mult = 0.5,
    target = function(self, t)
        return {type="ball", range=self:getTalentRange(t), selffire=false, radius=self:getTalentRadius(t)}
    end,

    message = function(self, t) return ("@Source@ spins %s polearm wildly."):format(string.his(self)) end,

    attack = function(self, t, target, combat, mult)
        local speed, hit

        self:project(self:getTalentTarget(t), self.x, self.y, function(px, py, tg, self)
            local this_target = game.level.map(px, py, Map.ACTOR)
            if this_target and this_target ~= self then
                local can_crit = this_target == target
                local this_mult = mult or 1
                if this_target ~= target then this_mult = this_mult * t.mult end

                local s, h = self:attackTargetWith(this_target, combat,
                    DamageType.PHYSICAL_KNOCKBACK, { distance=1 }, this_mult, can_crit)
                if not h then
                    if this_target:canBe("knockback") then
                        -- TODO: Keep this "driven back a square" mechanic?  See Bash.
                        this_target:knockback(self.x, self.y, 1)
                        this_target:setMoveAnim(px, py, 8, 4)
                        game.logSeen(this_target, ("%s is driven back!"):format(this_target.name:capitalize()))
                    else
                        game.logSeen(this_target, ("%s stands %s ground!"):format(this_target.name:capitalize(), string.his(this_target)))
                    end
                end
                speed = math.max(speed or 0, s)
                hit = hit or h
            end
        end)

        return speed, hit
    end,
    action = function(self, t)
        local combat = self:findCombat(function(combat, o) return o.subtype == "polearm" end)
        if not combat then
            game.logPlayer(self, "You can only use Spinning Halberd with a polearm equipped.")
            return nil
        end

        -- FIXME: Use speed
        t.attack(self, t, nil, combat)
        return true
    end,

    info = function(self, t)
        return ([[Spins your polearm, attempting to hit everyone around you for %i%% damage, and driving them back 1 square.]]):format(t.mult * 100)
    end,
}

