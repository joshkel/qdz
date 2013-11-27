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

local GameRules = require("mod.class.GameRules")

newTalent {
    name = "Capacitive Appendage",
    type = {"qi techniques/right hand", 1},
    mode = "sustained",
    sustain_qi = 5,
    cooldown = 5,

    getPerTurn = function(self, t)
        return 0.5 * GameRules:damScale(self.level)
    end,
    getMaxCharge = function(self, t)
        return self:talentDamage(self:getCon(), 6 + math.floor(GameRules.item_dam_per_level * self.level))
    end,

    do_turn = function(self, t)
        local eff = self:hasEffect(self.EFF_CHARGED)
        if not eff then
            self:setEffect(self.EFF_CHARGED, 1, { power=0 })
        else
            self.tempeffect_def[self.EFF_CHARGED].add_power(self, eff, t.getPerTurn(self, t), t.getMaxCharge(self, t))
        end
    end,
    activate = function(self, t)
        return {}
    end,
    deactivate = function(self, t, p)
        self:removeEffect(self.EFF_CHARGED)
        return true
    end,

    info = function(self, t)
        return ("Allows you to build an electrical charge in your right hand. Each turn you do not hit in melee, you build up charge, up to a maximum of %i points (based on your Constitution). When you successfully hit in melee, any charge is converted to lightning damage."):format(t.getMaxCharge(self, t))
    end,
}

-- My humble attempt to bring the joy of playing a Charged Bolt-spamming Diablo II
-- Sorceress to a turn-based roguelike.
newTalent {
    name = "Charged Bolt",
    type = {"qi techniques/left hand", 1},
    cooldown = 2,
    qi = 2,
    requires_target = true,
    range = 10,
    proj_speed = 2,

    base_spread = 2,
    spread_divisor = 4,

    getDamage = function(self, t) return self:talentDamage(self:getMnd(), 4) end,

    getDetails = function(self, t)
        -- Returns full details: damage per bolt, number of bolts
		-- TODO: Is double scaling on Mind too powerful at high levels?
        return t.getDamage(self, t), math.floor(self:getMnd() / 5)
    end,
    radius = function(self, t)
        local _, count, _ = t.getDetails(self, t)
        return math.round((t.base_spread + (count - 1)) / t.spread_divisor)
    end,

    target = function(self, t)
         return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), talent=t, stop_block=true}
    end,
    singleTarget = function(self, t)
         return {type="bolt", range=self:getTalentRange(t), talent=t, selffire=false, display={particle="charged_bolt"}, name="charged bolt"}
    end,

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        local dam, count = t.getDetails(self, t)
        local spread = t.base_spread

        for i = 1, count do
            local this_x, this_y = x, y
            this_x = math.round(this_x + rng.range(-spread, spread) / t.spread_divisor)
            this_y = math.round(this_y + rng.range(-spread, spread) / t.spread_divisor)
            local this_dam = rng.range(dam * 0.9, dam * 1.1)
            self:projectile(t.singleTarget(self, t), this_x, this_y, DamageType.LIGHTNING, this_dam, {type="charged_bolt_hit"})
            spread = spread + 1
        end

        return true
    end,
    info = function(self, t)
        local dam, count = t.getDetails(self, t)
        if count == 1 then
            return ("Conjures 1 bolt of charged electricity, which travels slowly and somewhat erratically to somewhere in the target area. Each bolt averages %i damage. The number of bolts conjured depends on your Mind."):format(dam)
        else
            return ("Conjures %i bolts of charged electricity, each of which travels slowly and somewhat erratically to somewhere in the target area. Each bolt averages %i damage. The number of bolts conjured depends on your Mind."):format(count, dam)
        end
    end,
}

-- Better name needed?  Absorptive Capacitor?  Energy Harvesting?  Defensive Capacitor?
newTalent {
    name = "Electrostatic Capture",
    type = {"qi techniques/chest", 1},
    mode = "passive",

    resist_lightning_bonus = 2,

    on_learn = function(self, t) self.resists[DamageType.LIGHTNING] = (self.resists[DamageType.LIGHTNING] or 0) + t.resist_lightning_bonus end,
    on_unlearn = function(self, t) self.resists[DamageType.LIGHTNING] = (self.resists[DamageType.LIGHTNING] or 0) - t.resist_lightning_bonus end,

    info = function(self, t)
        return flavorText(("Grants %i %s of lightning resistance. Additionally, whenever you take lightning damage, a portion of the damage you take is converted into an energy charge that's added as bonus lightning damage to your next successful melee attack."):format(t.resist_lightning_bonus, string.pluralize("level", t.resist_lightning_bonus)),
            "Grid bugs' control over electricity permits them to capture a portion of any lightning directed at them and store it for later use.")
    end,
}

newTalent {
    name = "Geomagnetic Orientation",
    type = {"qi techniques/feet", 1},
    mode = "sustained",
    sustain_qi = 1,
    cooldown = 5,

    -- For this to be a worthwhile choice, the movement speed bonus to compared
    -- to how often the player expects to move diagonally should make sense.
    -- Does it?
    --
    -- 0.15 equals 1 out of every 6.67 moves.
    movement_speed_bonus = 0.15,

    activate = function(self, t)
        local ret = {}
        self:talentTemporaryValue(ret, "movement_speed", t.movement_speed_bonus)
        self:talentTemporaryValue(ret, "forbid_diagonals", 1)
        return ret
    end,
    deactivate = function(self, t, p)
        return true
    end,

    info = function(self, t)
        return flavorText(("Increases your movement speed by %i%% but "..
            "prevents you from moving or attacking diagonally."):format(t.movement_speed_bonus * 100),
            "Grid bugs' alien electrical nature means that they can only move in this world by orienting themselves as a compass does. "..
            "They move in a strange zig-zag fashion, all straight lines and right angles, as a result of this.")
    end,
}

newTalent {
    name = "Electroluminescence",
    type = {"qi techniques/head", 1},
    mode = "sustained",
    sustain_qi = 6,
    cooldown = 5,

    lite = 2,

    activate = function(self, t)
        local liteid = self:addTemporaryValue("lite", t.lite)
        if self.doFOV then self:doFOV() end
        return {
            liteid = liteid
        }
    end,
    deactivate = function(self, t, p)
        self:removeTemporaryValue("lite", p.liteid)
        if self.doFOV then self:doFOV() end
        return true
    end,

    info = function(self, t)
        return ("Causes you to glow with electrical energy, adding %i to your light radius."):format(t.lite)
    end,
}

newTalent {
    name = "Fire Slash",
    type = {"qi techniques/right hand", 1},
    mode = "activated",
    cooldown = 5,
    qi = 6,
    requires_target = true,
    range = 1,

    hit_mult = 1.1,
    miss_mult = 0.4,

    action = function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        local speed, hit = self:attackTarget(target, DamageType.FIRE, nil, t.hit_mult)
        if not hit then
            DamageType:get(DamageType.FIRE).projector(self, x, y, DamageType.FIRE,
                self:combatDamage(self:getInvenCombat(self.INVEN_RHAND, true) or self.combat) * t.miss_mult,
                { msg = function(self, target, dam, dam_type) return ("The flames of the near miss scorch %s for %s%i %s damage#LAST#."):format(target:getTargetName(), dam_type.text_color, dam, dam_type.name) end })
        end
        game.level.map:particleEmitter(self.x, self.y, 1, "fire_slash", {tx=x-self.x, ty=y-self.y})
        return true
    end,

    info = function(self, t)
        return ("Turns your weapon (or body part) into solid flame and attacks, dealing %i%% of weapon damage as fire damage. Even if the attack misses, the intense heat will deal %i%% of weapon damage as fire damage."):format(t.hit_mult * 100, t.miss_mult * 100)
    end,
}

newTalent {
    name = "Burning Hand",
    type = {"qi techniques/left hand", 1},
    mode = "activated",
    cooldown = 6,
    qi = 6,
    requires_target = true,
    range = 1,
    radius = 1,
    target = function(self, t) return {type="cone", range=self:getTalentRange(t), radius=self:getTalentRadius(t), selffire=true, talent=t} end,
    getDamage = function(self, t) return self:talentDamage(self:getMnd(), 6) end,
    self_damage = 0.25,

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end

        if x == self.x and y == self.y then
            self:project(tg, x, y, DamageType.FIRE, t.getDamage(self, t) * t.self_damage)
            game.level.map:particleEmitter(self.x, self.y, tg.radius, "burn_self")
            -- TODO: Cauterize wounds?  Update description for targeting self.
        else
            self:project(tg, x, y, DamageType.FIRE_REF_HALF, t.getDamage(self, t))
            game.level.map:particleEmitter(self.x, self.y, tg.radius, "burning_hand", {radius=self:getTalentRadius(t), tx=x-self.x, ty=y-self.y})
        end

        return true
    end,

    info = function(self, t)
        return ("Emits a short-range cone of fire doing %i damage (based on your Mind). It does 50%% damage if the opponent succeeds on a Reflex save against your Skill and %i%% damage if it's aimed at yourself."):format(t.getDamage(self, t), t.self_damage * 100)
    end,
}

newTalent {
    name = "Heat Carapace",
    type = {"qi techniques/chest", 1},
    mode = "passive",

    resist_fire_bonus = 2,
    getArmorBonus = function(self, t)
        return math.floor(self:getCon() / 5)
    end,
    getDuration = function(self, t)
        return math.floor(self:getCon() / 2)
    end,

    on_learn = function(self, t) self.resists[DamageType.FIRE] = (self.resists[DamageType.FIRE] or 0) + t.resist_fire_bonus end,
    on_unlearn = function(self, t) self.resists[DamageType.FIRE] = (self.resists[DamageType.FIRE] or 0) - t.resist_fire_bonus end,

    info = function(self, t)
        return flavorText(("Grants %i %s of fire resistance. Additionally, whenever you take fire damage, the heat hardens your skin, adding %i your natural armor for %i turns (both based on your Constitution)."):format(t.resist_fire_bonus, string.pluralize("level", t.resist_fire_bonus), t.getArmorBonus(self, t), t.getDuration(self, t)),
            "Fire ants' outer shells are tempered and hardened by the flames that continually burn within.")
    end,
}

newTalent {
    name = "Burden of the Ant",
    short_name = "ANT_BURDEN",
    type = {"qi techniques/feet", 1},
    mode = "passive",

    max_encumber_bonus = 20,

    on_learn = function(self, t)
        self.max_encumber = (self.max_encumber or 0) + t.max_encumber_bonus
        self:checkEncumbrance()
    end,
    on_unlearn = function(self, t)
        self.max_encumber = self.max_encumber - t.max_encumber_bonus
        self:checkEncumbrance()
    end,

    info = function(self, t)
        return flavorText(("Adds %i to your carrying capacity."):format(t.max_encumber_bonus))
    end,
}

newTalent {
    name = "Hive Mind",
    type = {"qi techniques/head", 1},
    cooldown = 20,
    qi = 8,
    range = 5,
    requires_target = true,
    no_npc_use = true,
    target = function(self, t) return {type="hit", range=self:getTalentRange(t) } end,

    -- Picking up a permanent ally should be hard, especially since insects
    -- tend to have low Will saves (which would otherwise make this easy).
    check_modifier = -5,

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        if target.type ~= "insect" then
            game.logPlayer(self, "This technique only works on insects.")
            return false
        end

        if not self:skillCheck(self:talentPower(self:getMnd()) + t.check_modifier, target:willSave()) then
            game.logSeen(target, ("%s resists the mental assault."):format(target.name:capitalize()))
            return true, { ignore_cd = true }
        end

        -- Gain experience for defeating the monster.
        self:gainExp(target:worthExp(self))
        target.exp_worth = 0

        -- FIXME: More robust version: make allies follow you to other levels, but limit the number you can have.  Adjust cost, cooldown, failure rate once that's done?
        -- TODO: Pull into proper party member code.  Add provision for angering allies?

        game.logSeen(target, ("%s's mind is dominated!"):format(target.name:capitalize()))

        target.faction = self.faction
        target.move_others = true
        target.summoner = self
        target.summoner_gain_exp = true

        target.ai_state.ai_party = target.ai
        target.ai = "party_member"

        return true
    end,

    info = function(self, t)
        return flavorText("Attempts to dominate an insect's mind, causing it to view you as its hive queen and turning it into your ally until you leave the current level. The chance of success is based on your Mind compared to the insect's Will save.\n\nThis technique only incurs a cooldown if it succeeds.")
    end,
}

