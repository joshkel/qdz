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
require "mod.class.Actor"
require "engine.interface.PlayerRest"
require "engine.interface.PlayerRun"
require "engine.interface.PlayerMouse"
require "engine.interface.PlayerHotkeys"
local Map = require "engine.Map"
local Dialog = require "engine.Dialog"
local Talents = require "engine.interface.ActorTalents"
local Astar = require "engine.Astar"
local DirectPath = require "engine.DirectPath"
local Qi = require "mod.class.interface.Qi"

--- Defines the player
-- It is a normal actor, with some redefined methods to handle user interaction.<br/>
-- It is also able to run and rest and use hotkeys
module(..., package.seeall, class.inherit(
    mod.class.Actor,
    engine.interface.PlayerRest,
    engine.interface.PlayerRun,
    engine.interface.PlayerMouse,
    engine.interface.PlayerHotkeys
))

function _M:init(t, no_default)
    t.display=t.display or '@'
    t.color_r=t.color_r or 230
    t.color_g=t.color_g or 230
    t.color_b=t.color_b or 230

    t.player = true
    t.type = t.type or "humanoid"
    t.subtype = t.subtype or "player"
    t.faction = t.faction or "players"

    t.lite = t.lite or 0

    mod.class.Actor.init(self, t, no_default)
    engine.interface.PlayerHotkeys.init(self, t)

    self.descriptor = {}
end

--- Sorts hotkeys in the order in which their corresponding talents are defined.
--- By default, as far as I can tell, they're sorted effectively randomly, in
--- whatever order the birth descriptors' talent hash tables happen to list them.
function _M:sortHotkeysByTalent()
    -- Make a lookup of talent IDs giving the order in which they're defined.
    local talent_order = {}
    local n = 1
    for i, tt in ipairs(Talents.talents_types_def) do
        for j, t in ipairs(tt.talents) do
            talent_order[t.id] = n
            n = n + 1
        end
    end

    -- Sort talent hotkeys by definition order, using a selection sort.
    for i = 1, 12 * self.nb_hotkey_pages do
        if self.hotkey[i] and self.hotkey[i][1] == "talent" then
            local min_at, min_value = i, talent_order[self.hotkey[i][2]]
            for j = i + 1, 12 * self.nb_hotkey_pages do
                if self.hotkey[j] and self.hotkey[j][1] == "talent" and talent_order[self.hotkey[j][2]] < min_value then
                    min_at, min_value = j, talent_order[self.hotkey[j][2]]
                end
            end
            if min_at ~= i then
                self.hotkey[i], self.hotkey[min_at] = self.hotkey[min_at], self.hotkey[i]
            end
        end
    end
end

function _M:move(x, y, force)
    local moved = mod.class.Actor.move(self, x, y, force)
    if moved then
        game.level.map:moveViewSurround(self.x, self.y, 8, 8)
    end
    return moved
end

function _M:act()
    if not mod.class.Actor.act(self) then return end

    -- Clean log flasher
    game.flash:empty()

    -- Resting ? Running ? Otherwise pause
    if not self:restStep() and not self:runStep() and self.player then
        game.paused = true
    end
end

-- Precompute FOV form, for speed
local fovdist = {}
for i = 0, 30 * 30 do
    fovdist[i] = math.max((20 - math.sqrt(i)) / 14, 0.6)
end

function _M:playerFOV()
    -- Clean FOV before computing it
    game.level.map:cleanFOV()

    -- Blindsense: View "major" terrain (i.e., anything normally blocking movement)
    -- and (at least some) creatures.
    --
    -- This is dimmer than regular light. Do it first so that regular light
    -- can override it.
    --
    -- TODO: Mostly working, but finding objects with blindsense only is almost impossible.
    if self:attr("blindsense") then
        self:computeFOV(self.blindsense, "block_sight", function(x, y, dx, dy, sqdist)
            -- TODO: Any way to show an actor without showing the ground under it?
            if game.level.map:checkEntity(x, y, Map.TERRAIN, "does_block_move") or game.level.map:checkEntity(x, y, Map.TERRAIN, "door_opened") or self:canSee(game.level.map(x, y, Map.ACTOR)) then
                -- For comparison, a default remembered (but unseen) square is 0.6.
                game.level.map:applyLite(x, y, 0.7)
            end
        end, true, true, true)
    end

    -- Compute both the normal and the lite FOV, using cache
    self:computeFOV(self.sight or 20, "block_sight", function(x, y, dx, dy, sqdist)
        game.level.map:apply(x, y, fovdist[sqdist])
    end, true, false, true)
    self:computeFOV(self.lite, "block_sight", function(x, y, dx, dy, sqdist) game.level.map:applyLite(x, y) end, true, true, true)
end

function _M:doFOV()
    game.level.map.clean_fov = true
    self:playerFOV()
end

--- Adds map lighting (see playerFov) to Actor.canReallySee
function _M:canReallySee(actor)
    return self:canSee(actor) and game.level.map.seens(actor.x, actor.y)
end

--- Called before taking a hit, overload mod.class.Actor:onTakeHit() to stop resting and running
function _M:onTakeHit(value, src)
    self:runStop("taken damage")
    self:restStop("taken damage")
    local ret = mod.class.Actor.onTakeHit(self, value, src)
    if self.life < self.max_life * 0.3 then
        local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
        game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, 2, "LOW HEALTH!", {255,0,0}, true)
    end
    return ret
end

function _M:die(src)
    if self.game_ender then
        engine.interface.ActorLife.die(self, src)
        game.paused = true
        self.energy.value = game.energy_to_act
        game:registerDialog(require("mod.dialogs.DeathDialog").new(self))
    else
        mod.class.Actor.die(self, src)
    end
end

function _M:setName(name)
    self.name = name
    game.save_name = name
end

--- Notify the player of available cooldowns
function _M:onTalentCooledDown(tid)
    if not self:knowTalent(tid) then return end
    local t = self:getTalentFromId(tid)

    local x, y = game.level.map:getTileToScreen(self.x, self.y)
    game.flyers:add(x, y, 30, -0.3, -3.5, ("%s available"):format(t.name:capitalize()), {0,255,00})
    game.log("#00ff00#Technique %s is ready to use.#LAST#", t.name)
end

function _M:levelup()
    mod.class.Actor.levelup(self)

    local x, y = game.level.map:getTileToScreen(self.x, self.y)
    game.flyers:add(x, y, 80, 0.5, -2, "LEVEL UP!", {0,255,255})
    game.log("#00ffff#Welcome to level %d.#LAST#", self.level)
end

--- Tries to get a target from the user
function _M:getTarget(typ)
    return game:targetGetForPlayer(typ)
end

--- Sets the current target
function _M:setTarget(target)
    return game:targetSetForPlayer(target)
end

local function spotHostiles(self)
    local seen = false
    -- Check for visible monsters, only see LOS actors, so telepathy wont prevent resting
    core.fov.calc_circle(self.x, self.y, game.level.map.w, game.level.map.h, 20, function(_, x, y) return game.level.map:opaque(x, y) end, function(_, x, y)
        local actor = game.level.map(x, y, game.level.map.ACTOR)
        if actor and self:reactionToward(actor) < 0 and self:canSee(actor) and game.level.map.seens(x, y) then seen = true end
    end, nil)
    return seen
end

--- Can we continue resting ?
-- We can rest if no hostiles are in sight, and if we need life/mana/stamina (and their regen rates allows them to fully regen)
function _M:restCheck()
    if spotHostiles(self) then return false, "hostile spotted" end

    -- Check resources, make sure they CAN go up, otherwise we will never stop
    if self:getQi() < self:getMaxQi() and self.qi_regen > 0 then return true end
    if self.life < self.max_life and self.life_regen > 0 then return true end

    if self.resting.rest_turns then return true end

    return false, "all resources and life at maximum"
end

--- Can we continue running?
-- We can run if no hostiles are in sight, and if we no interesting terrains are next to us
function _M:runCheck()
    if spotHostiles(self) then return false, "hostile spotted" end

    -- Notice any noticeable terrain
    local noticed = false
    self:runScan(function(x, y)
        -- Only notice interesting terrains
        local grid = game.level.map(x, y, Map.TERRAIN)
        if grid and grid.notice then noticed = "interesting terrain" end
    end)
    if noticed then return false, noticed end

    self:playerFOV()

    return engine.interface.PlayerRun.runCheck(self)
end

function _M:runStopped()
    self:doFOV()
end

--- Move with the mouse
-- We just feed our spotHostile to the interface mouseMove
function _M:mouseMove(tmx, tmy)
    return engine.interface.PlayerMouse.mouseMove(self, tmx, tmy, spotHostiles)
end

function _M:getEncumberTitleUpdater(title)
    return function()
        local enc, max = self:getEncumbrance(), self:getMaxEncumbrance()
        local color = "#00ff00#"
        if enc > max then color = "#ff0000#"
        elseif enc > max * 0.9 then color = "#ff8a00#"
        elseif enc > max * 0.75 then color = "#fcff00#"
        end
        return ("%s - %sEncumbrance %d/%d"):format(title, color, enc, max)
    end
end

function _M:showEquipInven(title, filter, action, on_select, inven)
    return engine.interface.ActorInventory.showEquipInven(self,
        self:getEncumberTitleUpdater(title)(), filter, action, on_select, inven)
end

function _M:showInventory(title, inven, filter, action)
    return engine.interface.ActorInventory.showInventory(self,
        self:getEncumberTitleUpdater(title)(), inven, filter, action)
end

function _M:playerPickup()
    -- If 2 or more objects, display a pickup dialog, otherwise just picks up
    if game.level.map:getObject(self.x, self.y, 2) then
        local d d = self:showPickupFloor("Pickup", nil, function(o, item)
            self:pickupFloor(item, true)
            self.changed = true
            d:used()
        end)
    else
        if self:pickupFloor(1, true) then
            self:sortInven()
            self:useEnergy()
            self.changed = true
        end
    end
end

function _M:playerDrop()
    local inven = self:getInven(self.INVEN_INVEN)
    local d d = self:showInventory("Drop object", inven, nil, function(o, item)
        self:dropFloor(inven, item, true, true)
        self:sortInven(inven)
        self:useEnergy()
        self.changed = true
        return true
    end)
end

function _M:playerUseItem(object, item, inven)
    local use_fct = function(o, inven, item)
        if not o then return end
        local co = coroutine.create(function()
            self.changed = true

            local ret = o:use(self, nil, inven, item) or {}
            if not ret.used then return end
            if ret.destroy then
                if o.multicharge and o.multicharge > 1 then
                    o.multicharge = o.multicharge - 1
                else
                    local _, del = self:removeObject(self:getInven(inven), item)
                    if del then
                        game.log("You have no more %s.", string.pluralize(o:getName{no_count=true, do_color=true}))
                    else
                        game.log("You have %s left.", o:getName{force_count=true, do_color=true})
                    end
                    self:sortInven(self:getInven(inven))
                end
            end
        end)
        local ok, ret = coroutine.resume(co)
        if not ok and ret then print(debug.traceback(co)) error(ret) end
        return true
    end

    if object and item then return use_fct(object, inven, item) end

    self:showEquipInven("Use object",
        function(o)
            return o:canUseObject()
        end,
        use_fct
    )
end

function _M:doDrop(inven, item, on_done, nb)
    if self.no_inventory_access then return end
    
    if nb == nil or nb >= self:getInven(inven)[item]:getNumber() then
        self:dropFloor(inven, item, true, true)
    else
        for i = 1, nb do self:dropFloor(inven, item, true) end
    end
    self:sortInven(inven)
    self:useEnergy()
    self.changed = true
    if on_done then on_done() end
end

function _M:doWear(inven, item, o)
    self:removeObject(inven, item, true)
    local ro = self:wearObject(o, true, true)
    if ro then
        if type(ro) == "table" then self:addObject(inven, ro) end
    elseif not ro then
        self:addObject(inven, o)
    end
    self:sortInven()
    self:useEnergy()
    self.changed = true
end

function _M:doTakeoff(inven, item, o)
    if self:takeoffObject(inven, item) then
        self:addObject(self.INVEN_INVEN, o)
    end
    self:sortInven()
    self:useEnergy()
    self.changed = true
end

function _M:getTechniqueLimit()
    -- TODO: Figure out a good value for this number
    return self.level + 2
end

function _M:checkTechniqueLimit(newest_tid)
    if self:getTechniqueCount() <= self:getTechniqueLimit() then return end

    game:registerDialog(require("mod.dialogs.ForgetTalent").new(self, newest_tid))
end

--- Absorbs the qi technique from a slain opponent (given by src)
function _M:absorbTechnique(src)
    local typ = self:getAbsorbSlot()
    print(("ABSORB TECHNIQUE: getAbsorbSlot = %s"):format(typ or "nil"))

    if not typ then return false end

    if not src.can_absorb then
        game.logSeen(self, ("%s's qi is too weak to absorb."):format(src.name:capitalize()))
        return false
    end

    local t_id = src.can_absorb[typ] or src.can_absorb["any"]
    if not t_id then
        game.logSeen(self, ("You try to absorb %s's qi, but it does nothing when bound to your %s."):format(
            src.name, Qi.slots_def[typ].desc))
        return false
    end

    if self:knowTalent(t_id) then
        game.logSeen(self, ("You try to absorb %s's qi, but you already know %s."):format(
            src.name, self:getTalentDisplayName(self:getTalentFromId(t_id))))
        return false
    end

    local t = self:getTalentFromId(t_id)
    game.level.map:particleEmitter(self.x, self.y, 1, "absorb_qi")
    if not t.silent_absorb then
        game.log(("You absorb a portion of %s's qi and bind it to your %s. You learn %s!"):format(
            src.name, Qi.slots_def[typ].desc, self:getTalentDisplayName(t)))
    end
    self:learnTalent(t_id, true)

    -- Mark this technique as seen.
    profile:saveModuleProfile("techniques", {tid=t_id, nb={"inc",1}})

    self:checkTechniqueLimit(t_id)

    return true
end

--- For the player (only), learning or unlearning qi talents alters stats.
function _M:changeStatForTalent(t_id, mod)
    local t = self:getTalentFromId(t_id)
    local t_type = self:getTalentTypeFrom(t.type[1])
    if Qi.slots_def[t_type.slot] then
        local stat = Qi.slots_def[t_type.slot].stat
        self:incIncStat(stat, mod)
        game.log(mod > 0 and self.stats_def[stat].gain_msg or self.stats_def[stat].lose_msg)
    end
end

--- Overload ActorTalents:learnTalent to add changeStatForTalent
function _M:learnTalent(t_id, force, nb)
    local ok, err = mod.class.Actor.learnTalent(self, t_id, force, nb)
    if not ok then return ok, err end
    self:changeStatForTalent(t_id, 1)
    return ok
end

--- Overload ActorTalents:unlearnTalent to add changeStatForTalent
function _M:unlearnTalent(t_id, nb)
    local ok, err = mod.class.Actor.unlearnTalent(self, t_id, nb)
    if not ok then return ok, err end
    self:changeStatForTalent(t_id, -1)
    return ok
end

