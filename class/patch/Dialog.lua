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

local Dialog=require("engine.ui.Dialog")

local function configureYesNoKeys(d, fct, yes_text, no_text)
    yes_text = yes_text or "Yes"
    no_text = no_text or "No"
    if yes_text:sub(1, 1):lower() ~= no_text:sub(1, 1):lower() then
        d.key:addCommands{
            __TEXTINPUT = function(c)
                if c:lower() == yes_text:sub(1, 1):lower() then game:unregisterDialog(d) fct(true)
                elseif c:lower() == no_text:sub(1, 1):lower() then game:unregisterDialog(d) fct(false)
                end
            end,
        }
        d.on_register = function() game:onTickEnd(function() d.key:unicodeInput(true) end) end
    end
end

--- Requests a simple yes-no dialog
Dialog.yesnoPopup = function(self, title, text, fct, yes_text, no_text, no_leave, escape)
    local w, h = Dialog.font:size(text)
    local d = Dialog.new(title, 1, 1)

--    d.key:addBind("EXIT", function() game:unregisterDialog(d) fct(false) end)
    local ok = require("engine.ui.Button").new{text=yes_text or "Yes", fct=function() game:unregisterDialog(d) fct(true) end}
    local cancel = require("engine.ui.Button").new{text=no_text or "No", fct=function() game:unregisterDialog(d) fct(false) end}
    if not no_leave then d.key:addBind("EXIT", function() game:unregisterDialog(d) game:unregisterDialog(d) fct(escape) end) end
    d:loadUI{
        {left = 3, top = 3, ui=require("engine.ui.Textzone").new{width=w+20, height=h+5, text=text}},
        {left = 3, bottom = 3, ui=ok},
        {right = 3, bottom = 3, ui=cancel},
    }
    d:setFocus(ok)
    d:setupUI(true, true)
    configureYesNoKeys(d, fct, yes_text, no_text)

    game:registerDialog(d)
    return d
end

--- Requests a long yes-no dialog
Dialog.yesnoLongPopup = function(self, title, text, w, fct, yes_text, no_text, no_leave, escape)
    local list = text:splitLines(w - 10, font)
    local d = Dialog.new(title, 1, 1)

--    d.key:addBind("EXIT", function() game:unregisterDialog(d) fct(false) end)
    local ok = require("engine.ui.Button").new{text=yes_text or "Yes", fct=function() game:unregisterDialog(d) fct(true) end}
    local cancel = require("engine.ui.Button").new{text=no_text or "No", fct=function() game:unregisterDialog(d) fct(false) end}
    if not no_leave then d.key:addBind("EXIT", function() game:unregisterDialog(d) game:unregisterDialog(d) fct(escape) end) end
    d:loadUI{
        {left = 3, top = 3, ui=require("engine.ui.Textzone").new{width=w+20, height=Dialog.font_h * #list, text=text}},
        {left = 3, bottom = 3, ui=ok},
        {right = 3, bottom = 3, ui=cancel},
    }
    d:setFocus(ok)
    d:setupUI(true, true)
    configureYesNoKeys(d, fct, yes_text, no_text)

    game:registerDialog(d)
    return d
end

--- Requests a simple yes-no dialog
Dialog.yesnocancelPopup = function(self, title, text, fct, yes_text, no_text, cancel_text, no_leave, escape)
    local w, h = Dialog.font:size(text)
    local d = Dialog.new(title, 1, 1)

--    d.key:addBind("EXIT", function() game:unregisterDialog(d) fct(false) end)
    local ok = require("engine.ui.Button").new{text=yes_text or "Yes", fct=function() game:unregisterDialog(d) fct(true, false) end}
    local no = require("engine.ui.Button").new{text=no_text or "No", fct=function() game:unregisterDialog(d) fct(false, false) end}
    local cancel = require("engine.ui.Button").new{text=cancel_text or "Cancel", fct=function() game:unregisterDialog(d) fct(false, true) end}
    if not no_leave then d.key:addBind("EXIT", function() game:unregisterDialog(d) game:unregisterDialog(d) fct(false, not escape) end) end
    d:loadUI{
        {left = 3, top = 3, ui=require("engine.ui.Textzone").new{width=w+20, height=h + 5, text=text}},
        {left = 3, bottom = 3, ui=ok},
        {left = 3 + ok.w, bottom = 3, ui=no},
        {right = 3, bottom = 3, ui=cancel},
    }
    d:setFocus(ok)
    d:setupUI(true, true)
    configureYesNoKeys(d, fct, yes_text, no_text)

    game:registerDialog(d)
    return d
end

--- Requests a simple yes-no dialog
Dialog.yesnocancelLongPopup = function(self, title, text, w, fct, yes_text, no_text, cancel_text, no_leave, escape)
    local list = text:splitLines(w - 10, font)
    local d = Dialog.new(title, 1, 1)

--    d.key:addBind("EXIT", function() game:unregisterDialog(d) fct(false) end)
    local ok = require("engine.ui.Button").new{text=yes_text or "Yes", fct=function() game:unregisterDialog(d) fct(true, false) end}
    local no = require("engine.ui.Button").new{text=no_text or "No", fct=function() game:unregisterDialog(d) fct(false, false) end}
    local cancel = require("engine.ui.Button").new{text=cancel_text or "Cancel", fct=function() game:unregisterDialog(d) fct(false, true) end}
    if not no_leave then d.key:addBind("EXIT", function() game:unregisterDialog(d) game:unregisterDialog(d) fct(false, not escape) end) end
    d:loadUI{
        {left = 3, top = 3, ui=require("engine.ui.Textzone").new{width=w+20, height=Dialog.font_h * #list, text=text}},
        {left = 3, bottom = 3, ui=ok},
        {left = 3 + ok.w, bottom = 3, ui=no},
        {right = 3, bottom = 3, ui=cancel},
    }
    d:setFocus(ok)
    d:setupUI(true, true)
    configureYesNoKeys(d, fct, yes_text, no_text)

    game:registerDialog(d)
    return d
end

