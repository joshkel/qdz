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

newAI("party_member", function(self)
    -- Unselect friendly targets
    if self.ai_target.actor and self:reactionToward(self.ai_target.actor) >= 0 then self:setTarget(nil) end

    -- Run normal AI
    local ret = self:runAI(self.ai_state.ai_party)

    if not ret and not self.energy.used then
        return self:runAI("move_player")
    else
        return ret
    end
end)

newAI("move_player", function(self)
    local a = engine.Astar.new(game.level.map, self)
    local path = a:calc(self.x, self.y, game.player.x, game.player.y)
    if not path then
        return self:moveDirection(game.player.x, game.player.y)
    else
        local moved = self:move(path[1].x, path[1].y)
        if not moved then return self:moveDirection(game.player.x, game.player.y) end
    end
end)

