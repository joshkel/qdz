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
    if act == "learn_technique" then game:registerDialog(require("mod.dialogs.DebugLearnTechnique").new()) end
    if act == "create_item" then game:registerDialog(require("mod.dialogs.DebugCreateItem").new()) end
end

function _M:generateListContents()
    local list = {}

    list[#list+1] = {name="Reset Cooldowns", action="reset_cooldowns"}
    list[#list+1] = {name="Full Heal", action="full_heal"}
    list[#list+1] = {name="Learn Qi Technique", action="learn_technique"}
    list[#list+1] = {name="Create Item", action="create_item"}

    return list
end
