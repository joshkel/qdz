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

newTalent{
    name = "Mining",
    type = {"basic/proficiencies", 1},
    points = 5,
    no_npc_use = true,
    no_energy = true, -- energy cost is handled by wait() below

    -- Strength or constitution?  Mining is granted by chest techniques, and
    -- it seems reasonable to say that a guy who can work all day without
    -- taking a break would be more desirable than a bodybuilder with less
    -- stamina...
    stat = "con",

    findBest = function(self, t)
        local best = nil
        local find = function(inven)
            for item, o in ipairs(inven) do
                if o.digspeed and (not best or o.digspeed < best.digspeed) then best = o end
            end
        end
        for inven_id, inven in pairs(self.inven) do find(inven) end
        return best
    end,
    no_proficiency_penalty = 2,

    -- NOTE: Dig speed logic is partially duplicated in diggers.lua
    getEffectiveDigSpeed = function(self, t, obj, show_message)
        local mining = self:getTalentLevel(t.id)

        local digspeed
        if not obj then
            if show_message then game.logPlayer(self, "Without proper tools, this could take a while...") end
            digspeed = 20
        else
            digspeed = obj.digspeed
        end

        if mining == 0 then
            if show_message then game.logPlayer(self, "You don't know the first thing about mining. This could take a while...") end
            return math.floor(digspeed * t.no_proficiency_penalty)
        else
            return math.floor(digspeed * math.pow(0.9, mining - 1))
        end
    end,

    action = function(self, t)
        local digger = self._force_digger or t.findBest(self, t)

        -- Based on ToME's DIG_OBJECT
        local tg = {type="bolt", range=1, nolock=true}
        local x, y = self:getTarget(tg)
        if not x or not y then return nil end
        local feat = game.level.map(x, y, Map.TERRAIN)
        if not feat.dig then
            game.logPlayer(self, ("The %s is not diggable."):format(feat.name))
            return nil
        end

        -- Hack: Subtracting 1 is necessary to make turns taken match.
        -- I'm not sure why.
        local digspeed = t.getEffectiveDigSpeed(self, t, digger, true) - 1

        local wait = function()
            local co = coroutine.running()
            local ok = false
            self:restInit(digspeed, "digging", "dug", function(cnt, max)
                if cnt > max then ok = true end
                coroutine.resume(co)
            end)
            coroutine.yield()
            if not ok then
                game.logPlayer(self, "You have been interrupted!")
                return false
            end
            return true
        end
        if wait() then
            self:project(tg, x, y, engine.DamageType.DIG, 1)
        end

        return true
    end,
    info = function(self, t)
        local digger = t.findBest(self, t)
        local result = "Mining lets you use a pickaxe or similar tool to dig stone and earth.\n\n"
        if digger then
            result = result .. ("Digging with your %s takes %d turns (based on your effective Mining proficiency and best mining tool available)."):format(digger.name, t.getEffectiveDigSpeed(self, t, digger))
        else
            result = result .. ("Digging without proper tools takes %d turns (based on your effective Mining proficiency)."):format(t.getEffectiveDigSpeed(self, t, digger))
        end
        return result
    end,
}

newTalent{
    name = "Pickpocket",
    type = {"basic/proficiencies", 1},
    points = 5,
    cooldown = 6,
    no_npc_use = true,  -- TODO: Actually, pickpocket NPCs would be cool, but implementation would have to change.
    range = 1,
    stat = "ski",

    chanceOfSuccess = function(self, t)
        return self:talentPercentage(t, 20)
    end,

    action = meleeTalent(function(self, t, target)
        if target.type ~= "humanoid" then
            game.logPlayer(self, ("%s has no pockets."):format(target.name:capitalize()))
            return false
        end

        -- Sample opposed skill check.  This would need to be standardized,
        -- and I'm not sure how to keep proficiency level relevant without
        -- it being a treadmill.
        --local success = self:skillCheck(self.level / 2 + self:getSki() / 2 + self:getTalentLevel(t), target.level / 2 + target:getMnd() / 2)

        -- Flat percentage check
        local success = target:attr("combat_def_zero") or rng.percent(t.chanceOfSuccess(self, t))

        if not success then
            game.logSeen(self, ("%s tries to pick %s's pockets but fails."):format(
                self.name:capitalize(), target.name))
        elseif target.pickpocketed then
            game.logSeen(self, ("%s tries to pick %s's pockets, but %s has already been robbed."):format(
                self.name:capitalize(), target.name, target.name, target.name))
        else
            local o = game.zone:makeEntity(game.level, "object", {special=function(e) return e.encumber <= 1 and not e.unique end}, nil, true)
            if o then
                if o.type == "money" then
                    local money_value = o:getMoneyValue(self)
                    self:incMoney(money_value)
                    game.logSeen(self, ("%s picks %s's pockets and steals %i gold pieces."):format(
                        self.name:capitalize(), target.name, math.floor(money_value)))
                else
                    self:addObject(self.INVEN_INVEN, o)
                    game.logSeen(self, ("%s picks %s's pockets and steals %s."):format(
                        self.name:capitalize(), target.name, o.name:a()))
                end
            else
                game.logSeen(self, ("%s picks %s's pockets but finds nothing of value."):format(
                    self.name:capitalize(), target.name))
            end
            target.pickpocketed = true
        end

        return true
    end),

    info = function(self, t)
        return ("Attempts to steal a small item from a nearby enemy. Only humanoid enemies can be robbed. The chance of success is %i%% (based on your effective Pickpocket proficiency)."):format(t.chanceOfSuccess(self, t))
    end,
}

