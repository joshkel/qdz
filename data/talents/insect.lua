-- Qi Dao Zei
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
    type = {"qi abilities/right hand", 1},
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
        return true
    end,

    info = function(self, t)
        return ("Allows you to build an electrical charge in your right hand. Each turn you do not hit in melee, you build half a point of charge, up to a maximum of %i points (based on your Constitution). When you successfully hit in melee, any charge is converted to lightning damage."):format(t.getMaxCharge(self, t))
    end,
}

