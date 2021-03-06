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
require "engine.Actor"
require "engine.Autolevel"
require "engine.interface.ActorTemporaryEffects"
require "engine.interface.ActorLife"
require "engine.interface.ActorProject"
require "engine.interface.ActorLevel"
require "mod.class.interface.ActorStats"
require "engine.interface.ActorTalents"
require "engine.interface.ActorResource"
require "engine.interface.ActorFOV"
require "engine.interface.ActorInventory"
require "mod.class.interface.Combat"
local Map = require "engine.Map"
local Talents = require "engine.interface.ActorTalents"
local Qi = require "mod.class.interface.Qi"
local GameUI = require "mod.class.ui.GameUI"
local GameRules = require "mod.class.GameRules"
local DamageType = require "engine.DamageType"

module(..., package.seeall, class.inherit(
    engine.Actor,
    engine.interface.ActorInventory,
    engine.interface.ActorTemporaryEffects,
    engine.interface.ActorLife,
    engine.interface.ActorProject,
    engine.interface.ActorLevel,
    mod.class.interface.ActorStats,
    engine.interface.ActorTalents,
    engine.interface.ActorResource,
    engine.interface.ActorFOV,
    mod.class.interface.Combat
))

_M.projectile_class = "mod.class.Projectile"

_M.temporary_values_conf.flying = "last"

_M.BASE_UNARMED_DAMAGE = 2

function _M:init(t, no_default)
    self.incomplete = true

    -- Define some basic stats
    self.combat_armor = 0
    self.combat_natural_armor = 0
    self.combat_atk = 0
    self.combat_def = 0
    self.combat_dam = 0
    self.combat_crit = 5
    self.global_speed = 1
    self.movement_speed = 1

    t.base_life = t.base_life or t.max_life

    -- Default regen
    t.qi_regen = t.qi_regen or 0.25
    t.life_regen = t.life_regen or 0.25

    t.money = 0

    t.blindsense = t.blindsense or 0

    t.resists = t.resists or {}
    t.melee_project = t.melee_project or {}

    -- Default melee barehanded damage
    self.combat = { dam=_M.BASE_UNARMED_DAMAGE }

    -- Default body parts
    t.body_parts = t.body_parts or {}
    t.body_parts.skin = t.body_parts.skin or "skin"

    engine.Actor.init(self, t, no_default)
    engine.interface.ActorInventory.init(self, t)
    engine.interface.ActorTemporaryEffects.init(self, t)
    engine.interface.ActorLife.init(self, t)
    engine.interface.ActorProject.init(self, t)
    engine.interface.ActorTalents.init(self, t)
    engine.interface.ActorResource.init(self, t)
    mod.class.interface.ActorStats.init(self, t)
    engine.interface.ActorLevel.init(self, t)
    engine.interface.ActorFOV.init(self, t)
end

function _M:onEntityMerge(a)
    -- Remove stats to make new stats work.  This is necessary for stats on a
    -- derived NPC (like kobold in the example module) to override the base
    -- define_as NPC.
    for i, s in ipairs(_M.stats_def) do
        if a.stats[i] then
            a.stats[s.short_name], a.stats[i] = a.stats[i], nil
        end
    end
end

function _M:resetToFull()
    if self.dead then return end
    self.life = self.max_life
    self.qi = self.max_qi
end

---This function is called as the last step in resolving a new Actor.
---We use it to apply initial stat values.
function _M:resolveLevel()
    engine.interface.ActorLevel.resolveLevel(self)

    self.max_life = math.floor(self.max_life * GameRules:damStatMod(self:getCon()))
    self.max_qi = self.max_qi + self:getMnd() * GameRules.qi_per_mnd
    self:resetToFull()
    self.incomplete = nil
end

function _M:act()
    if not engine.Actor.act(self) then return end

    game:processCrit()

    self.changed = true

    -- Cooldown talents
    self:cooldownTalents()
    -- Regen resources
    self:regenLife()
    self:regenResources()
    -- Compute timed effects
    self:timedEffects()

    -- Handle talents that may have an effect or may need updating each turn
    if not self.dead then
        if self:knowTalent(self.T_DWELLER_IN_DARKNESS) then
            local t = self:getTalentFromId(self.T_DWELLER_IN_DARKNESS)
            t.do_turn(self, t)
        end
        if self:isTalentActive(self.T_MINING_LIGHT) then
            local t = self:getTalentFromId(self.T_MINING_LIGHT)
            t.do_turn(self, t)
        end
        if self:isTalentActive(self.T_CAPACITIVE_APPENDAGE) then
            local t = self:getTalentFromId(self.T_CAPACITIVE_APPENDAGE)
            t.do_turn(self, t)
        end
    end

    if (self:attr("prone") or self:attr("unconscious")) and self.energy.value >= game.energy_to_act then self.energy.value = self.energy.value - game.energy_to_act end

    game.level.map:checkEntity(self.x, self.y, Map.TERRAIN, "on_stand", self)
    game.level.map:checkEntity(self.x, self.y, Map.TERRAIN_CLOUD, "on_stand", self)

    -- Still enough energy to act ?
    if self.energy.value < game.energy_to_act then return false end

    return true
end

function _M:move(x, y, force)
    local moved = false
    local ox, oy = self.x, self.y
    local move_energy = game.energy_to_act * self:movementSpeed()
    local target = game.level.map(x, y, Map.ACTOR)
    if force or self:enoughEnergy(move_energy) then

        -- Never move, but allow attacking.
        if not force and self:attr("never_move") then
            -- Copied from ToME - this asks the collision code to check for attacking
            if not game.level.map:checkAllEntities(x, y, "block_move", self, true) then
                game.logPlayer(self, "You are unable to move!")
            end
            return false
        end

        -- random_move gives a percentage chance for movements to be random,
        -- but only if we're truly moving (not trying to attack).
        --
        -- confused gives a flat chance for movements to be random.
        --
        -- random_move causes running to an unknown map location to abort
        -- early (??? - this seems to be the case, but I've had trouble
        -- figuring out why).  As a favor to the player, disable random movement
        -- while running.
        local do_random_move = false
        if not force and self.x and self.y then
            if self:attr("random_move") and not (target and self:reactionToward(target) < 0) and rng.percent(self.random_move) and not self.running then
                print(("%s: random movement from random_move"):format(self.name))
                do_random_move = true
            elseif self:attr("confused") and rng.percent(self.confused) then
                print(("%s: random movement from confused"):format(self.name))
                do_random_move = true
            end
        end
        if do_random_move then
            local moves = {}
            for k, v in pairs(util.adjacentCoords(self.x, self.y, self.forbid_diagonals)) do
                if self:canMove(v[1], v[2]) then
                    moves[#moves+1] = v
                end
            end
            if #moves > 0 then
                local selected = rng.table(moves)
                x, y = selected[1], selected[2]
            end
        end

        if not force and self:isTalentActive(self.T_GEOMAGNETIC_ORIENTATION) then
            if x ~= ox and y ~= oy then
                game.logPlayer(self, "Your mind rebels at the thought of moving misaligned from the earth's magnetic field.")
                return false
            end
        end

        moved = engine.Actor.move(self, x, y, force)
        if not force and moved and (self.x ~= ox or self.y ~= oy) and not self.did_energy then
            self:useEnergy(game.energy_to_act * self:movementSpeed())
        end
    end
    self.did_energy = nil
    return moved
end

--- Override ActorTemporaryEffects:setEffect to add qi tracking
function _M:setEffect(eff_id, dur, p, silent)
    engine.interface.ActorTemporaryEffects.setEffect(self, eff_id, dur, p, silent)

    if p and p.src then
        Qi.saveSourceInfo(p.src, self:hasEffect(eff_id))
    end
end

--- Override ActorTemporaryEffects:removeAllEffects to add silent, force
function _M:removeAllEffects(silent, force)
    local todel = {}
    for eff, p in pairs(self.tmp) do
        todel[#todel+1] = eff
    end

    while #todel > 0 do
        self:removeEffect(table.remove(todel), silent, force)
    end
end

function _M:resolveSource()
    if self.summoner_gain_exp and self.summoner then
        return self.summoner:resolveSource()
    else
        return self
    end
end

--- Gets this actor's name, formatted for use in a log message.
--- (This is thus somewhat player-centric in its wordings and assumptions.)
function _M:getLogName()
    if self == game.player or (game.level.map.seens(self.x, self.y) and game.player:canSee(self)) then
        return self.name, true
    else
        return "something", false
    end
end

--- Gets this actor's name, formatted for use in a damage or effect source message.
--- (This is thus somewhat player-centric in its wordings and assumptions.)
function _M:getSrcName()
    local name, seen = self:getLogName()

    -- Note that we assume that we're being called from a damage projector or
    -- similar and thus have access to intermediate.  If not, it's harmless.
    local intermediate = Qi.getIntermediate(self)

    local used_intermediate = false
    if intermediate ~= self and intermediate.damage_message_use_name then
        used_intermediate = true
        if seen then
            name = ("%s's %s"):format(name, intermediate.name)
        else
            name = string.a(intermediate.name)
        end
    end

    return name, seen, used_intermediate
end

--- Gets this actor's name, formatted for use in a damage or effect target message.
--- See also getSrcName.
function _M:getTargetName(src, used_intermediate)
    if src == self then
        -- used_intermediate means that we got a message like "Guy's bomb"
        -- instead of "Guy," so "himself" would be ungrammatical.
        return used_intermediate and string.him(self) or string.himself(self)
    else
        return self:getLogName()
    end
end

function _M:tooltip()
    local color = GameUI.tooltipColor
    local delim

    local text = GameUI:tooltipTitle(self:getDisplayString(), self.name)

    -- Basic tooltips
    text:add(true, color.caption, 'Type: ', color.text, tostring(self.type))
    text:add(true, color.caption, 'Level: ', color.text, tostring(self.level))
    text:add(true, color.caption, 'Life: ', color.health, ("%d (%d%%)"):format(self.life, self.life * 100 / self.max_life))

    -- Stats
    delim = {}
    text:add(true, color.caption, 'Stats: ')
    for i, v in ipairs({self:getStr(), self:getSki(), self:getCon(), self:getAgi(), self:getMnd()}) do
        text:merge(delim)
        text:add(color.text, tostring(v))
        delim = { color.caption, ' / ' }
    end

    -- Attack, damage
    delim = nil
    local attack, dam attack, dam = tstring{}, tstring{}
    for combat, combat_mult in self:iterCombat() do
        attack:add(delim, tostring(self:combatAttack(combat)))
        dam:add(delim, string.describe_range(self:combatDamageRange(combat, combat_mult)))

        -- Add damage-on-hit
        local project_dam = tstring{}
        local total_project_dam = 0
        local project_count = 0
        for _, melee_project in ipairs{ combat.melee_project or {}, self.melee_project } do
            for typ, dam in pairs(melee_project) do
                if dam > 0 then
                    local damtype = DamageType:get(typ)
                    project_dam:add('+', damtype.text_color, tostring(dam), color.text)
                    total_project_dam = total_project_dam + dam
                    project_count = project_count + 1
                end
            end
        end
        if project_count > 3 then
            -- A rainbow-colored number would be tacky, so we'll just say it's GOLD damage!  Ooh!
            dam:add('+#GOLD#', tostring(total_project_dam), color.text)
        else
            dam:merge(project_dam)
        end

        delim = ' / '
    end
    if delim then
        text:add(true, color.caption, 'Attack: ', color.text)
        text:merge(attack)
        text:add(true, color.caption, 'Damage: ', color.text)
        text:merge(dam)
    end

    -- Defense, armor
    text:add(true, color.caption, 'Defense: ', color.text, tostring(self:combatDefense()))
    local armor_min, armor_max = self:combatArmorRange()
    text:add(true, color.caption, 'Armor: ', color.text, string.describe_range(armor_min, armor_max))

    -- Temporary effects
    for tid, act in pairs(self.sustain_talents) do
        if act then text:add(true, color.text, ' - ', color.good, self:getTalentFromId(tid).name) end
    end
    for eff_id, p in pairs(self.tmp) do
        text:add(true, color.text, ' - '):merge(GameUI:tempEffectText(self, eff_id))
    end

    if self.desc then text:add(true, true, color.text, self.desc, true) end

    return text
end

function _M:checkAngered(src)
    if game.player:hasEffect(game.player.EFF_CALM_AURA) then
        -- Allow player to maintain Calm Aura even if player is suffering from DoTs
        if self ~= game.player then
            game.player:removeEffect(game.player.EFF_CALM_AURA)
        end
    end
end

function _M:onTakeHit(value, src)
    self:checkAngered(src)

    if self.desperation_threshold and not self:attr("fatigued") and self.life / self.max_life <= self.desperation_threshold then
        -- TODO: Possible improvements / changes:
        -- More than 1 turn, but end as soon as you attack?
        -- Boost move speed as well?  (That would require that it time out based on base, not actor turns.)
        self:setEffect(self.EFF_DESPERATION, 1, {})
    end

    return value
end

function _M:die(src)
    engine.interface.ActorLife.die(self, src)

    self:checkAngered(src)

    -- Gives the killer some exp for the kill
    local killer
    if src and src.resolveSource and src:resolveSource().gainExp then
        killer = src:resolveSource()
        killer:gainExp(self:worthExp(killer))
    end

    -- Cancel First Blessing: Virtue if appropriate
    -- For now, at least, we do not also check src:resolveSource() (e.g., summoned creatures).
    if src:isTalentActive(src.T_BLESSING_VIRTUE) and not src:getTalentFromId(src.T_BLESSING_VIRTUE).canKill(src, self) then
        src:forceUseTalent(src.T_BLESSING_VIRTUE, {ignore_energy=true})
    end

    -- If the killer had focused qi, then try absorbing a technique.
    if src and Qi.isFocused(src) then
        if src:absorbTechnique(self) then
            -- Each qi focus may only be good for one absorption, so forcibly
            -- clear any focused state if appropriate.
            Qi.clearFocus(src)
        end
    end

    -- Remove any remaining temporary effects so that they don't get processed
    -- after death.
    self:removeAllEffects(true, true)

    return true
end

---Updates maximum life for the given changes in level and Con.  The easiest
-- way to avoid roundoff errors is to just recalculate it.
function _M:updateMaxLife(level_change, con_change)
    local function baseLife(level, con)
        return math.floor(self.base_life * GameRules:damScale(level, con))
    end
    self.max_life = self.max_life - baseLife(self.level - level_change, self:getCon() - con_change) + baseLife(self.level, self:getCon())
end

function _M:levelup()
    self:updateMaxLife(1, 0)

    self:incMaxQi(GameRules.qi_per_level)

    -- Heal upon new level.  TODO: Keep doing this?
    self.life = self.max_life
    self.qi = self.max_qi
end

--- Notifies a change of stat value
function _M:onStatChange(stat, v)
    if self.incomplete then return end

    -- TODO: Modify current life / qi as well as max?
    if stat == self.STAT_STR then
        self:checkEncumbrance()
    elseif stat == self.STAT_CON then
        self:updateMaxLife(0, v)
    elseif stat == self.STAT_MND then
        self.max_qi = self.max_qi + v * GameRules.qi_per_mnd
    end
end

function _M:attack(target)
    self:bumpInto(target)
end

function _M:heal(value, src)
    engine.interface.ActorLife.heal(self, value, src)

    -- Friends' healing is green, enemies is red.
    -- Use base reactionToward to ignore EFF_CALM_AURA.
    local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
    if self == game.player or engine.Actor.reactionToward(game.player, self) >= 0 then
        game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, '+'..tostring(math.ceil(value)), {0,255,0})
    else
        game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, '+'..tostring(math.ceil(value)), {255,0,0})
    end
end

function _M:unlearnTalent(t_id, nb)
    if not engine.interface.ActorTalents.unlearnTalent(self, t_id, nb) then return false end

    local t = _M.talents_def[t_id]

    if not self:knowTalent(t_id) and t.mode == "sustained" and self:isTalentActive(t_id) then self:forceUseTalent(t_id, {ignore_energy=true}) end

    return true
end

--- Called before a talent is used
-- Check the actor can cast it
-- @param ab the talent (not the id, the table)
-- @return true to continue, false to stop
function _M:preUseTalent(ab, silent, fake)
    if not self:enoughEnergy() then print("fail energy") return false end

    if ab.mode == "sustained" then
        if ab.sustain_qi and self.max_qi < ab.sustain_qi and not self:isTalentActive(ab.id) then
            if not silent then game.logPlayer(self, "You do not have enough qi to activate %s.", ab.name) end
            return false
        end
    else
        if ab.qi and self:getQi() < ab.qi then
            if not silent then game.logPlayer(self, "You do not have enough qi to use %s.", ab.name) end
            return false
        end
    end

    if not fake and self:attr("confused") and not ab.reliable and (ab.mode ~= "sustained" or not self:isTalentActive(ab.id)) and rng.percent(self.confused) then
        if not silent then game.logSeen(self, "%s is confused and fails to use %s.", self.name:capitalize(), ab.name) end
        self:useEnergy()
        return false
    end

    if not silent then
        self:showTalentMessage(ab)
    end

    if not fake then
        self.last_action = { type = 'talent', talent = ab.id }
    end

    return true
end

function _M:showTalentMessage(ab)
    -- Allow for silent talents
    if ab.message ~= nil then
        if ab.message then
            game.logSeen(self, "%s", self:useTalentMessage(ab) or "")
        end
    elseif ab.mode == "sustained" and not self:isTalentActive(ab.id) then
        game.logSeen(self, "%s activates %s.", self.name:capitalize(), ab.name)
    elseif ab.mode == "sustained" and self:isTalentActive(ab.id) then
        game.logSeen(self, "%s deactivates %s.", self.name:capitalize(), ab.name)
    else
        game.logSeen(self, "%s uses %s.", self.name:capitalize(), ab.name)
    end
end

--- Called before a talent is used
-- Check if it must use a turn, mana, stamina, ...
-- @param ab the talent (not the id, the table)
-- @param ret the return of the talent action
-- @return true to continue, false to stop
function _M:postUseTalent(ab, ret)
    if not ret then return end

    if not ab.no_energy then
        self:useEnergy(game.energy_to_act / (ab.speed or 1))
    end

    if ab.mode == "sustained" then
        if not self:isTalentActive(ab.id) then
            if ab.sustain_qi then
                self.max_qi = self.max_qi - ab.sustain_qi
            end
        else
            if ab.sustain_qi then
                self.max_qi = self.max_qi + ab.sustain_qi
            end
        end
    else
        if ab.qi then
            self:incQi(-ab.qi)
        end
    end

    self.last_action = nil

    return true
end

---Override engine.ActorTalents.getTalentLevel to support talents whose level
-- depends on a stat rather than just talent mastery.
function _M:getTalentLevel(id)
    local level = Talents.getTalentLevel(self, id)

	if type(id) == "table" then
		t, id = id, id.id
	else
		t = _M.talents_def[id]
	end
    if t.stat then level = level * self:getStat(t.stat) / 10 end

    return level
end

--- Return the full description of a talent
function _M:getTalentFullDescription(t)
    local d = tstring{}
    local color = GameUI.tooltipColor

    d:add(color.caption, "Use mode: ", color.use)
    if t.mode == "passive" then d:add("Passive")
    elseif t.mode == "sustained" then d:add("Sustained")
    else d:add("Active")
    end
    d:add(true)

    if t.qi or t.sustain_qi then d:add(color.caption, "Qi cost: ", color.text, ""..(t.qi or t.sustain_qi), true) end

    if self:getTalentRange(t) > 1 then d:add(color.caption, "Range: ", color.text, ""..self:getTalentRange(t), true)
    elseif t.range then d:add(color.caption, "Range: ", color.text, "melee", true)
    else d:add(color.caption, "Range: ", color.text, "personal", true)
    end

    if t.no_energy then d:add(color.caption, "Speed: ", color.text, "instantaneous", true)
    elseif t.speed then d:add(color.caption, "Speed: ", color.text, ("%i%%"):format(t.speed * 100), true)
    end

    if t.cooldown then d:add(color.caption, "Cooldown: ", color.text, ""..t.cooldown, true) end

    -- Hack: Only proficiencies have multiple talent levels (at least for now)
    if t.type[1] == "basic/proficiencies" then
        d:add(color.caption, "Effective proficiency: ", color.text, ("%.1f"):format(self:getTalentLevel(t)))
        if t.stat then
            d:add(' #{italic}#(based on your ', self.stats_def[t.stat].name, ')#{normal}#')
        end
        d:add(true)
    end

    -- Two versions, with and without "Description: " caption.
    --d:add(true, color.caption, "Description: ", true, color.text)
    d:add(true, color.text)
    d:merge(t.info(self, t):toTString())

    return d
end

--- As engine.interface.ActorTalents.talentCallbackOn, but over *all* talents,
--- not just current sustains.
function _M:talentCallbackAllOn(on, ...)
    for tid, _ in pairs(self.talents) do
        local t = self:getTalentFromId(tid)
        if t and t[on] then
            self:callTalent(tid, on, ...)
        end
    end
end

--- How much experience is this actor worth
-- @param target to whom is the exp rewarded
-- @return the experience rewarded
function _M:worthExp(target)
    if not target.level or self.level < target.level - 3 then return 0 end

    local mult = 2
    if self.unique then mult = 6
    elseif self.egoed then mult = 3 end
    return self.level * mult * self.exp_worth
end

--- Gets the total experience that this Actor has acquired.
function _M:totalExp()
    return self:totalExpChart(self.level) + self.exp
end

--- Gets the total experience required to attain the given level.
function _M:totalExpChart(level)
    local result = 0
    for i = 2, level do
        result = result + self:getExpChart(i)
    end
    return result
end

--- Can the actor see the target actor
-- This does not check LOS or such, only the actual ability to see it.<br/>
-- Check for telepathy, invisibility, stealth, ...
function _M:canSee(actor, def, def_pct)
    if not actor then return false, 0 end

    -- Check for stealth. Checks against the target cunning and level
    --[[if actor:attr("stealth") and actor ~= self then
        local def = self.level / 2 + self:getCun(25)
        local hit, chance = self:checkHit(def, actor:attr("stealth") + (actor:attr("inc_stealth") or 0), 0, 100)
        if not hit then
            return false, chance
        end
    end]]

    if def ~= nil then
        return def, def_pct
    else
        return true, 100
    end
end

--- Checks if the actor can see the target actor, *including* checking for
--- LOS, lighting, etc.
function _M:canReallySee(actor)
    -- Non-players currently have no light limitations, so just use FOV.
    if not self.fov then self:doFOV() end
    return self:canSee(actor) and self.fov.actors[actor]
end

--- Can the target be applied some effects
-- @param what a string describing what is being tried
function _M:canBe(what)
    if what == "poison" and rng.percent(100 * (self:attr("poison_immune") or 0)) then return false end
    if what == "cut" and rng.percent(100 * (self:attr("cut_immune") or 0)) then return false end
    if what == "confusion" and rng.percent(100 * (self:attr("confusion_immune") or 0)) then return false end
    if what == "blind" and rng.percent(100 * (self:attr("blind_immune") or 0)) then return false end
    if what == "stun" and rng.percent(100 * (self:attr("stun_immune") or 0)) then return false end
    if what == "fear" and rng.percent(100 * (self:attr("fear_immune") or 0)) then return false end

    -- Note that knockback also covers knockdown.  Note that never_move only
    -- means that an actor can't move of his own will; he's not rooted to the
    -- ground and can still be knocked around or forced back.
    if what == "knockback" and rng.percent(100 * (self:attr("knockback_immune") or 0)) then return false end
    --if what == "knockback" and (rng.percent(100 * (self:attr("knockback_immune") or 0)) or self:attr("never_move")) then return false end

    if what == "instakill" and rng.percent(100 * (self:attr("instakill_immune") or 0)) then return false end

    return true
end

function _M:resetTalentCooldowns()
    for k, v in pairs(self.talents_cd) do
        self.talents_cd[k] = nil
    end
    self.changed = true
end

function _M:getMaxEncumbrance()
    -- For comparison, D20 says a heavy load starts at 67 lbs. for strength 10,
    -- 267 lbs for strength 20.
    --
    -- This number is really chosen to try and make for interesting inventory
    -- decisions, not for any attempt at realism.
    return 30 + self:getStr() * 2 + (self.max_encumber or 0)
end

function _M:getEncumbrance()
    local enc = 0

    -- Compute encumbrance
    for inven_id, inven in pairs(self.inven) do
        for item, o in ipairs(inven) do
            o:forAllStack(function(so) enc = enc + so.encumber end)
        end
    end

    return math.floor(enc)
end

function _M:checkEncumbrance()
    local enc, max = self:getEncumbrance(), self:getMaxEncumbrance()

    -- We are pinned to the ground if we carry too much
    if not self.encumbered and enc > max then
        game.logPlayer(self, "#FF0000#You are carrying too much and are unable to move.#LAST#")
        self.encumbered = self:addTemporaryValue("never_move", 1)

        if self.x and self.y then
            local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
            game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, rng.float(-2.5, -1.5), "+OVERBURDENED!", {255,0,0}, true)
        end
    elseif self.encumbered and enc <= max then
        self:removeTemporaryValue("never_move", self.encumbered)
        self.encumbered = nil
        game.logPlayer(self, "#00FF00#You are no longer overburdened.#LAST#")

        if self.x and self.y then
            local sx, sy = game.level.map:getTileToScreen(self.x, self.y)
            game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, rng.float(-2.5, -1.5), "-OVERBURDENED!", {255,0,0}, true)
        end
    end
end

function _M:onAddObject(o)
    engine.interface.ActorInventory.onAddObject(self, o)
    self:checkEncumbrance()
end

function _M:onRemoveObject(o)
    engine.interface.ActorInventory.onRemoveObject(self, o)
    self:checkEncumbrance()
end

function _M:incMoney(v)
    if self.summoner then self = self.summoner end
    self.money = self.money + v
    if self.money < 0 then self.money = 0 end
    self.changed = true
end

function _M:reactionToward(target)
    local v = engine.Actor.reactionToward(self, target)

    if game.player:hasEffect(game.player.EFF_CALM_AURA) then v = math.max(v, 0) end

    return v
end

--- Attempts to absorb a qi technique.
-- Only Player can absorb techniques, so for most actors, this does nothing.
function _M:absorbTechnique()
    return false
end

local talent_absorb_type = {
    [Talents.T_KICK] = "feet",
    [Talents.T_BASH] = "chest",
    [Talents.T_OFF_HAND_ATTACK] = "lhand"
}
local action_absorb_type = {
    attack = "rhand",
    use_object = "lhand",
}

--- Gets the type of qi technique to be absorbed (an index into Qi.slots_def),
--- based on our last action.
function _M:getAbsorbSlot()
    local src = self
    while src.intermediate do src = src.intermediate end

    if type(src.last_action) == "table" then
        if src.last_action.type == "talent" then
            return talent_absorb_type[src.last_action.talent] or "head"
        else
            return nil
        end
    else
        return action_absorb_type[src.last_action]
    end
end

function _M:getTechniqueCount()
    local nb = 0
    for id, _ in pairs(self.talents) do
        local t = self.talents_def[id]
        if t.type[1]:startsWith("qi techniques/") then nb = nb + 1 end
    end
    return nb
end

--- Gets the maximum number of qi techniques that an actor can learn.
function _M:getTechniqueLimit()
    -- Only Player can dynamically learn techniques.
    return 0
end

