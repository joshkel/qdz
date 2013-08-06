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
require "engine.Actor"
require "engine.Autolevel"
require "engine.interface.ActorTemporaryEffects"
require "engine.interface.ActorLife"
require "engine.interface.ActorProject"
require "engine.interface.ActorLevel"
require "engine.interface.ActorStats"
require "engine.interface.ActorTalents"
require "engine.interface.ActorResource"
require "engine.interface.ActorFOV"
require "engine.interface.ActorInventory"
require "mod.class.interface.Combat"
local Map = require "engine.Map"
local Talents = require "engine.interface.ActorTalents"
local Qi = require "mod.class.interface.Qi"

module(..., package.seeall, class.inherit(
    engine.Actor,
    engine.interface.ActorInventory,
    engine.interface.ActorTemporaryEffects,
    engine.interface.ActorLife,
    engine.interface.ActorProject,
    engine.interface.ActorLevel,
    engine.interface.ActorStats,
    engine.interface.ActorTalents,
    engine.interface.ActorResource,
    engine.interface.ActorFOV,
    mod.class.interface.Combat
))

_M.projectile_class = "mod.class.Projectile"

_M.BASE_UNARMED_DAMAGE = 2

function _M:init(t, no_default)
    -- Define some basic combat stats
    self.combat_armor = 0
    self.plus_attack = 0
    self.plus_defense = 0

    -- Default regen
    t.power_regen = t.power_regen or 0.25
    t.life_regen = t.life_regen or 0.25

    t.money = 0

    -- Default melee barehanded damage
    self.combat = { dam=_M.BASE_UNARMED_DAMAGE }

    engine.Actor.init(self, t, no_default)
    engine.interface.ActorInventory.init(self, t)
    engine.interface.ActorTemporaryEffects.init(self, t)
    engine.interface.ActorLife.init(self, t)
    engine.interface.ActorProject.init(self, t)
    engine.interface.ActorTalents.init(self, t)
    engine.interface.ActorResource.init(self, t)
    engine.interface.ActorStats.init(self, t)
    engine.interface.ActorLevel.init(self, t)
    engine.interface.ActorFOV.init(self, t)
end

function _M:resetToFull()
    if self.dead then return end
    self.life = self.max_life
    self.power = self.max_power
end

function _M:resolveLevel()
    engine.interface.ActorLevel.resolveLevel(self)
    self.max_life = self.max_life + self:getCon()
    self.max_power = self.max_power + self:getMnd()
    self:resetToFull()
end

function _M:act()
    if not engine.Actor.act(self) then return end

    self.changed = true

    -- Cooldown talents
    self:cooldownTalents()
    -- Regen resources
    self:regenLife()
    self:regenResources()
    -- Compute timed effects
    self:timedEffects()

    if not self.dead then
        if self:isTalentActive(self.T_MINING_LIGHT) then
            local t = self:getTalentFromId(self.T_MINING_LIGHT)
            t.do_turn(self, t)
        end
    end

    -- Still enough energy to act ?
    if self.energy.value < game.energy_to_act then return false end

    return true
end

function _M:move(x, y, force)
    local moved = false
    local ox, oy = self.x, self.y
    if force or self:enoughEnergy() then
        moved = engine.Actor.move(self, x, y, force)
        if not force and moved and (self.x ~= ox or self.y ~= oy) and not self.did_energy then self:useEnergy() end
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

function _M:tooltip()
    local text = ([[%s%s
#00ffff#Level: %d
#WHITE#HP: #LIGHT_RED#%d (%d%%)
#WHITE#Stats: #LIGHT_GREEN#%d#WHITE# / #LIGHT_GREEN#%d#WHITE# / #LIGHT_GREEN#%d#WHITE# / #LIGHT_GREEN#%d#WHITE# / #LIGHT_GREEN#%d#WHITE#
#WHITE#Attack: #LIGHT_GREEN#%i#WHITE#
#WHITE#Defense: #LIGHT_GREEN#%i#WHITE#
%s]]):format(
        self:getDisplayString(),
        self.name,
        self.level,
        self.life, self.life * 100 / self.max_life,
        self:getStr(),
        self:getSki(),
        self:getCon(),
        self:getAgi(),
        self:getMnd(),
        self:combatAttack(self.combat),  -- TODO: Find equipped item instead of self.combat?
        self:combatDefense(),
        self.desc and ("\n" .. self.desc .. "\n") or ""
    )

    for tid, act in pairs(self.sustain_talents) do
        if act then text = text .. ("- #LIGHT_GREEN#%s#WHITE#"):format(self:getTalentFromId(tid).name) end
    end
    for eff_id, p in pairs(self.tmp) do
        local e = self.tempeffect_def[eff_id]
        local dur = p.dur + 1
        local color = e.status == "detrimental" and "LIGHT_RED" or "LIGHT_GREEN"
        text = text .. ("- #%s#%s (%d)#WHITE#"):format(color, e.desc, dur)
    end
 
    return text
end

function _M:onTakeHit(value, src)
    return value
end

function _M:die(src)
    engine.interface.ActorLife.die(self, src)

    -- Gives the killer some exp for the kill
    if src and src.gainExp then
        src:gainExp(self:worthExp(src))
    end

    -- If the killer had focused qi, then try absorbing an ability.
    if src and Qi.isFocused(src) then
        if src:absorbAbility(self) then
            -- Each qi focus is only good for one absorption, so forcibly
            -- clear any focused state.
            Qi.clearFocus(src)
        end
    end

    return true
end

function _M:levelup()
    self.max_life = self.max_life + 2

    self:incMaxPower(2)

    -- Heal upon new level
    self.life = self.max_life
    self.power = self.max_power
end

--- Notifies a change of stat value
--- TODO: Also need to change on temporary values and change on negative values??
function _M:onStatChange(stat, v)
    if stat == self.STAT_CON then
        self.max_life = self.max_life + 1
    elseif stat == self.STAT_MND then
        self.max_power = self.max_power + 1
    end
end

function _M:attack(target)
    self:bumpInto(target)
end


--- Called before a talent is used
-- Check the actor can cast it
-- @param ab the talent (not the id, the table)
-- @return true to continue, false to stop
function _M:preUseTalent(ab, silent, fake)
    if not self:enoughEnergy() then print("fail energy") return false end

    if ab.mode == "sustained" then
        if ab.sustain_power and self.max_power < ab.sustain_power and not self:isTalentActive(ab.id) then
            game.logPlayer(self, "You do not have enough power to activate %s.", ab.name)
            return false
        end
    else
        if ab.power and self:getPower() < ab.power then
            game.logPlayer(self, "You do not have enough power to use %s.", ab.name)
            return false
        end
    end

    if not silent then
        -- Allow for silent talents
        if ab.message ~= nil then
            if ab.message then
                game.logSeen(self, "%s", self:useTalentMessage(ab))
            end
        elseif ab.mode == "sustained" and not self:isTalentActive(ab.id) then
            game.logSeen(self, "%s activates %s.", self.name:capitalize(), ab.name)
        elseif ab.mode == "sustained" and self:isTalentActive(ab.id) then
            game.logSeen(self, "%s deactivates %s.", self.name:capitalize(), ab.name)
        else
            game.logSeen(self, "%s uses %s.", self.name:capitalize(), ab.name)
        end
    end

    if not fake then
        self.last_action = { type = 'talent', talent = ab.id }
    end

    return true
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
            if ab.sustain_power then
                self.max_power = self.max_power - ab.sustain_power
            end
        else
            if ab.sustain_power then
                self.max_power = self.max_power + ab.sustain_power
            end
        end
    else
        if ab.power then
            self:incPower(-ab.power)
        end
    end

    self.last_action = nil

    return true
end

--- Return the full description of a talent
-- You may overload it to add more data (like power usage, ...)
function _M:getTalentFullDescription(t)
    local d = tstring{}
    local caption_color = { "color", 0x6f, 0xff, 0x83 }
    local text_color = { "color", 0xff, 0xff, 0xff }
    local power_color = { "color", 0x7f, 0xff, 0xd4 }
    local use_color = { "color", 0x00, 0xff, 0x00 }

    d:add(caption_color, "Use mode: ", use_color)
    if t.mode == "passive" then d:add("Passive")
    elseif t.mode == "sustained" then d:add("Sustained")
    else d:add("Active")
    end
    d:add(true)

    if t.power or t.sustain_power then d:add(caption_color, "Power cost: ", text_color, ""..(t.power or t.sustain_power), true) end

    if self:getTalentRange(t) > 1 then d:add(caption_color, "Range: ", text_color, ""..self:getTalentRange(t), true)
    elseif t.range then d:add(caption_color, "Range: ", text_color, "melee", true)
    else d:add(caption_color, "Range: ", text_color, "personal", true)
    end

    if t.no_energy then d:add(caption_color, "Speed: ", text_color, "instantaneous", true)
    elseif t.speed then d:add(caption_color, "Speed: ", text_color, ("%i%%"):format(t.speed * 100), true)
    end

    if t.cooldown then d:add(caption_color, "Cooldown: ", text_color, ""..t.cooldown, true) end

    d:add(true, caption_color, "Description: ", true, text_color)
    d:merge(t.info(self, t):toTString())

    return d
end

--- As engine.interface.ActorTalents.talentCallbackOn, but over *all* talents,
--- not just current sustaints.
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

--- Can the actor see the target actor
-- This does not check LOS or such, only the actual ability to see it.<br/>
-- Check for telepathy, invisibility, stealth, ...
function _M:canSee(actor, def, def_pct)
    if not actor then return false, 0 end

    -- Check for stealth. Checks against the target cunning and level
    if actor:attr("stealth") and actor ~= self then
        local def = self.level / 2 + self:getCun(25)
        local hit, chance = self:checkHit(def, actor:attr("stealth") + (actor:attr("inc_stealth") or 0), 0, 100)
        if not hit then
            return false, chance
        end
    end

    if def ~= nil then
        return def, def_pct
    else
        return true, 100
    end
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
    if what == "knockback" and rng.percent(100 * (self:attr("knockback_immune") or 0)) then return false end
    if what == "instakill" and rng.percent(100 * (self:attr("instakill_immune") or 0)) then return false end
    return true
end

function _M:getMaxEncumbrance()
    -- FIXME: Different math here
	return math.floor(40 + self:getStr() * 1.8 + (self.max_encumber or 0))
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

function _M:incMoney(v)
    if self.summoner then self = self.summoner end
    self.money = self.money + v
    if self.money < 0 then self.money = 0 end
    self.changed = true
end

--- Attempts to absorb a qi ability.
-- Only Player can absorb abilities, so for most actors, this does nothing.
function _M:absorbAbility()
    return false
end

local talent_absorb_type = {
    [Talents.T_KICK] = "feet",
    [Talents.T_BASH] = "chest",
    [Talents.T_OFF_HAND_ATTACK] = "lhand"
}
local action_absorb_type = {
    attack = "rhand"
}

--- Gets the type of qi ability to be absorbed, based on our last action.
function _M:getAbsorbType()
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

--- Gets a human-readable description of getAbsorbType.
-- I'm not sure where this best belongs.
function _M:getAbsorbTypeDescription()
    return ({
        rhand = "right hand",
        lhand = "left hand",
        chest = "chest",
        feet = "feet",
        head = "head"
    })[self:getAbsorbType()]
end
