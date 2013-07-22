-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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

newTalent{
    -- FIXME: add combat bonuses for qi focus and describe them
    name = "Focus Qi",
    type = {"basic/qi", 1},
    points = 1,
    cooldown = 50,
    action = function(self, t)
        self:setEffect(self.EFF_FOCUSED_QI, 1, {})
        return true
    end,
    info = function(self, t)
        return [[Focuses your qi into a visibly glowing aura around you.

If you deal a killing blow to an opponent while focused, you may absorb a portion of the opponent's qi, granting you a new ability or experience.

The type of ability absorbed depends on how you deal the killing blow: whether a right hand (or two handed) weapon, left hand (or ranged) weapon, bash, kick, or qi ability.]]
    end
}

newTalent{
    -- FIXME: Differentiate cooldown and effect from Kick, and make it use a shield if you have one
    name = "Bash",
    type = {"basic/combat", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = 1,
    action = function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        target:knockback(self.x, self.y, 2 + self:getSki())
        target:setMoveAnim(x, y, 8, 5)
        self:attackTarget(target)
        return true
    end,
    info = function(self, t)
        return [[Bashes an enemy with your shield (if you have one) or a tackle, damaging it and knocking it back.

If this kills an enemy while your qi is focused, you may absorb a portion of the enemy's qi and bind it to your chest.]]
    end,
}

newTalent{
    name = "Kick",
    type = {"basic/combat", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = 1,
    action = function(self, t)
        -- FIXME: Some sort of unique effect here, and update the description below
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        target:knockback(self.x, self.y, 2 + self:getSki())
        target:setMoveAnim(x, y, 8, 5)
        self:attackTarget(target)
        return true
    end,
    info = function(self, t)
        return [[Kicks an enemy, damaging it and knocking it back.

If this kills an enemy while your qi is focused, you may absorb a portion of the enemy's qi and bind it to your feet.]]
    end,
}

