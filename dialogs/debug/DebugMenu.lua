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

module(..., package.seeall, class.inherit(mod.class.ui.SimpleListDialog))

function _M:init()
    mod.class.ui.SimpleListDialog.init(self, "Debug Menu")
end

function _M:useItem(item)
    local act = item.action

    if act == "reset_cooldowns" then game.player:resetTalentCooldowns() end
    if act == "full_heal" then game.player:resetToFull() game.player.changed = true end
    if act == "learn_technique" then game:registerDialog(require("mod.dialogs.debug.LearnTechnique").new(true)) end
    if act == "create_item" then game:registerDialog(require("mod.dialogs.debug.CreateItem").new()) end
    if act == "create_npc" then game:registerDialog(require("mod.dialogs.debug.CreateNPC").new()) end
    if act == "reload_ui" then self:reloadUI() end
    if act == "test_talent" then game:registerDialog(require("mod.dialogs.debug.LearnTechnique").new(false)) end
end

--- Reload what we can of the UI, to test changes without reloading the whole
--- game.
---
--- For now, this reloads custom dialogs (only).  That should be safe.
function _M:reloadUI()
    for k, v in pairs(package.loaded) do
        if k:startsWith("mod.dialogs.") then
            print(("reloading %s"):format(k))
            package.loaded[k] = nil
        end
    end
end

function _M:generateListContents()
    local list = {}

    list[#list+1] = {name="Reset Cooldowns", action="reset_cooldowns"}
    list[#list+1] = {name="Full Heal", action="full_heal"}
    list[#list+1] = {name="Learn Qi Technique", action="learn_technique"}
    list[#list+1] = {name="Create Item", action="create_item"}
    list[#list+1] = {name="Create NPC", action="create_npc"}
    list[#list+1] = {name="Reload UI", action="reload_ui"}
    list[#list+1] = {name="Test Talent", action="test_talent"}

    return list
end

