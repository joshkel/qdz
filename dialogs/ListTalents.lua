-- Qi Daozei
-- Copyright (C) 2013 Josh Kelley
--
-- based on
-- TE4 - T-Engine 4
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
local Dialog = require "engine.ui.Dialog"
local ListColumns = require "engine.ui.ListColumns"
local Textzone = require "engine.ui.Textzone"
local TextzoneList = require "engine.ui.TextzoneList"
local Separator = require "engine.ui.Separator"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(Dialog))

--- Generic list-talents dialog.  Does very little by itself, but provides
--- methods that talent-related subclasses can use.
function _M:init(actor, title, w, h)
    self.actor = actor
    Dialog.init(self, title, w, h)
end

function _M:on_register()
    game:onTickEnd(function() self.key:unicodeInput(true) end)
end

--- Sets self.list and self.sel based on the talents that the charater knows.
function _M:generateList(qi_only, allow_passive, name_formatter)
    -- Makes up the list
    local list = {}
    list.chars = {}
    local letter = 1
    for i, tt in ipairs(self.actor.talents_types_def) do
        if not qi_only or tt.type:startsWith("qi techniques/") then
            local cat = tt.type:gsub("/.*", "")
            local where = #list
            local added = false

            -- Find all talents of this type
            for j, t in ipairs(tt.talents) do
                if self.actor:knowTalent(t.id) then
                    local status = tstring{{"color", "LIGHT_GREEN"}, "Active"}
                    if self.actor:isTalentCoolingDown(t) then
                        status = tstring{{"color", "LIGHT_RED"}, self.actor:isTalentCoolingDown(t).." turns"}
                    elseif t.mode == "sustained" then
                        status = self.actor:isTalentActive(t.id) and tstring{{"color", "YELLOW"}, "Sustaining"} or tstring{{"color", "LIGHT_GREEN"}, "Sustain"}
                    elseif t.mode == "passive" then
                        status = tstring{{"color", "GREY"}, "Passive"}
                    end

                    local t_name = name_formatter and name_formatter(t) or t.name

                    if t.mode == "passive" and not allow_passive then
                        list[#list+1] = { char="", name=t_name, status=status, desc=self.actor:getTalentFullDescription(t) }
                    else
                        list[#list+1] = { char=self:makeKeyChar(letter), name=t_name, status=status, talent=t.id, desc=self.actor:getTalentFullDescription(t) }
                        list.chars[self:makeKeyChar(letter)] = list[#list]
                        if not self.sel then self.sel = #list + 1 end
                        letter = letter + 1
                    end

                    added = true
                end
            end

            if added then
                table.insert(list, where+1, { char="", name=tstring{{"font","bold"}, cat:capitalize().." / "..tt.name:capitalize(), {"font","normal"}}, type=tt.type, color={0x80, 0x80, 0x80}, status="", desc=tt.description })
                if where ~= 0 then 
                    -- If this isn't the first category we've added, insert a blank
                    -- line between categories.
                    table.insert(list, where+1, { char="", name=tstring{}, type=tt.type, color={0x80, 0x80, 0x80}, status="" })
                end
            end
        end
    end
    for i = 1, #list do list[i].id = i end
    self.list = list
end
