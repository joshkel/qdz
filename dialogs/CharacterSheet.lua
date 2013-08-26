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
--
-- Nicolas Casalini "DarkGod"
-- darkgod@te4.org

require "engine.class"

local Dialog = require "mod.class.ui.Dialog"
local Talents = require "engine.interface.ActorTalents"
local Tab = require "engine.ui.Tab"
local SurfaceZone = require "engine.ui.SurfaceZone"
local Separator = require "engine.ui.Separator"
local Stats = require "mod.class.interface.ActorStats"
local Textzone = require "engine.ui.Textzone"
local GameUI = require "mod.class.ui.GameUI"

module(..., package.seeall, class.inherit(Dialog))

function _M:init(actor)
    self.actor = actor
    Dialog.init(self, "Character Sheet: "..self.actor.name, math.max(game.w * 0.7, 950), 500)

    self.font = core.display.newFont(GameUI.mono_font_name, GameUI.font_size)
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

    local extra_offset = 5
    local tab_padding = 2
    -- The wiki and ToME itself add 17 instead of 5 here...  I'm not sure why...
    self.hoffset = extra_offset + self.c_tut.h + self.vs.h + self.c_general.h

    self:loadUI{
        {left=0, top=0, ui=self.c_tut},
        {left=15, top=self.c_tut.h, ui=self.c_general},
        {left=15+self.c_general.w+tab_padding, top=self.c_tut.h, ui=self.c_attack},
        {left=15+self.c_general.w+self.c_attack.w+tab_padding*2, top=self.c_tut.h, ui=self.c_defense},
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

function _M:on_register()
    game:onTickEnd(function() self.key:unicodeInput(true) end)
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
    local color = GameUI.tooltipColor

    self.mouse:reset()

    self:setupUI()

    local player = self.actor
    local s = self.c_desc.s

    s:erase(0,0,0,0)

    local h = 0
    local w = 0

    if kind == "general" then
        -- First column: Primary stats
        h = 0
        w = 0
        local name = player.name or "Unnamed"
        if player ~= game.player then name = name:capitalize() end
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#"..name.."#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h

        h = h + self.font_h

        -- TODO: Replace tooltips with what load.lua defines
        self:drawString(s, ("#LIGHT_RED#Life : #00ff00#%d/%d"):format(player.life, player.max_life), w, h,
            GameUI:tooltipTitle('Life'):merge{true, "Your health. When this reaches 0, you die."}) h = h + self.font_h
        self:drawString(s, ("#LIGHT_BLUE#Qi   : #00ff00#%d/%d"):format(player:getQi(), player.max_qi), w, h,
            GameUI:tooltipTitle('Qi'):merge{true, player.resources_def[player.RS_QI].description}) h = h + self.font_h

        h = h + self.font_h

        function statTooltip(short_name)
            return GameUI:tooltipTitle(player.stats_def[short_name].name):merge{true, player.stats_def[short_name].description}
        end
        self:drawString(s, "Strength     : #00ff00# "..player:getStr(), w, h, statTooltip('str')) h = h + self.font_h
        self:drawString(s, "Skill        : #00ff00# "..player:getSki(), w, h, statTooltip('ski')) h = h + self.font_h
        self:drawString(s, "Constitution : #00ff00# "..player:getCon(), w, h, statTooltip('con')) h = h + self.font_h
        self:drawString(s, "Agility      : #00ff00# "..player:getAgi(), w, h, statTooltip('agi')) h = h + self.font_h
        self:drawString(s, "Mind         : #00ff00# "..player:getMnd(), w, h, statTooltip('mnd')) h = h + self.font_h

        -- Second column: Effects and sustains
        h = 0
        w = self.w * 0.25

        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Effects#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        for tid, act in pairs(player.sustain_talents) do
            if act then
                local t = player:getTalentFromId(tid)
                self:drawString(s, tstring{color.good, t.name}:toString(), w, h,
                    GameUI:tooltipTitle(t.name):add(true):merge(player:getTalentFullDescription(t))) h = h + self.font_h
            end
        end
        for eff_id, p in pairs(player.tmp) do
            local tooltip
            local e = player.tempeffect_def[eff_id]
            if e.long_desc then
                tooltip = GameUI:tooltipTitle(e.desc):add(true, e.long_desc(player, p))
            end
            self:drawString(s, GameUI:tempEffectText(player, eff_id):toString(), w, h,
                tooltip) h = h + self.font_h
        end

    elseif kind=="attack" then
        local COL_WIDTH = 0.15
        w = 0

        h = 0
        if player:getInven(player.INVEN_RHAND) then
            for i, o in ipairs(player:getInven(player.INVEN_RHAND)) do
                local combat = player:getObjectCombat(o, "rhand")
                if combat then
                    h = self:drawCombatBlock(s, w, h, "Right Hand: "..o.name:capitalize(), combat)
                end
            end
        end
        if h ~= 0 then w = w + self.w * COL_WIDTH end

        h = 0
        if player:getInven(player.INVEN_LHAND) then
            for i, o in ipairs(player:getInven(player.INVEN_LHAND)) do
                local combat = player:getObjectCombat(o, "lhand")
                if combat then
                    h = self:drawCombatBlock(s, w, h, "Left Hand: "..o.name:capitalize(), combat, player:getOffHandMult(combat))
                end
            end
        end
        if h ~= 0 then w = w + self.w * COL_WIDTH end

        h = 0
        self:drawCombatBlock(s, w, h, "Unarmed", player:getObjectCombat(nil, "unarmed"))

    elseif kind=="defense" then
        h = 0
        w = 0

        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Physical Defenses#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        self:drawString(s, "Defense : #00ff00# "..player:combatDefense(), w, h,
            GameUI:tooltipTitle('Defense'):merge{true, "Ability to dodge or block attacks. Against an evenly matched opponent, +1 Defense decreases the chance to hit by roughly 5%."}) h = h + self.font_h
        self:drawString(s, "Armor   : #00ff00# "..player.combat_armor, w, h,
            GameUI:tooltipTitle('Armor'):merge{true, "Armor reduces damage from every physical attack by a random amount up to the given value."}) h = h + self.font_h

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

    w1("  [Qi Daozei Character Dump]")
    w1()

    w1(("%-32s"):format(makelabel("Name", player.name)))

    w1(("Str:  %d"):format(player:getStr()))
    w1(("Ski:  %d"):format(player:getSki()))
    w1(("Con:  %d"):format(player:getCon()))
    w1(("Agi:  %d"):format(player:getAgi()))
    w1(("Mnd:  %d"):format(player:getMnd()))

    fff:close()

    Dialog:simplePopup("Character dump complete", "File: "..fs.getRealPath(file))
end

function _M:drawCombatBlock(s, w, h, desc, combat, mult)
    local player = self.actor
    mult = mult or 1

    self:drawString(s, "#GOLD##{bold}#"..desc.."#{normal}##LAST#", w, h) h = h + self.font_h
    self:drawString(s, "Attack : #00ff00# "..player:combatAttack(combat), w, h,
        GameUI:tooltipTitle('Attack'):merge{true, "Accuracy in combat. Against an evenly matched opponent, +1 Attack increases the chance to hit by roughly 5%."}) h = h + self.font_h

    local dam_min, dam_max = player:combatDamageRange(combat)
    dam_min = math.round(dam_min * mult)
    dam_max = math.round(dam_max * mult)
    self:drawString(s, "Damage : #00ff00# "..string.describe_range(dam_min, dam_max, true), w, h,
        GameUI:tooltipTitle('Damage'):merge{true, "The damage range of this attack."}) h = h + self.font_h

    h = h + self.font_h
    return h
end
