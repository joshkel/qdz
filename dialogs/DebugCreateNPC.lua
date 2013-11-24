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
local Map = require("engine.Map")
local NPC = require("mod.class.NPC")

module(..., package.seeall, class.inherit(mod.class.ui.SimpleListDialog))

function _M:init()
    mod.class.ui.SimpleListDialog.init(self, "Debug Menu - Create NPC")
end

function _M:useItem(item)
    local x, y = util.findFreeGrid(game.player.x, game.player.y, 5, true, {[Map.ACTOR]=true})
    if not x then
        game.logPlayer(self, "Not enough space to summon!")
        return
    end

    local m = NPC.new(item.npc)
    -- The following logic is based on ToME's data/talents/gifts/gifts.lua's setupSummons.
    m:resolve()
    m:resolve(nil, true)
    game.zone:addEntity(game.level, m, "actor", x, y)
end

function _M:generateListContents()
    local list = {}

    local npc_list = NPC:loadList('/data/general/npcs/all.lua')
    table.sort(npc_list, function(a, b) return a.name < b.name end)

    for i, v in ipairs(npc_list) do
        -- Assume that define_as indicates a base NPC, not to be instantiated
        -- itself.  (We could also check rarity to be closer to how T-Engine
        -- works for randomly generated NPCs, I think.)
        if v.name and not v.define_as then
            list[#list+1] = {name=v.name, npc=v}
        end
    end

    return list
end
