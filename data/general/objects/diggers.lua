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


newEntity{
    define_as = "BASE_DIGGER",
    slot = "RHAND",
    type = "tool", subtype="digger",
    display = "\\", color=colors.SLATE,
    encumber = 8,
    rarity = 5,
    combat = { sound = "actions/melee", sound_miss = "actions/melee_miss", },
    name = "a generic digging implement",
    desc = [[A digging implement.]],
    
    digspeed = 5,
    use_no_wear = true,
    use_no_energy = true, -- energy cost is handled by wait() below

    getEffectiveDigSpeed = function(self, who, show_message)
        local Talents = require "engine.interface.ActorTalents"
        local mining = who:getTalentLevel(Talents.T_MINING)
        if mining == 0 then
            if show_message then game.logPlayer(who, "You don't know the first thing about mining. This could take a while...") end
            return math.floor(self.digspeed * 2)
        else
            return math.floor(self.digspeed * math.pow(0.9, mining - 1))
        end
    end,

    -- Based on ToME's DIG_OBJECT
    use_simple = {
        name = "dig",
        use = function(self, who)
            local Map = require "engine.Map"
            local tg = {type="bolt", range=1, nolock=true}
            local x, y = who:getTarget(tg)
            if not x or not y then return nil end
            local feat = game.level.map(x, y, Map.TERRAIN)
            if not feat.dig then
                game.logPlayer(who, ("The %s is not diggable."):format(feat.name))
                return nil
            end

            local digspeed = self:getEffectiveDigSpeed(who, true)

            local wait = function()
                local co = coroutine.running()
                local ok = false
                who:restInit(digspeed, "digging", "dug", function(cnt, max)
                    if cnt > max then ok = true end
                    coroutine.resume(co)
                end)
                coroutine.yield()
                if not ok then
                    game.logPlayer(who, "You have been interrupted!")
                    return false
                end
                return true
            end
            if wait() then
                who:project(tg, x, y, engine.DamageType.DIG, 1)
            end

            return true
        end,
    }
}

newEntity{ base = "BASE_DIGGER",
    name = "iron pickaxe",
    level_range = {1, 10},
    cost = 5,
    combat = {
        dam = 5,
    },
    desc = [[A pickaxe. Although designed for mining, it can be used as a weapon in a pinch.]]
}

