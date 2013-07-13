-- Qi Dao Zei
-- Copyright (C) 2013 Castler
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

require "engine.class"

local Dialog = require "mod.class.ui.Dialog"
local Talents = require "engine.interface.ActorTalents"
local Tab = require "engine.ui.Tab"
local SurfaceZone = require "engine.ui.SurfaceZone"
local Separator = require "engine.ui.Separator"
local Stats = require "engine.interface.ActorStats"
local Textzone = require "engine.ui.Textzone"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
    self.actor = actor
    Dialog.init(self, "Character Sheet: "..self.actor.name, math.max(game.w * 0.7, 950), 500)

    self.font = core.display.newFont("/data/font/VeraMono.ttf", 12)
    self.font_h = self.font:lineSkip()

    self.c_general = Tab.new{title="General", default=true, fct=function() end, on_change=function(s) if s then self:switchTo("general") end end}
    self.c_attack = Tab.new{title="Attack", default=false, fct=function() end, on_change=function(s) if s then self:switchTo("attack") end end}
    self.c_defense = Tab.new{title="Defense", default=false, fct=function() end, on_change=function(s) if s then self:switchTo("defense") end end}

    local tw, th = self.font_bold:size(self.title)

    self.vs = Separator.new{dir="vertical", size=self.iw}

    self.c_tut = Textzone.new{width=self.iw * 0.6, auto_height=true, no_color_bleed=true, font = self.font, text=[[
Keyboard: #00FF00#'d'#LAST# to save character dump. #00FF00#TAB key#LAST# to switch between tabs.
Mouse: Hover over stat for info
]]}

    self.c_desc = SurfaceZone.new{width=self.iw, height=self.ih - self.c_general.h - self.vs.h - self.c_tut.h,alpha=0}

    -- The wiki and ToME itself add 17 instead of 5 here...  I'm not sure why...
    local extra_offset = 5
    self.hoffset = extra_offset + self.c_tut.h + self.vs.h + self.c_general.h

    self:loadUI{
        {left=0, top=0, ui=self.c_tut},
        {left=15, top=self.c_tut.h, ui=self.c_general},
        {left=15+self.c_general.w, top=self.c_tut.h, ui=self.c_attack},
        {left=15+self.c_general.w+self.c_attack.w, top=self.c_tut.h, ui=self.c_defense},
        {left=0, top=self.c_tut.h + self.c_general.h, ui=self.vs},

        {left=0, top=self.c_tut.h + self.c_general.h + extra_offset + self.vs.h, ui=self.c_desc},
    }
    self:setFocus(self.c_general)
    self:setupUI()

    self:switchTo("general")

    self:updateKeys()
end

function _M:switchTo(kind)
    self:drawDialog(kind, cs_player_dup)
    if kind == "general" then self.c_attack.selected = false self.c_defense.selected = false
    elseif kind == "attack" then self.c_general.selected = false self.c_defense.selected = false
    elseif kind == "defense" then self.c_attack.selected = false self.c_general.selected = false
    end
    self:updateKeys()
end

function _M:updateKeys()
    self.key:addCommands{
    _TAB = function() self:tabTabs() end,
    __TEXTINPUT = function(c)
        if c == 'd' or c == 'D' then
            self:dump()
        end
    end,
    }

    self.key:addBinds{
        EXIT = function() cs_player_dup = game.player:clone() game:unregisterDialog(self) end,
    }
end

function _M:tabTabs()
    if self.c_general.selected == true then self.c_attack:select() elseif
    self.c_attack.selected == true then self.c_defense:select() elseif
    self.c_defense.selected == true then self.c_general:select() end
end

function _M:mouseZones(t, no_new)
    -- Offset the x and y with the window position and window title
    if not t.norestrict then
        for i, z in ipairs(t) do
            if not z.norestrict then
                z.x = z.x + self.display_x + 5
                z.y = z.y + self.display_y + 20 + 3
            end
        end
    end

    if not no_new then self.mouse = engine.Mouse.new() end
    self.mouse:registerZones(t)
end

function _M:drawDialog(kind)
    self.mouse:reset()

    self:setupUI()

    local player = self.actor
    local s = self.c_desc.s

    s:erase(0,0,0,0)

    local h = 0
    local w = 0

    if kind == "general" then
        h = 0
        w = 0
        s:drawStringBlended(self.font, "Name : "..(player.name or "Unnamed"), w, h, 255, 255, 255, true) h = h + self.font_h

        h = h + self.font_h -- Adds an empty row
        
        -- Draw some text with an attatched tooltip
        self:drawString(s, ("#c00000#Life : #00ff00#%d/%d"):format(player.life, player.max_life), w, h,
            "#GOLD#Life#LAST#\nYour health. When this reaches 0, you die.") h = h + self.font_h
        self:drawString(s, ("#ffcc80#Power: #00ff00#%d/%d"):format(player:getPower(), player.max_power), w, h,
            "#GOLD#Power#LAST#\nYour available qi energy. Many qi abilities require this.") h = h + self.font_h
        
        h = 0
        w = self.w * 0.25 
        -- start on second column
        
        function statTooltip(short_name)
            return ("#GOLD#%s#LAST#\n%s"):format(player.stats_def[short_name].name, player.stats_def[short_name].description)
        end
        self:drawString(s, "Strength     : #00ff00# "..player:getStr(), w, h, statTooltip('str')) h = h + self.font_h
        self:drawString(s, "Skill        : #00ff00# "..player:getSki(), w, h, statTooltip('ski')) h = h + self.font_h
        self:drawString(s, "Constitution : #00ff00# "..player:getCon(), w, h, statTooltip('con')) h = h + self.font_h
        self:drawString(s, "Agility      : #00ff00# "..player:getAgi(), w, h, statTooltip('agi')) h = h + self.font_h
        self:drawString(s, "Mind         : #00ff00# "..player:getMnd(), w, h, statTooltip('mnd')) h = h + self.font_h
        
    elseif kind=="attack" then
        h = 0
        w = 0
        
        -- draw the attack tab here

    elseif kind=="defense" then
        h = 0
        w = 0
        
        -- draw the defense tab here

    end

    self.c_desc:generate()
    self.changed = false
end

function _M:dump()
    local player = self.actor

    fs.mkdir("/character-dumps")
    local file = "/character-dumps/"..(player.name:gsub("[^a-zA-Z0-9_-.]", "_")).."-"..os.date("%Y%m%d-%H%M%S")..".txt"
    local fff = fs.open(file, "w")
    local labelwidth = 17
    local w1 = function(s) s = s or "" fff:write(s:removeColorCodes()) fff:write("\n") end
    --prepare label and value
    local makelabel = function(s,r) while s:len() < labelwidth do s = s.." " end return ("%s: %s"):format(s, r) end

    w1("  [Qi Dao Zei Character Dump]")
    w1()
    
    w1(("%-32s"):format(makelabel("Name", player.name)))
    
    w1(("STR:  %d"):format(player:getStr()))
    w1(("SKI:  %d"):format(player:getSki()))
    w1(("CON:  %d"):format(player:getCon()))
    w1(("AGI:  %d"):format(player:getAgi()))
    w1(("MND:  %d"):format(player:getMnd()))

    fff:close()

    Dialog:simplePopup("Character dump complete", "File: "..fs.getRealPath(file))
end 

