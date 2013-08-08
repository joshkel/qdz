-- Qi Dao Zei
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

-- Game UI constants and helpers

module(..., package.seeall, class.make)

-- TODO: These color names / descriptions were from an old version of Actor:getTalentFullDescription.
-- They need to be a bit more consistent / generic / widely applicable.
-- Note: Since these are designed to be used with tstrings, they're formatted as tstring color codes.
_M.tooltipColor = {
    -- Caption
    caption = { "color", 0x6f, 0xff, 0x83 },

    -- Body text (game values, descriptions, etc.)
    text = { "color", 0xff, 0xff, 0xff },

    -- Use mode of a talent.  This is still a bit too vague.
    use = { "color", 0x00, 0xff, 0x00 },

    -- Resources
    health = { "color", "LIGHT_RED" },
    power = { "color", "LIGHT_BLUE" },

    -- Good stuff: sustained talents, beneficial timed effects, etc.
    good = { "color", "LIGHT_GREEN" },

    -- Bad stuff: detrimental timed effects, etc.
    bad = { "color", "LIGHT_RED" }
}

---Generates a tstring giving the title for a tooltip.  Static function.
---@param display_string Optional display string
---@param title
function _M:tooltipTitle(display_string, title)
    if title then
        return tstring{display_string, {"color","GOLD"}, {"font", "bold"}, title:capitalize(), {"font", "normal"}, {"color", "LAST"}}
    else
        title = display_string
        return tstring{{"color","GOLD"}, {"font", "bold"}, title:capitalize(), {"font", "normal"}, {"color", "LAST"}}
    end
end

---Returns a tstring describing a temporary effect on an Actor.  Static function.
function _M:tempEffectText(actor, eff_id)
    local color = self.tooltipColor 
    local e = actor.tempeffect_def[eff_id]
    local dur = actor:hasEffect(eff_id).dur + 1
    local this_color = e.status == "detrimental" and color.bad or color.good
    return tstring{this_color, e.desc, (" (%i)"):format(dur)}
end
