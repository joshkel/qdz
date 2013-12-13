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
    name = "Mining",
    type = {"basic/proficiencies", 1},
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
    points = 5,
    no_npc_use = true,
    no_energy = true, -- energy cost is handled by diggers.lua's wait()
    action = function(self, t)
        local best = t.findBest(self, t)
        if not best then game.logPlayer(self, "You require a mining tool to dig.") return end
        return best:useObject(self)
    end,
    info = function(self, t)
        -- TODO: Permit Mining to work without a digger?
        -- I'm not positive it will be worth a talent slot otherwise.
        local best = t.findBest(self, t)
        local result = "Mining lets you use a pickaxe or similar tool to dig stone and earth.\n\n"
        if best then
            result = result .. ("Digging with your %s takes %d turns (based on your Mining proficiency, Constitution, and best mining tool available)."):format(best.name, best:getEffectiveDigSpeed(self))
        else
            result = result .. "You currently have no mining tools."
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

    chanceOfSuccess = function(self, t)
        return self:talentPercentage(t, 20, self:getSki())
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
        return ("Attempts to steal a small item from a nearby enemy. Only humanoid enemies can be robbed. The chance of success is %i%% (based on your Pickpocket proficiency and Skill)."):format(t.chanceOfSuccess(self, t))
    end,
}

