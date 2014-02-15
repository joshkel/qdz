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


require "engine.class"
local DebugConsole = require "engine.DebugConsole"
local Key = require "engine.Key"
local inspect = require "mod.thirdparty.inspect.inspect"

module(..., package.seeall, class.inherit(DebugConsole))

table.insert(DebugConsole.history, 8, [[<                                                                                             >]])
table.insert(DebugConsole.history, 9, [[< Use == for Enrique Garcia's expanded table output. Example: ==game.player.combat            >]])

function _M:init()
    DebugConsole.init(self)

    local return_fct = self.key.commands[Key._RETURN].plain
    self.key:addCommand(Key._RETURN, function()
        -- Add inspect feature, based on Marson's Developer Tools
        -- See http://te4.org/games/addons/tome/marson-dev
        if DebugConsole.line:match("^==") then
            table.insert(DebugConsole.commands, DebugConsole.line)
            DebugConsole.com_sel = #DebugConsole.commands + 1
            table.insert(DebugConsole.history, DebugConsole.line)

            DebugConsole.line = "return "..DebugConsole.line:sub(3)
            local f, err = loadstring(DebugConsole.line)
            if err then
                table.insert(DebugConsole.history, err)
            else
                local _, res = pcall(function() return inspect(f()) end)
                for str in (tostring(res).."\n"):gmatch("(.-)\n") do
                    table.insert(DebugConsole.history, tostring(str))
                end
            end

            DebugConsole.line = ""
            DebugConsole.line_pos = 0
            DebugConsole.offset = 0
            self.changed = true
            return
        end

        return_fct()
    end)
end

