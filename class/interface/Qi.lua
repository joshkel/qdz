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

--- Interface for qi combat
--
-- Basic design:
-- * If the player kills a creature while the player's qi is focused, then
--   the player may absorb a technique.
-- * Anything that the player causes while qi is focused - projectiles,
--   temporary effects, etc. - need to remember if they were created while
--   qi was focused, so that they can properly trigger an absorb.
-- * The result is (potentially) a chain of "intermediate" attributes referring
--   back to the player and a series of "focused_qi" attributes indicating
--   whether the player was focused when each effect / entity was created.
-- * Each intermediate effect / entity can temporarily apply its focused state
--   back to the player by using Qi.call or Qi.preCall / Qi.postCall when
--   doing anything that might kill a creature.
--
-- Tracking intermediate effects is also useful for displaying more detailed
-- messages in damage_types.lua.  See that file for more details.
module(..., package.seeall, class.make)

--- Definitions of qi technique slots.  See also talents.lua, load.lua.
-- TODO: Terminology's a bit inconsistent - "absorb type," "slot" are mostly synonymous.
_M.slots_def = {
    rhand = {
        desc = "right hand",
        stat = "str",
    },
    lhand = {
        desc = "left hand",
        stat = "ski",
    },
    chest = {
        desc = "chest",
        stat = "con",
    },
    feet = {
        desc = "feet",
        stat = "agi",
    },
    head = {
        desc = "head",
        stat = "mnd",
    },
}

--- Gets the currently active intermediate effect for the given entity.
function _M.getIntermediate(e)
    while e.intermediate do
        e = e.intermediate
    end
    return e
end

--- Static function that saves a source's qi state to an intermediate effect
--- so that the intermediate effect can properly trigger absorb.
function _M.saveSourceInfo(from, to)
    from = _M.getIntermediate(from)

    to.last_action = from.last_action

    -- Allow focused_qi state to carry over from previous applications, if relevant.
    if from.focused_qi or (from.hasEffect and from:hasEffect(from.EFF_FOCUSED_QI)) then
        to.focused_qi = true
    end

    -- T-Engine's convention seems to be to set src itself, but just in case it
    -- doesn't, we'll do this.  This is needed for "to" tables that we make up
    -- ourselves, as for DamageType.QI_CALL.
    if not to.src then
        to.src = from
    end

    return to
end

--- Calls the given function, correctly applying any intermediate qi state
function _M.call(intermediate, f, ...)
    return util.scoped_change(intermediate.src, {intermediate=intermediate}, f, ...)
end

--- Split pre- and post- version of Qi.call
function _M.preCall(intermediate)
    if intermediate.src then return util.apply_temp_change(intermediate.src, {intermediate=intermediate}) end
end

--- Split pre- and post- version of Qi.call
function _M.postCall(intermediate, saved)
    if intermediate.src then util.revert_temp_change(intermediate.src, {intermediate=intermediate}, saved) end
end

--- Checks if an entity or effect has focused qi.  There are two ways this could happen:
---  1) Entity has EFF_FOCUSED_QI directly.
---  2) Entity initiated some intermediate effect while focused.
function _M.isFocused(e)
    if e.intermediate then
        return _M.isFocused(e.intermediate)
    else
        return e.focused_qi or (e.hasEffect and e:hasEffect(e.EFF_FOCUSED_QI))
    end
end

---Clears qi focus.  This is triggered by successfully absorbing a qi technique.
---For now, this is *disabled*.  If you can kill several enemies with a single
---blow, you deserve to absorb several techniques.  If this becomes unbalanced,
---we can reconsider.
function _M.clearFocus(e)
    --If this is reenabled, it needs to be more sophisticated.  E.g., if a
    --single technique triggers multiple effects (projectiles, timed effects,
    --etc.), each effect currently has its own copy of focus state; all copies
    --would need to be cleared.

    --[[if e.intermediate then
        _M.clearFocus(e.intermediate)
    elseif e.focused_qi then
        e.focused_qi = false
    elseif e.removeEffect then
        e:removeEffect(e.EFF_FOCUSED_QI)
    end]]
end

