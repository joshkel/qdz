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

local Dialog = require "mod.class.ui.Dialog"
local Talents = require "engine.interface.ActorTalents"
local Tab = require "engine.ui.Tab"
local SurfaceZone = require "engine.ui.SurfaceZone"
local Separator = require "engine.ui.Separator"
local Stats = require "mod.class.interface.ActorStats"
local Textzone = require "engine.ui.Textzone"
local GameRules = require "mod.class.GameRules"
local GameUI = require "mod.class.ui.GameUI"
local DamageType = require "engine.DamageType"

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
    self:drawDialog(kind)
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
        EXIT = function() game:unregisterDialog(self) end,
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
    local is_none

    if kind == "general" then
        -- First column: General info
        h = 0
        w = 0
        local name = player.name or "Unnamed"
        if player ~= game.player then name = name:capitalize() end
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#"..name.."#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h

        h = h + self.font_h

        self:drawString(s, ("#LIGHT_RED#Life : #00ff00#%d/%d"):format(player.life, player.max_life), w, h,
            GameUI:tooltipTitle('Life'):merge{true, "Your health. When this reaches 0, you die."}) h = h + self.font_h
        self:drawString(s, ("#LIGHT_BLUE#Qi   : #00ff00#%d/%d"):format(player:getQi(), player.max_qi), w, h,
            GameUI:tooltipTitle('Qi'):merge{true, player.resources_def[player.RS_QI].description}) h = h + self.font_h

        h = h + self.font_h
        self:drawString(s,     ("#GOLD#Level#LAST#         : %i"):format(player.level), w, h,
            GameUI:tooltipTitle('Level'):merge{true, "Overall experience level."}) h = h + self.font_h
        if player == game.player then
            self:drawString(s, ("Experience    : %i"):format(player:totalExp()), w, h,
                GameUI:tooltipTitle('Experience'):merge{true, "Experience gained so far. Experience is generally gained from killing monsters."}) h = h + self.font_h
            self:drawString(s, ("To next level : %i"):format(player:totalExpChart(player.level + 1)), w, h,
                GameUI:tooltipTitle('To Next Level'):merge{true, "Experience needed to reach the next level."}) h = h + self.font_h

            h = h + self.font_h

            self:drawString(s, tstring{'Money', '         : ', {"color", GameUI.money_color}, tostring(math.floor(player.money)), {'color', 'LAST'}}:toString(), w, h,
                GameUI:tooltipTitle('Money'):merge{true, GameUI.money_desc}) h = h + self.font_h
        end

        if player.can_absorb then
            h = h + self.font_h
            self:drawString(s, ("#GOLD##{bold}#Available Techniques#{normal}##LAST#"):format(player:getQi(), player.max_qi), w, h,
                GameUI:tooltipTitle('Available Techniques'):merge{true, "You can learn these techniques if you kill this creature while your qi is focused."}) h = h + self.font_h
            local absorb_count = #table.keys(player.can_absorb)
            local slots = {
                { 'rhand', 'R.hand', 'Killing this creature with a right-handed or two-handed attack while focused lets you learn ' },
                { 'lhand', 'L.hand', 'Killing this creature with a left-handed attack, ranged weapon, or special item while focused lets you learn ' },
                { 'chest', 'Chest ', 'Killing this creature with a bash while focused lets you learn ' },
                { 'feet',  'Feet  ', 'Killing this creature with a kick while focused lets you learn ' },
                { 'head',  'Head  ', 'Killing this creature with a qi technique while focused lets you learn ' }
            }
            if absorb_count > 1 then
                slots[#slots+1] = { 'any', 'Other ', 'Killing this creature in another fashion while focused lets you learn ' }
            else
                slots[#slots+1] = { 'any', 'Any   ', 'Killing this creature by any means while focused lets you learn ' }
            end
            for i, v in pairs(slots) do
                if player.can_absorb[v[1]] then
                    local talent = player:getTalentFromId(player.can_absorb[v[1]])
                    local known = profile.mod.techniques and profile.mod.techniques.techniques and profile.mod.techniques.techniques[talent.id]
                    if known then
                        self:drawString(s, tstring{color.caption, v[2], ': ', color.text, talent.name}:toString(), w, h,
                            tstring{v[3]}:add('this technique.', true, true):merge(GameUI:tooltipTitle(talent.name)):add(true):merge(game.player:getTalentFullDescription(talent))) h = h + self.font_h
                    else
                        self:drawString(s, tstring{color.caption, v[2], ': #777777#???'}:toString(), w, h,
                            tstring{v[3], 'a new technique.'}) h = h + self.font_h
                    end
                end
            end
        end

        -- Second column: Attributes
        h = 0
        w = self.w * 0.25
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Attributes#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        function statTooltip(short_name)
            return GameUI:tooltipTitle(player.stats_def[short_name].name):merge{true, player.stats_def[short_name].description}
        end
        self:drawString(s, "Strength     : #00ff00# "..player:getStr(), w, h, statTooltip('str')) h = h + self.font_h
        self:drawString(s, "Skill        : #00ff00# "..player:getSki(), w, h, statTooltip('ski')) h = h + self.font_h
        self:drawString(s, "Constitution : #00ff00# "..player:getCon(), w, h, statTooltip('con')) h = h + self.font_h
        self:drawString(s, "Agility      : #00ff00# "..player:getAgi(), w, h, statTooltip('agi')) h = h + self.font_h
        self:drawString(s, "Mind         : #00ff00# "..player:getMnd(), w, h, statTooltip('mnd')) h = h + self.font_h

        -- Third column: Speed and senses
        h = 0
        w = self.w * 0.5
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Speed#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        self:drawString(s, ("Base     : #00ff00# %3i%%"):format(player.global_speed * 100), w, h,
            GameUI:tooltipTitle('Base Speed'):merge{true, "Overall speed, indicating how many turns you get per “normal” game turn. Higher is better."}) h = h + self.font_h
        if player.movement_speed ~= 100 then
            self:drawString(s, ("Movement : #00ff00# %3i%%"):format(player.movement_speed * 100), w, h,
                GameUI:tooltipTitle('Movement'):merge{true, "Movement speed. Higher is better. The displayed value is multiplied by your base speed to determine the actual movement speed."}) h = h + self.font_h
        end

        h = h + self.font_h
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Senses#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        self:drawString(s, ("Sight        : #00ff00# %2i"):format(player.sight), w, h,
            GameUI:tooltipTitle('Sight'):merge{true, "How far you can see (assuming the area is sufficiently lit)."}) h = h + self.font_h
        self:drawString(s, ("Light Radius : #00ff00# %2i"):format(player.lite or 0), w, h,
            GameUI:tooltipTitle('Light Radius'):merge{true, "The area which you illuminate (due to your lantern, various techniques, etc.)."}) h = h + self.font_h
        if player.blindsense ~= 0 then
            self:drawString(s, ("Blindsense   : #00ff00# %2i"):format(player.blindsense), w, h,
                GameUI:tooltipTitle('Blindsense'):merge{true, GameRules.extra_stat_desc.blindsense}) h = h + self.font_h
        end

        h = h + self.font_h
        if player:attr("blind_fight") then
            s:drawColorStringBlended(self.font, "#GOLD##{bold}#Other Senses#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        end
        if player:attr("blind_fight") then
            self:drawString(s, "Blind-Fighting", w, h,
                GameUI:tooltipTitle('Blind-Fighting'):merge{true, "You have learned how to use senses other than sight in combat. You no longer suffer the flat ", tostring(GameRules.blind_miss), "% miss chance for attacking an unseen opponent or the flat ", tostring(GameRules.concealment_miss), "% miss chance for attacking a concealed opponent."}) h = h + self.font_h
        end

        -- Fourth column: Effects and sustains
        h = 0
        w = self.w * 0.75

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
        local COL_WIDTH = 0.2
        w = 0

        h = 0
        if player:getInven(player.INVEN_RHAND) then
            for i, o in ipairs(player:getInven(player.INVEN_RHAND)) do
                if o.combat then
                    h = self:drawCombatBlock(s, w, h, o.name:capitalize(), player:isInvenTwoHanded() and "Two Handed" or "Right Hand", o.combat)
                end
            end
        end
        if h ~= 0 then w = w + self.w * COL_WIDTH end

        h = 0
        if player:getInven(player.INVEN_LHAND) then
            for i, o in ipairs(player:getInven(player.INVEN_LHAND)) do
                if o.combat then
                    h = self:drawCombatBlock(s, w, h, o.name:capitalize(), "Left Hand", o.combat, player:getOffHandMult(o.combat))
                end
            end
        end
        if h ~= 0 then w = w + self.w * COL_WIDTH end

        h = 0
        self:drawCombatBlock(s, w, h, "Unarmed", "", player.combat)

    elseif kind=="defense" then
        -- First column: Basic / physical defenses
        h = 0
        w = 0
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Physical Defenses#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        self:drawString(s, "Defense : #00ff00# "..player:combatDefense(), w, h,
            GameUI:tooltipTitle('Defense'):merge{true, "Ability to dodge or block attacks. Against an evenly matched opponent, +1 Defense decreases the chance to hit by roughly 5%."}) h = h + self.font_h
        local armor_min, armor_max = player:combatArmorRange()
        self:drawString(s, "Armor   : #00ff00# "..string.describe_range(armor_min, armor_max, true), w, h,
            GameUI:tooltipTitle('Armor'):merge{true, ("An armor of %i reduces damage from every physical attack by %s (after including natural armor bonuses, techniques, etc.)."):format(armor_max, string.describe_range(armor_min, armor_max))}) h = h + self.font_h

        -- Second column: Saving throws
        h = 0
        w = self.w * 0.25
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Saving Throws#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        self:drawString(s, "Fortitude : #00ff00# "..player:fortSave(), w, h,
            GameUI:tooltipTitle('Fortitude'):merge{true, "Ability to shrug off physical ailments such as poison and disease."}) h = h + self.font_h
        self:drawString(s, "Reflex    : #00ff00# "..player:refSave(), w, h,
            GameUI:tooltipTitle('Reflex'):merge{true, "Ability to get out of the way of dangerous area effects."}) h = h + self.font_h
        self:drawString(s, "Will      : #00ff00# "..player:willSave(), w, h,
            GameUI:tooltipTitle('Will'):merge{true, "Willpower; the ability to resist effects targeting your mind."}) h = h + self.font_h

        -- Third column: Resistances
        h = 0
        w = self.w * 0.50
        s:drawColorStringBlended(self.font, "#GOLD##{bold}#Resistances#{normal}##LAST#", w, h, 255, 255, 255, true) h = h + self.font_h
        is_none = true
        for k, v in pairs(player.resists) do
            if v ~= 0 then
                is_none = false
                local type = DamageType:get(k)
                local sub, mult = player:combatResist(k)
                local pct = 100 - (mult * 100)
                self:drawString(s, ("%s%-10s#LAST#: #00ff00# %2i / %3i%%"):format(type.text_color or "", type.name:capitalize(), sub, pct), w, h,
                    GameUI:tooltipTitle(("%s Resistance"):format(type.name:capitalize())):merge{true, ("%i %s of %s resistance, meaning that %i is subtracted from all incoming %s damage, then the remainder is reduced by %i%%."):format(v, string.pluralize("level", v), type.name, sub, type.name, pct)}) h = h + self.font_h
            end
        end
        if is_none then
            self:drawString(s, "None", w, h) h = h + self.font_h
        end

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

function _M:drawCombatBlock(s, w, h, desc1, desc2, combat, mult)
    -- TODO: Add tooltips - explain about left hand damage penalty, where unarmed damage is used
    local player = self.actor
    mult = mult or 1

    self:drawString(s, "#GOLD##{bold}#"..desc1.."#{normal}##LAST#", w, h) h = h + self.font_h
    self:drawString(s, "#GOLD#"..desc2.."#LAST#", w, h) h = h + self.font_h
    self:drawString(s, "Attack : #00ff00# "..player:combatAttack(combat), w, h,
        GameUI:tooltipTitle('Attack'):merge{true, "Accuracy in combat. Against an evenly matched opponent, +1 Attack increases the chance to hit by roughly 5%."}) h = h + self.font_h

    local dam_min, dam_max = player:combatDamageRange(combat, mult)
    self:drawString(s, "Damage : #00ff00# "..string.describe_range(dam_min, dam_max, true), w, h,
        GameUI:tooltipTitle('Damage'):merge{true, "The damage range of this attack, before the opponent's armor is applied."}) h = h + self.font_h

    h = h + self.font_h
    return h
end
