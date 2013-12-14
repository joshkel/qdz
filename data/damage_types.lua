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

local GameRules = require "mod.class.GameRules"
local Qi = require "mod.class.interface.Qi"

local function getDamageFlash(src, target)
    if target == game.player then return game.flash.BAD
    elseif src == game.player then return game.flash.GOOD
    else return game.flash.NEUTRAL
    end
end

-- The basic stuff used to damage a grid.
-- Supported values for extra:
-- * silent - if true, suppresses any log message
-- * msg - a function(src, target, dam, dam_type) that displays any appropriate log message
setDefaultProjector(function(src, x, y, type, dam, extra)
    extra = extra or {}
    local target = game.level.map(x, y, Map.ACTOR)
    if not target then return nil end

    local damtype = DamageType:get(type)
    local init_dam = dam
    local adverb, punct
    adverb, punct = "", "."

    -- Handle critical hits.
    -- This may need changing.  E.g., ToME has physicalCrit et al. in
    -- Combat.lua, so it can handle different weapons, backstab, etc.
    if src:isCrit(target) and damtype.can_crit ~= false and extra.can_crit ~= false and not Qi.getIntermediate(src).is_passive then
        -- TODO: Damage type-specific effects (caught on fire, debilitating poison, etc.)
        dam = dam * 1.5
        adverb, punct = "critically ", "!"
        -- TODO: Force-expire the off-balance effect at the end of this action,
        -- instead of waiting for beginning of target's next turn?
    end

    -- Apply armor.
    if type == DamageType.PHYSICAL then
        if Qi.isFocused(src) then
            dam = dam - target:combatArmorRange()
        else    
            dam = dam - target:combatArmor()
        end
        dam = math.max(0, math.round(dam))
    end

    -- Apply resistances.
    if target.resists then
        local sub, mult = target:combatResist(type)
        dam = math.round((dam - sub) * mult)
        dam = math.max(dam, 0)
        if dam ~= init_dam then
            print(("%s resistance reduced %f damage to %i"):format(damtype.name, init_dam, dam))
        end
    end

    -- Display log message.
    extra = extra or {}
    if extra.msg then
        -- TODO: Include critical damage here?  How best to communicate?
        extra.msg(src, target, dam, damtype)
    elseif not extra.silent then
        local src_name, seen, used_intermediate = src:getSrcName()

        local message
        if Qi.getIntermediate(src).is_passive then
            message = ("%s takes %s%i %s damage#LAST#."):format(target:getTargetName():capitalize(), damtype.text_color, dam, damtype.name)
            game.logSeen(target, getDamageFlash(src, target), message)
        else
            message = ("%s %shits %s for %s%i %s damage#LAST#%s"):format(src_name:capitalize(), adverb, target:getTargetName(src, used_intermediate), damtype.text_color, dam, damtype.name, punct)
            game.logSeenAny({src, target}, getDamageFlash(src, target), message)
        end
    end

    -- Apply damage.  Check for kill.  Display flyer message.
    local sx, sy = game.level.map:getTileToScreen(x, y)
    if target:takeHit(dam, src) then
        if src == game.player or target == game.player then
            game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, "Kill!", {255,0,255})
        end
    else
        if src == game.player then
            game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, tostring(-math.ceil(dam)), {0,255,0})
        elseif target == game.player then
            game.flyers:add(sx, sy, 30, (rng.range(0,2)-1) * 0.5, -3, tostring(-math.ceil(dam)), {255,0,0})
        end
    end

    -- Beginning of on-damage talent effects.  Should these be moved to
    -- on_damage functions within talent definitions?

    -- Handle talent: Electrostatic Capture.
    if not target.dead and type == DamageType.LIGHTNING and init_dam > 0 and target:knowTalent(target.T_ELECTROSTATIC_CAPTURE) then
        -- Better formula needed here?  (E.g., should we recompute the effects
        -- of t.resist_lightning_bonus levels of resistance on init_dam?)
        game.logSeen(target, ("%s absorbs a portion of the charge."):format(target.name:capitalize()))
        local charge_power = math.ceil(init_dam / 10)
        local eff = target:hasEffect(target.EFF_CHARGED)
        if not eff then
            target:setEffect(target.EFF_CHARGED, 1, { power=charge_power })
        else
            target.tempeffect_def[target.EFF_CHARGED].add_power(target, eff, charge_power)
        end
    end

    -- Handle talent: Heat Carapace
    if not target.dead and type == DamageType.FIRE and init_dam > 0 and target:knowTalent(target.T_HEAT_CARAPACE) then
        local t = target:getTalentFromId(target.T_HEAT_CARAPACE)
        target:setEffect(target.EFF_HEAT_CARAPACE, t.getDuration(target, t), { power=t.getArmorBonus(target, t) })
    end

    return dam
end)

-- An alternate DamageType projector that does half damage on a reflex save.
-- Should this print any message if an opponent succeeds on a reflex save?
-- Probably not; it's probably too noisy.
--
-- typ is used to look up the base type (or it may already be the base type itself).
local function refHalf(src, x, y, typ, dam, extra)
    local base_type = DamageType:get(typ).base_type or typ
    local target = game.level.map(x, y, Map.ACTOR)
    if target and not src:skillCheck(src:talentPower(src:getSki()), target:refSave()) then
        dam = dam / 2
    end
    return DamageType:get(base_type).projector(src, x, y, base_type, dam, extra)
end

-- A helper for DamageType projectors that applies knockback.
-- Returns a msg function suitable for use in extra.
--
-- dam should have a dam value, distance, and optionally src_x and src_y.
--
-- alt_src_x and alt_src_y, if provided, are used in place of src_x and src_y
-- *if* the knockback's source are the same as the target's x and y.  In other
-- words, these are alternate values that can be used to ensure that the
-- knockback actually moves the targe.
--
-- This function modifies dam by adding a tmp value for tracking targets that
-- have already been hit.
local function damageKnockback(src, target, dam)
    dam.tmp = dam.tmp or {}
    if dam.tmp[target] then return end
    dam.tmp[target] = true

    local seen = { target }
    if not Qi.getIntermediate(src).is_passive then table.insert(seen, src) end

    if target:canBe("knockback") then
        local before_name, before_seen = target:getTargetName()
        local old_x, old_y = target.x, target.y
        local src_x, src_y = dam.src_x or src.x, dam.src_y or src.y
        if src_x == old_x and src_y == old_y and dam.alt_src_x and dam.alt_src_y then
            src_x, src_y = dam.alt_src_x, dam.alt_src_y
        end
        target:knockback(src_x, src_y, dam.distance)
        target:setMoveAnim(old_x, old_y, 8, 4)
        local after_name, after_seen = target:getTargetName()

        table.insert(seen, {x=old_x, y=old_y})

        return function(src, target, dam, dam_type)
            game.logSeenAny(seen, ("%s is knocked back and takes %s%i %s damage#LAST#!"):format((before_seen and before_name or after_name):capitalize(), dam_type.text_color, dam, dam_type.name))
        end
    else
        return function(src, target, dam, dam_type)
            game.logSeenAny(seen, getDamageFlash(src, target), ("%s takes %s%i %s damage#LAST# but stands %s ground!"):format(target:getTargetName():capitalize(), dam_type.text_color, dam, dam_type.name, string.his(target)))
        end
    end
end

-- Special case: A damage type that wraps another damage type (indicated by
-- dam.type and dam.dam) while handling intermediate qi state (see Qi.call).
newDamageType{
    name = "qi call", type = "QI_CALL",
    projector = function(src, x, y, typ, dam)
        return Qi.call(dam, DamageType:get(dam.type).projector, src, x, y, dam.type, dam.dam)
    end
}

newDamageType{
    name = "physical", type = "PHYSICAL",
}

-- Similar to physical; kept separate so that it ignores armor.
-- Should T_BLOOD_SIP's on_bleed be called here instead of from timed_effects.lua?
newDamageType{
    name = "bleeding", type = "BLEEDING",
}

newDamageType{
    name = "fire", type = "FIRE", text_color = "#RED#",
}

newDamageType{
    name = "fire (reflex half)", type = "FIRE_REF_HALF", text_color = "#RED#",
    projector = refHalf, base_type = DamageType.FIRE
}

newDamageType{
    name = "acid", type = "ACID", text_color = "#GREEN#",
}

newDamageType{
    name = "poison", type = "POISON", text_color = "#GREEN#",
}

newDamageType{
    name = "poison gas", type = "POISON_GAS", text_color = "#GREEN#",
    can_crit = false,
    projector = function(src, x, y, typ, dam, extra)
        -- For now, treat poison gas as poison.  A later version may add
        -- special handling for non-breathing creatures.
        return DamageType:get(DamageType.POISON).projector(src, x, y, DamageType.POISON, dam, table.merge(extra or {}, {
            msg=function(src, target, dam, dam_type)
                game.logSeen(target, getDamageFlash(src, target),
                    ("%s takes %s%i %s damage#LAST# from the gas."):format(target:getTargetName():capitalize(), dam_type.text_color, dam, dam_type.name))
            end
        }))
    end
}

newDamageType{
    name = "lighting", type = "LIGHTNING", text_color = "#LIGHT_BLUE#"
}

newDamageType{
    name = "negative qi", type = "NEGATIVE_QI", text_color = "#LIGHT_DARK#",
    projector = function(src, x, y, typ, dam, extra)
        local realdam = DamageType.defaultProjector(src, x, y, typ, dam, extra)
        local target = game.level.map(x, y, Map.ACTOR)
        if target then
            target:incQi(-math.min(realdam / math.pow(GameRules.dam_level_mod, src.level - 1), target:getQi()))
        end
        return realdam
    end
}

newDamageType{
    name = "dig", type = "DIG",
    projector = function(src, x, y, typ, dam)
        local feat = game.level.map(x, y, Map.TERRAIN)
        if not feat or not feat.dig then return end

        local newfeat_name, newfeat, silence = feat.dig, nil, false
        if type(feat.dig) == "function" then newfeat_name, newfeat, silence = feat.dig(src, x, y, feat) end
        game.level.map(x, y, Map.TERRAIN, newfeat or game.zone.grid_list[newfeat_name])
        if not silence then
            game.logSeen({x=x,y=y}, "The %s turns into %s.", feat.name, (newfeat or game.zone.grid_list[newfeat_name]).name)
        end

        if src.talentCallbackAllOn then src:talentCallbackAllOn("on_dig", x, y, feat) end
    end,
}

-- Physical damage plus knockback.
-- dam should be a table containing elements dam and distance et al.; see damageKnockback.
newDamageType{
    name = "physical knockback", type = "PHYSICAL_KNOCKBACK",
    projector = function(src, x, y, typ, dam, extra)
        local target = game.level.map(x, y, Map.ACTOR)
        if not target then return end

        local msg = damageKnockback(src, target, dam)
        if not msg then return end
 
        return DamageType:get(DamageType.PHYSICAL).projector(src, target.x, target.y, DamageType.PHYSICAL, dam.dam, table.merge(extra or {}, {msg=msg}) )
    end,
}

-- Physical damage plus poison.  dam should be a table containing these elements:
-- - dam - immediate damage
-- - power - damage per turn of the poison effect
-- - duration - optional duration of the poison effect
newDamageType{
    name = "physical poison", type = "PHYSICAL_POISON",
    projector = function(src, x, y, typ, dam, extra)
        local result = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam.dam, extra)
        if result ~= 0 then
            local target = game.level.map(x, y, Map.ACTOR)
            if not target or target.dead then return result end   -- I don't think checking target.dead is necessary

            if not target:canBe("poison") then
                game.logSeen(target, "%s resists the poison.", target.name:capitalize())
            else
                target:setEffect(target.EFF_POISON, dam.duration or 5, {src=src, power=dam.power})
            end
        end
        return result
    end
}

-- Physical damage plus poison.  dam should be a table containing these elements:
-- - dam - immediate damage
-- - power - damage per turn of the bleeding effect (as a multiple of dam)
-- - duration - optional duration of the bleeding effect
newDamageType{
    name = "physical bleeding", type = "PHYSICAL_BLEEDING",
    projector = function(src, x, y, typ, dam, extra)
        local result = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam.dam, extra)
        if result ~= 0 then
            local target = game.level.map(x, y, Map.ACTOR)
            if not target or target.dead then return result end   -- I don't think checking target.dead is necessary

            if not target:canBe("cut") then
                -- Need a message here?  Nothing seems appropriate.
                --game.logSeen(target, "%s is not seriously injured.", target.name:capitalize())
            else
                target:setEffect(target.EFF_BLEEDING, dam.duration or 5, {src=src, power=math.ceil(result * dam.power)})
            end
        end
        return result
    end
}

-- Explosion is fire + physical + knockback, reflex half.
-- dam should be a table containing elements dam and distance et al.; see damageKnockback.
newDamageType{
    name = "explosion", type = "EXPLOSION",
    projector = function(src, x, y, typ, dam, extra)
        -- TODO: Damage items / environment
        local target = game.level.map(x, y, Map.ACTOR)
        if not target then return end

        local msg = damageKnockback(src, target, dam)
        if not msg then return end
 
        local result = DamageType:get(DamageType.FIRE_REF_HALF).projector(src, target.x, target.y, DamageType.FIRE_REF_HALF, dam.dam / 2, extra)
        if not target.dead then
            result = result + refHalf(src, target.x, target.y, DamageType.PHYSICAL, dam.dam / 2, table.merge(extra or {}, {msg=msg}))
        end
        return result
    end,
}

-- Assign default colors to any DamageTypes lacking an explicit color.
for id, dam in ipairs(DamageType.dam_def) do
    if not dam.text_color then
        dam.text_color = "#aaaaaa#"
        dam.color = dam.color or { r=0xaa, g=0xaa, b=0xaa }
    end
end

