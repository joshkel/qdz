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
    name = "Focus Qi",
    type = {"basic/qi", 1},
    cooldown = 50,
    no_energy = true,
    action = function(self, t)
        self:setEffect(self.EFF_FOCUSED_QI, 1, {})

        -- HACK: Because this is no_energy, duration doesn't count down as we'd
        -- expect.  (It takes one round for the duration to reach 0 - this is 
        -- usually the round when a 1-duration effect is added - then another
        -- round for the effect to be removed.  So we actually want a duration
        -- of 0, so that it's immediately removed, but T-Engine interprets
        -- "assign a duration of 0" as "remove the effect.")
        --
        -- Force taking one off the duration now as a workaround.
        self:timedEffects(function(def, p) return def.id == self.EFF_FOCUSED_QI end)

        return true
    end,
    info = function(self, t)
        return [[Focuses your qi into a visibly glowing aura around you. Qi focus only lasts for one turn, but while focused, your attacks are guaranteed to hit and do maximum damage.

If you kill an opponent while focused, you may absorb a portion of the opponent's qi, granting you a new technique or an experience bonus.

The type of technique absorbed depends on how you deal the killing blow: whether with a right hand (or two handed) weapon, left hand (or ranged) weapon (or other item), bash, kick, or qi technique.]]
    end
}

newTalent{
    name = "Off-Hand Attack",
    short_name = "OFF_HAND_ATTACK",
    type = {"basic/combat", 1},
    cooldown = 3,
    requires_target = true,
    range = 1,
    speed = 2.0,
    action = function(self, t)
        -- TODO: This will need to be reworked if we ever permit the main weapon to be wielded in the left hand
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        local combat = self:getInvenCombat(self.INVEN_LHAND, true)
        self:attackTargetWith(target, self:combatMod(combat, {attack=2}), nil, nil, self:getOffHandMult(combat))
        return true
    end,
    info = function(self, t)
        -- TODO: It'd be nice to describe which exactly it is, based on current equipment.  Also need damage numbers.
        return [[A quick, unexpected attack with your off-hand weapon, or a quick shield jab, or a quick unarmed strike with your left hand, as appropriate.

This is weaker than a normal attack (dealing off-hand damage or half of regular unarmed damage) but can be performed twice as quickly and has +2 to Attack.]]
    end,
}

newTalent{
    -- TODO: Make it use a shield if you have one?
    name = "Bash",
    type = {"basic/combat", 1},
    cooldown = 6,
    requires_target = true,
    range = 1,
    getDistance = function(self, t)
        return (self:getStr() + self:getCon()) / 5
    end,
    action = function(self, t)
        -- TODO? This block is duplicated throughout basic.lua and other talents - can it be cleaned up?
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        local speed, hit = self:attackTargetWith(target, self:getObjectCombat(nil, "bash"),
            DamageType.PHYSICAL_KNOCKBACK, { distance = t.getDistance(self, t) })
        if not hit then
            if target:canBe("knockback") then
                -- TODO: Keep this "driven back a square" mechanic?
                -- It implies that an immobile target can't dodge a tackle...
                target:knockback(self.x, self.y, 1)
                target:setMoveAnim(x, y, 8, 4)
                game.logSeen(target, ("%s is driven back!"):format(target.name:capitalize()))
            else
                game.logSeen(target, ("%s stands %s ground!"):format(target.name:capitalize(), string.his(target)))
            end
        end
        return true
    end,
    info = function(self, t)
        return ([[Bashes into an enemy with a shoulder tackle, dealing %s damage and knocking it back %i squares. Damage and knockback distance are determined by your Strength and Constitution. Even if your opponent manages to dodge, it will be driven back one square.

If this kills an enemy while your qi is focused, you may absorb a portion of the enemy's qi and bind it to your chest.]]):format(string.describe_range(self:combatDamageRange(self:getObjectCombat(nil, "bash"))), t.getDistance(self, t))
    end,
}

newTalent{
    name = "Kick",
    type = {"basic/combat", 1},
    cooldown = 6,
    requires_target = true,
    range = 1,
    action = function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        local combat = self:getObjectCombat(nil, "kick")
        local speed, hit = self:attackTargetWith(target, combat)
        if hit and not target.dead then
            if not target:canBe("knockback") then
                game.logSeen(target, ("%s stands its ground!"):format(target.name:capitalize()))
            elseif self:skillCheck(self:combatAttack(combat), target:combatDefense()) then
                -- TODO: Replace that skillCheck with some kind of combat maneuver check or saving throw
                target:setEffect(target.EFF_PRONE, 1, {})
            end
        end
        return true
    end,
    info = function(self, t)
        return ([[Kicks an enemy, dealing %s damage and possibly knocking it prone. A prone enemy's turn is delayed and is easier to hit. Damage and knockdown chance are determined by your Strength and Agility.

If this kills an enemy while your qi is focused, you may absorb a portion of the enemy's qi and bind it to your feet.]]):format(string.describe_range(self:combatDamageRange(self:getObjectCombat(nil, "kick"))))
    end,
}

