-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- ToME - Tales of Maj'Eyal
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

require "engine.class"
require "mod.class.ui.SimpleListDialog"
local Talents = require "engine.interface.ActorTalents"

module(..., package.seeall, class.inherit(mod.class.ui.SimpleListDialog))

---Displays a list of techniques and allows the player to learn one.
--
-- If qi_only is true (the normal case), then learn a new qi technique.
-- This currently ignores the per-level limit on number of techniques known.
--
-- If qi_only is false, then learn a non-qi talent.  This is normally illegal
-- but is useful for testing.
function _M:init(qi_only)
    self.qi_only = qi_only
    mod.class.ui.SimpleListDialog.init(self, qi_only and "Debug Menu - Learn Technique" or "Debug Menu - Test Talent")
end

function _M:useItem(item)
    local player = game.player
    local id = item.id
    
    if player:knowTalent(id) then
        game.log("You already know this technique.")
    else
        local t = Talents:getTalentFromId(id)
        game.log(("You learn %s."):format(t.name))
        player:learnTalent(id, true)
    end
end

function _M:selectItem(item, sel)
    local t = Talents:getTalentFromId(item.id)
    game:tooltipDisplayAtMap(game.w, game.h, game.player:getTalentFullDescription(t), nil, true)
end

function _M:generateListContents()
    local list = {}

    for id, t in pairs(Talents.talents_def) do
        local is_qi = t.type[1]:startsWith("qi techniques/") or t.type[1]:startsWith("infernal qi/")
        if is_qi == self.qi_only then
            list[#list+1] = {name=t.name, id=id}
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)

    return list
end

