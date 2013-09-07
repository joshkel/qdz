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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

local Map = require("engine.Map")
local Qi = require("mod.class.interface.Qi")

newTalent{
    name = "Acid Spray",
    type = {"qi techniques/right hand", 1},
    points = 1,
    cooldown = 6,
    qi = 2,
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

-----------------------------------------------------------------------------
-- Dog-head talents

--[[
Quoting Wikipedia (http://en.wikipedia.org/wiki/Kobold):

"16th-century miners sometimes encountered what looked to be rich veins of copper
or silver, but which, when smelted, proved to be little more than a pollutant
and could even be poisonous. These ores caused a burning sensation to those who
handled them... Miners called these ores cobalt after the creatures from whom
they were thought to come. In 1735, Swedish chemist Georg Brandt isolated a
substance from such ores and named it cobalt rex. In 1780, scientists showed
that this was in fact a new element, which they named cobalt."]]
newTalent {
    name = "Poison Ore Strike",
    type = {"qi techniques/right hand", 1},
    points = 1,
    cooldown = 6,
    qi = 10,
    range = 1,
    radius = 1,
    getDuration = function(self, t) return 5 end,
    getDamage = function(self, t)
        local combat, obj = self:getInvenCombat(self.INVEN_RHAND, true)
        local min_dam, dam = self:combatDamageRange(combat)
        if obj and obj.subtype == "digger" then
            dam = dam / 2
        else
            dam = dam / 4
        end
        dam = dam + self:getTalentLevel(self.T_MINING)
        return dam
    end,
    getDirectDamage = function(self, t) return t.getDamage(self, t) * 3 end,
    target = function(self, t)
         return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), nowarning=true, nolock=true, pass_terrain=true, talent=t}
    end,
    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        local feat = game.level.map(x, y, Map.TERRAIN)
        if not feat then return nil end
        if not feat.dig or not feat.is_stone then
            game.logPlayer(self, "You must select a section of diggable stone to poison.")
            return nil
        end

        if target then
            self:project({type="hit", range=self:getTalentRange(t), talent=t},
                x, y, DamageType.POISON, t.getDamage(self, t) * 3)
        end

        self:project(tg, x, y, function(px, py)
            if game.level.map:checkEntity(px, py, engine.Map.TERRAIN, "block_move") and not game.level.map:checkEntity(px, py, engine.Map.TERRAIN, "pass_projectile") then return end

            local target = game.level.map(px, py, Map.ACTOR)
            if target and self:reactionToward(target) >= 0 then return end

            game.level.map:addEffect(self,
                px, py, t.getDuration(self, t),
                DamageType.QI_CALL, Qi.saveSourceInfo(self, { type=DamageType.POISON_GAS, dam=t.getDamage(self, t) }),
                0,        -- radius 0 for individual clouds
                5, nil,   -- dir (5 for ball effect), angle
                engine.Entity.new{alpha=100, display='', color_br=30, color_bg=180, color_bb=60})
        end)

        return true
    end,
    info = function(self, t)
        return flavorText(
            ("Strikes an adjacent section of diggable stone, releasing clouds "..
            "of poisonous gas in a radius of %i. The gas clouds "..
            "last %i turns and do %i damage each turn.\n\n"..
            "If this directly hits a creature within the stone, it also "..
            "deals %i damage to the creature.\n\n"..
            "Damage is based on your main weapon but is increased if you have a digging tool equipped and / or know Mining."):format(
                self:getTalentRadius(t), t.getDuration(self, t), t.getDamage(self, t), t.getDirectDamage(self, t)),
            "Dog-head men are cunning tricksters and trapsmiths, but one of " ..
            "their simplest methods for discouraging interlopers is to curse " ..
            "a vein of ore, causing it to release poisonous gas when anyone " ..
            "tries to mine it.")
    end,
}

newTalent {
    name = "Poisoned Dart",
    type = {"qi techniques/left hand", 1},
    points = 1,
    cooldown = 6,
    qi = 2,
    range = 5,
    getCombat = function(self, t) return {dam=3} end,
    getPower = function(self, t) return self:talentDamage(self:getSki(), 1, 0.3) end,
    getDuration = function(self, t) return 3 end,
    message = function(self, t) return "@Source@ throws a poisoned dart." end,
    target = function(self, t)
         return {type="bolt", range=self:getTalentRange(t), talent=t, display={display='*', color=colors.GREEN}}
    end,
    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        -- TODO: Debuff instead of just damage over time?
        self:projectile(tg, x, y, function(tx, ty, tg, self, tmp)
            local target = game.level.map(tx, ty, game.level.map.ACTOR)
            if not target then return end
            local combat = t.getCombat(self, t)
            self:attackTargetWith(target, combat, DamageType.PHYSICAL_POISON,
                { power=t.getPower(self, t), duration=t.getDuration(self, t) }, self:getOffHandMult(combat))
        end)

        return true
    end,
    info = function(self, t)
        local combat = t.getCombat(self, t)
        local rules_text = ("Hurls a poisoned dart with range %i, doing %s damage immediately and %i per turn (based on your Skill) for %i turns."):format(
            self:getTalentRange(t), string.describe_range(self:combatDamageRange(combat, self:getOffHandMult(combat))),
            t.getPower(self, t), t.getDuration(self, t))
        if self == game.player then
            return flavorText(rules_text, 
                "Dog-head often employ poisoned darts in their ambushes. You can "..
                "learn to achieve a similar effect by forming your qi into "..
                "short-lived darts of force.")
        else
            return rules_text
        end
    end,
}

newTalent {
    name = "Dog-Head Mining",
    short_name = "DOG_HEAD_MINING",
    type = {"qi techniques/chest", 1},
    points = 1,
    mode = "passive",
    on_learn = function(self, t)
        self:learnTalent(Talents.T_MINING, true)
    end,
    on_unlearn = function(self, t)
        self:unlearnTalent(Talents.T_MINING)
    end,

    count = 3,
    chance = 50,

    info = function(self, t)
        return flavorText(("+1 Mining proficiency. The first %i times you mine "..
            "on each level, you have a %i%% chance of finding gold or gems."):format(
                t.count, t.chance),
            "The dog-head have an instinctive ability to find the richest ore veins, "..
            "such that it often seems to observers that they can swing their pickaxes "..
            "anywhere they want and find treasure.")
    end,

    on_dig = function(self, t, x, y, feat)
        if not feat.is_stone then return end
        game.level.times_dug_stone = (game.level.times_dug_stone or 0) + 1
        if game.level.times_dug_stone <= t.count then
            if rng.percent(t.chance) then
                -- TODO: Make this more interesting.  (ADOM-style magic gems, perhaps?  Ore to upgrade weapons?)
                local item = game.zone:makeEntityByName(game.level, "object", "MONEY_SMALL")
                if not item then return end
                game.level.map:addObject(x, y, item)
                game.logSeen({x=x,y=y}, "The %s contained some treasure!", feat.name)
                if game.level.times_dug_stone == t.count then
                    game.logSeen({x=x,y=y}, "The ore in this region now seems to be mined out.", feat.name)
                end
            end
        end
    end
}

-- According to Wikipedia, some stories have kobolds flying through the air as a
-- fiery stripe or appearing as round lights.
newTalent {
    name = "Dancing Lights",
    type = {"qi techniques/feet", 1},
    points = 1,
    cooldown = 6,
    qi = 2,
    range = function(self, t) return self.lite or 0 end,
    target = function(self, t)
         return {type="hit", range=self:getTalentRange(t), nowarning=true, nolock=true, talent=t}
    end,
    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local orig_x, orig_y = self.x, self.y
        local x, y = self:getTarget(tg)

        if not self:hasLOS(x, y) or game.level.map:checkEntity(x, y, Map.TERRAIN, "block_move") then
            game.logSeen(self, "You cannot dance there.")
            return false
        end

		local tx, ty = util.findFreeGrid(x, y, 0, true, {[Map.ACTOR]=true})
        if not tx or not ty then
            game.logSeen(self, "You cannot dance there.")
            return false
        end

        if not self:teleportRandom(tx, ty, 0) then
            game.logSeen(self, "The technique fails!")
        else
            self:resetMoveAnim()

            -- Not sure the exact relationship between speed / blur and the
            -- dancing_lights particle effect, but these values seem to work
            -- well enough.
            self:setMoveAnim(orig_x, orig_y, 8, 5)

            game.level.map:particleEmitter(orig_x, orig_y, 0, "dancing_lights",
                { delta_x = self.x - orig_x, delta_y = self.y - orig_y })
        end

        return true
    end,
    info = function(self, t)
        return flavorText(("Transforms into a ball of light that immediately moves"..
            "to a given location within %i squares, where you reappear. "..
            "The range is determined by your light radius."):format(self:getTalentRange(t)),
            "Dog-head men have some small affinity with fire; they can "..
            "transform their bodies into floating flames that resemble the "..
            "lanterns in their mining helmets and travel quickly in this form.")
    end,
}

newTalent {
    name = "Mining Light",
    type = {"qi techniques/head", 1},
    points = 1,
    mode = "sustained",
    sustain_qi = 3,
    cooldown = 5,

    lite = 1,
    getAttack = function(self, t)
        return math.floor(self.lite / 2)
    end,

    do_turn = function(self, t)
        local p = self:isTalentActive(t.id)
        if p.prev_lite ~= self.lite then
            if p.attackid then self:removeTemporaryValue("combat_atk", p.attackid) end
            p.attackid = self:addTemporaryValue("combat_atk", t.getAttack(self, t))
            p.prev_lite = self.lite
        end
    end,
    activate = function(self, t)
        local liteid = self:addTemporaryValue("lite", t.lite)
        if self.doFOV then self:doFOV() end
        return {
            liteid = liteid
        }
    end,
    deactivate = function(self, t, p)
        if p.attackid then self:removeTemporaryValue("combat_atk", p.attackid) end
        self:removeTemporaryValue("lite", p.liteid)
        return true
    end,

    info = function(self, t)
        return flavorText(("Adds %i to your light radius and boosts your morale, adding half your light radius to your Attack."):format(t.lite),
            "Although the dog-head have limited darkvision, they often conjure "..
            "small fires for their mining helmets. The light makes working "..
            "underground easier and helps bolster their morale if their traps "..
            "and ambushes fail and they're forced to engage in direct combat.")
    end,
}

