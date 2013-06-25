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

newTalentType{ type="basic/qi", name = "qi", description = "Basic manipulation of your qi (life energy)" }
newTalentType{ type="basic/combat", name = "combat", description = "Basic combat techniques" }
newTalentType{ type="basic/proficiency", name = "proficiency", description = "Proficients are various (mostly) mundane skills. Most beings learn these through training and practice. As a qi dao zei, you may instead be granted them through the abilities you absorb from your foes."}

newTalentType{ type="qi abilities/right hand", name = "right hand", description = "Qi abilities bound to your right hand. These are typically direct, physical, hand-to-hand attacks." }
newTalentType{ type="qi abilities/left hand", name = "left hand", description = "Qi abilities bound to your left hand. These are typically indirect, magical, and / or ranged attacks." }
newTalentType{ type="qi abilities/chest", name = "chest", description = "Qi abilities bound to your chest. Chest abilities provide defense, enhancement, and healing." }
newTalentType{ type="qi abilities/feet", name = "feet", description = "Qi abilities bound to your feet. These relate to movement and mobility." }
newTalentType{ type="qi abilities/head", name = "head", description = "Qi abilities bound to your head. These may provide perception or knowledge, let you acquire and enhance allies to assist you in combat, or provide other strange and wonderful effects." }

newTalent{
    -- FIXME: Add particle effects for qi aura; add effects for qi focus on combat and describe them
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

If you deal a killing blow to an opponent while focused, you may absorb a portion of the opponent's qi, granting you a new ability or experience.]]
    end
}

newTalent{
    -- FIXME: Differentiate cooldown and range from Kick, and make it use a shield if you have one
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
        self:attackTarget(target)
        return true
    end,
    info = function(self, t)
        return [[Bashes an enemy with your shield (if you have one) or a tackle, possibly knocking it back.

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
        self:attackTarget(target)
        return true
    end,
    info = function(self, t)
        return [[Kicks an enemy.

If this kills an enemy while your qi is focused, you may absorb a portion of the enemy's qi and bind it to your feet.]]
    end,
}

newTalent{
    name = "Acid Spray",
    type = {"qi abilities/right hand", 1},
    points = 1,
    cooldown = 6,
    power = 2,
    range = 6,
    action = function(self, t)
        local tg = {type="ball", range=self:getTalentRange(t), radius=1, talent=t}
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end
        self:project(tg, x, y, DamageType.ACID, 1 + self:getSki(), {type="acid"})
        return true
    end,
    info = function(self, t)
        return "Zshhhhhhhhh!"
    end,
}

