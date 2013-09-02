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

newTalent {
    name = "Capacitive Appendage",
    type = {"qi techniques/right hand", 1},
    points = 1,
    mode = "sustained",
    sustain_qi = 5,
    cooldown = 5,

    per_turn = 0.5,
    getMaxCharge = function(self, t)
        return self:talentDamage(self:getCon(), 1)
    end,

    do_turn = function(self, t)
        local eff = self:hasEffect(self.EFF_CHARGED)
        if not eff then
            self:setEffect(self.EFF_CHARGED, 1, { power=0 })
        else
            self.tempeffect_def[self.EFF_CHARGED].add_power(self, eff, t.per_turn, t.getMaxCharge(self, t))
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
        return ("Allows you to build an electrical charge in your right hand. Each turn you do not hit in melee, you build half a point of charge, up to a maximum of %i points (based on your Constitution). When you successfully hit in melee, any charge is converted to lightning damage."):format(t.getMaxCharge(self, t))
    end,
}

-- My humble attempt to bring the joy of playing a Charged Bolt-spamming Diablo II
-- Sorceress to a turn-based roguelike.
newTalent {
    name = "Charged Bolt",
    type = {"qi techniques/left hand", 1},
    points = 1,
    cooldown = 2,
    qi = 2,
    range = 10,
    proj_speed = 2,

    damage_per_bolt = 4,
    base_spread = 3,
    spread_divisor = 4,

    getTotalDamage = function(self, t) return self:talentDamage(self:getMnd(), 1) end,

    getDetails = function(self, t)
        -- Returns full details: damage per bolt, number of bolts, damage for last bolt
        local dam = t.getTotalDamage(self, t)
        if dam % t.damage_per_bolt == 0 then
            return t.damage_per_bolt, dam / t.damage_per_bolt, t.damage_per_bolt
        else
            return t.damage_per_bolt, math.ceil(dam / t.damage_per_bolt), dam % t.damage_per_bolt
        end
    end,
    radius = function(self, t)
        local _, count, _ = t.getDetails(self, t)
        return math.round((t.base_spread + (count - 1)) / t.spread_divisor)
    end,

    target = function(self, t)
         return {type="ball", range=self:getTalentRange(t), radius=self:getTalentRadius(t), talent=t, stop_block=true}
    end,
    singleTarget = function(self, t)
         return {type="bolt", range=self:getTalentRange(t), talent=t, selffire=false, display={particle="charged_bolt"}}
    end,

    action = function(self, t)
        local tg = self:getTalentTarget(t)
        local x, y, target = self:getTarget(tg)
        if not x or not y then return nil end

        local dam, count, last_dam = t.getDetails(self, t)
        local spread = t.base_spread

        for i = 1, count do
            local this_x, this_y = x, y
            this_x = math.round(this_x + rng.range(-spread, spread) / t.spread_divisor)
            this_y = math.round(this_y + rng.range(-spread, spread) / t.spread_divisor)
            local this_dam = i == count and last_dam or dam
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

newTalent {
    name = "Geomagnetic Orientation",
    type = {"qi techniques/feet", 1},
    points = 1,
    mode = "sustained",
    sustain_qi = 1,
    cooldown = 5,

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
    points = 1,
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

