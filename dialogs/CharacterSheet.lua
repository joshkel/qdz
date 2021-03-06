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
Keyboard: #00FF00#'d'#LAST# to save character dump. #00FF00#Tab#LAST# or #00FF00#Shift+Tab#LAST# to switch between tabs.
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
    [{"_TAB","shift"}] = function() self:backtabTabs() end,
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

function _M:backtabTabs()
    if self.c_general.selected == true then self.c_defense:select() elseif
    self.c_attack.selected == true then self.c_general:select() elseif
    self.c_defense.selected == true then self.c_attack:select() end
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

    local drawHeader = function(text, tooltip)
        self:drawString(s, "#GOLD##{bold}#"..text.."#{normal}##LAST#", w, h, tooltip) h = h + self.font_h
    end
    local drawLine = function(text, tooltip)
        self:drawString(s, text, w, h, tooltip) h = h + self.font_h
    end
    local drawBlock = function(text, tooltip, ...)
        local arg = table.pack(...)
        if not table.any(unpack(arg)) then return end
        if h ~= 0 then h = h + self.font_h end
        if text then drawHeader(text, tooltip) end
        for i = 1, arg.n do
            if arg[i] then
                if type(arg[i]) == "string" then drawLine(arg[i]) else drawLine(arg[i][1], arg[i][2]) end
            end
        end
    end

    if kind == "general" then
        -- First column: General info
        h = 0
        w = 0
        local name = player.name or "Unnamed"
        if player ~= game.player then name = name:capitalize() end
        drawHeader(name)

        h = h + self.font_h

        drawLine(("#LIGHT_RED#Life : #00ff00#%d/%d"):format(player.life, player.max_life),
            GameUI:tooltipTitle('Life'):merge{true, "Your health. When this reaches 0, you die."})
        drawLine(("#LIGHT_BLUE#Qi   : #00ff00#%d/%d"):format(player:getQi(), player.max_qi),
            GameUI:tooltipTitle('Qi'):merge{true, player.resources_def[player.RS_QI].description})

        h = h + self.font_h
        drawLine(("#GOLD#Level#LAST#         : %i"):format(player.level),
            GameUI:tooltipTitle('Level'):merge{true, "Overall experience level."})
        if player == game.player then
            drawLine(("Experience    : %i"):format(player:totalExp()),
                GameUI:tooltipTitle('Experience'):merge{true, "Experience gained so far. Experience is generally gained from killing monsters."})
            drawLine(("To next level : %i"):format(player:totalExpChart(player.level + 1)),
                GameUI:tooltipTitle('To Next Level'):merge{true, "Experience needed to reach the next level."})

            h = h + self.font_h

            drawLine(tstring{'Money', '         : ', {"color", GameUI.money_color}, tostring(math.floor(player.money)), {'color', 'LAST'}}:toString(),
                GameUI:tooltipTitle('Money'):merge{true, GameUI.money_desc})
        end

        if player.can_absorb then
            h = h + self.font_h
            drawHeader("Available Techniques",
                GameUI:tooltipTitle('Available Techniques'):merge{true, "You can learn these techniques if you kill this creature while your qi is focused."})
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
                        drawLine(tstring{color.caption, v[2], ': ', color.text, talent.name}:toString(),
                            tstring{v[3]}:add('this technique.', true, true):merge(GameUI:tooltipTitle(talent.name)):add(true):merge(game.player:getTalentFullDescription(talent)))
                    else
                        drawLine(tstring{color.caption, v[2], ': #777777#???'}:toString(),
                            tstring{v[3], 'a new technique.'})
                    end
                end
            end
        end

        -- Second column: Attributes
        h = 0
        w = self.w * 0.25
        function statTooltip(short_name)
            return GameUI:tooltipTitle(player.stats_def[short_name].name):merge{true, player.stats_def[short_name].description}
        end
        drawBlock("Attributes", nil,
            {"Strength     : #00ff00# "..player:getStr(), statTooltip('str')},
            {"Skill        : #00ff00# "..player:getSki(), statTooltip('ski')},
            {"Constitution : #00ff00# "..player:getCon(), statTooltip('con')},
            {"Agility      : #00ff00# "..player:getAgi(), statTooltip('agi')},
            {"Mind         : #00ff00# "..player:getMnd(), statTooltip('mnd')})

        -- Third column: Speed and senses
        h = 0
        w = self.w * 0.5
        drawBlock("Speed", nil,
            {("Base     : #00ff00# %3i%%"):format(player.global_speed * 100),
                GameUI:tooltipTitle('Base Speed'):merge{true,
                    "Overall speed, indicating how many turns you get per “normal” game turn. Higher is better."}},
            player.movement_speed ~= 1 and
                {("Movement : #00ff00# %3i%%"):format(player.movement_speed * 100),
                    GameUI:tooltipTitle('Movement'):merge{true,
                        "Movement speed. Higher is better. The displayed value is multiplied by your base speed to determine the actual movement speed."}})

        drawBlock("Senses", nil,
            {("Sight        : #00ff00# %2i"):format(player.sight),
                GameUI:tooltipTitle('Sight'):merge{true, "How far you can see (assuming the area is sufficiently lit)."}},
            {("Light Radius : #00ff00# %2i"):format(player.lite or 0),
                GameUI:tooltipTitle('Light Radius'):merge{true, "The area which you illuminate (due to your lantern, various techniques, etc.)."}},
            player:attr("blindsense") and
                {("Blindsense   : #00ff00# %2i"):format(player:attr("blindsense")),
                    GameUI:tooltipTitle('Blindsense'):merge{true, GameRules.extra_stat_desc.blindsense}})

        drawBlock("Other Senses", nil,
            player:attr("blind_fight") and
                {"Blind-Fighting",
                    GameUI:tooltipTitle('Blind-Fighting'):merge{true, "You have learned how to use senses other than sight in combat. ", GameRules.extra_stat_desc.blind_fight}})

        drawBlock("Movement", nil,
            player:attr("flying") and
                {"Flying", GameUI:tooltipTitle("Flying"):merge{true, "Flying allows you to avoid certain terrain features."}},
            player:attr("forbid_diagonals") and
                {"No Diagonals", GameUI:tooltipTitle("No Diagonals"):merge{true, "Moving or attacking diagonally is not permitted."}},
            player:attr("random_move") and
                {("Random Movement : %2i%%"):format(player:attr("random_move")),
                    GameUI:tooltipTitle('Random Movement'):merge{true, ("You will move randomly %i%% of the time. Only movements are affected; you retain full control of your attacks"):format(player:attr("random_move"))}})

        -- Fourth column: Effects and sustains
        h = 0
        w = self.w * 0.75

        drawHeader("Effects")
        for tid, act in pairs(player.sustain_talents) do
            if act then
                local t = player:getTalentFromId(tid)
                drawLine(tstring{color.good, t.name}:toString(),
                    GameUI:tooltipTitle(t.name):add(true):merge(player:getTalentFullDescription(t)))
            end
        end
        for eff_id, p in pairs(player.tmp) do
            local tooltip
            local e = player.tempeffect_def[eff_id]
            if e.long_desc then
                tooltip = GameUI:tooltipTitle(e.desc):add(true, e.long_desc(player, p))
            end
            drawLine(GameUI:tempEffectText(player, eff_id):toString(), tooltip)
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
        self:drawCombatBlock(s, w, h, player.combat.desc and player.combat.desc:capitalize() or "Unarmed", "", player.combat)

    elseif kind=="defense" then
        -- First column: Basic / physical defenses
        h = 0
        w = 0
        drawHeader("Physical Defenses")

        --  * Defense value, including optional hit chance
        local defense_tooltip = GameUI:tooltipTitle('Defense'):merge{true, "Ability to dodge or block attacks. Against an evenly matched opponent, +1 Defense decreases the chance to hit by roughly 5%."}
        if player ~= game.player then
            local attack, defense = game.player:combatAttack(game.player:firstCombat()), player:combatDefense()
            defense_tooltip:add(true, true, ("Your Attack of %i gives you a %i%% chance to hit this Defense."):format(attack, game.player:skillChanceOfSuccess(attack, defense)))
        end
        --  * Armor value, including reduction range
        drawLine("Defense : #00ff00# "..player:combatDefense(), defense_tooltip)

        local armor_min, armor_max = player:combatArmorRange()
        drawLine("Armor   : #00ff00# "..string.describe_range(armor_min, armor_max, true),
            GameUI:tooltipTitle('Armor'):merge{true, ("Armor will reduce damage from every physical attack by %s (after including natural armor bonuses, techniques, etc.)."):format(string.describe_range(armor_min, armor_max))})

        -- Second column: Saving throws
        h = 0
        w = self.w * 0.25
        drawHeader("Saving Throws")
        drawLine("Fortitude : #00ff00# "..player:fortSave(),
            GameUI:tooltipTitle('Fortitude'):merge{true, "Ability to shrug off physical ailments such as poison and disease."})
        drawLine("Reflex    : #00ff00# "..player:refSave(),
            GameUI:tooltipTitle('Reflex'):merge{true, "Ability to get out of the way of dangerous area effects."})
        drawLine("Will      : #00ff00# "..player:willSave(),
            GameUI:tooltipTitle('Will'):merge{true, "Willpower; the ability to resist effects targeting your mind."})

        -- Third column: Resistances
        h = 0
        w = self.w * 0.50
        drawHeader("Resistances")
        is_none = true
        for k, v in pairs(player.resists) do
            if v ~= 0 then
                is_none = false
                local type = DamageType:get(k)
                local sub, mult = player:combatResist(k)
                local pct = 100 - (mult * 100)
                drawLine(("%s%-10s#LAST#: #00ff00# %2i / %3i%%"):format(type.text_color or "", type.name:capitalize(), sub, pct),
                    GameUI:tooltipTitle(("%s Resistance"):format(type.name:capitalize())):merge{true, ("%i %s of %s resistance, meaning that %i is subtracted from all incoming %s damage, then the remainder is reduced by %i%%."):format(v, string.pluralize("level", v), type.name, sub, type.name, pct)})
            end
        end
        if is_none then
            drawLine("None")
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

    local attack_tooltip = GameUI:tooltipTitle('Attack'):merge{true, "Accuracy in combat. Against an evenly matched opponent, +1 Attack increases the chance to hit by roughly 5%."}
    if player ~= game.player then
        local attack, defense = player:combatAttack(combat), game.player:combatDefense()
        attack_tooltip:add(true, true, ("This Attack gives a %i%% chance to hit your Defense of %i."):format(player:skillChanceOfSuccess(attack, defense), defense))
    end
    self:drawString(s, "Attack : #00ff00# "..player:combatAttack(combat), w, h,
        attack_tooltip) h = h + self.font_h

    local dam_min, dam_max = player:combatDamageRange(combat, mult)
    self:drawString(s, "Damage : #00ff00# "..string.describe_range(dam_min, dam_max, true), w, h,
        GameUI:tooltipTitle('Damage'):merge{true, "The damage range of this attack, before the opponent's armor is applied."}) h = h + self.font_h
    for _, melee_project in ipairs{ combat.melee_project or {}, player.melee_project } do
        for typ, dam in pairs(melee_project) do
            if dam > 0 then
                local damtype = DamageType:get(typ)
                self:drawString(s, ("       #00ff00# + %s%i %s"):format(damtype.text_color, dam, damtype.name), w, h) h = h + self.font_h
            end
        end
    end

    h = h + self.font_h
    return h
end
