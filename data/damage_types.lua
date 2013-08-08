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

local Qi = require "mod.class.interface.Qi"

local function getDamageFlash(src, target)
    if target == game.player then return game.flash.BAD
    elseif src == game.player then return game.flash.GOOD
    else return game.flash.NEUTRAL
    end
end

-- The basic stuff used to damage a grid
setDefaultProjector(function(src, x, y, type, dam, extra)
    local target = game.level.map(x, y, Map.ACTOR)
    if target then
        if not extra or not extra.silent then
            game.logSeen(target, getDamageFlash(src, target), "%s hits %s for %s%i %s damage#LAST#.", src.name:capitalize(), target.name, DamageType:get(type).text_color or "#aaaaaa#", dam, DamageType:get(type).name)
        end

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
        return dam
    end
    return 0
end)

newDamageType{
    name = "physical", type = "PHYSICAL",
}

newDamageType{
    name = "acid", type = "ACID", text_color = "#GREEN#",
}

newDamageType{
    name = "poison", type = "POISON", text_color = "#GREEN#"
}

newDamageType{
    name = "poison gas", type = "POISON_GAS", text_color = "#GREEN#"
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

-- Physical damage plus knockback. dam should be a table containing elements dam and distance.
newDamageType{
    name = "physical knockback", type = "PHYSICAL_KNOCKBACK",
    projector = function(src, x, y, typ, dam)
        local target = game.level.map(x, y, Map.ACTOR)
        if not target then return end

        if target:canBe("knockback") then
            local old_x, old_y = target.x, target.y
            target:knockback(src.x, src.y, dam.distance)
            target:setMoveAnim(old_x, old_y, 8, 5)

            game.logAnySeen({{x=old_x, y=old_y}, target}, getDamageFlash(src, target), "%s is knocked back and takes %s%i %s damage#LAST#!",
                target.name:capitalize(), DamageType:get(DamageType.PHYSICAL).text_color or "#aaaaaa#", dam.dam, DamageType:get(DamageType.PHYSICAL).name)
        else
            game.logSeen(target, getDamageFlash(src, target), "%s takes %s%i %s damage#LAST# but stands its ground!",
                target.name:capitalize(), DamageType:get(DamageType.PHYSICAL).text_color or "#aaaaaa#", dam.dam, DamageType:get(DamageType.PHYSICAL).name)
        end
 
        return DamageType:get(DamageType.PHYSICAL).projector(src, target.x, target.y, DamageType.PHYSICAL, dam.dam, {silent=true} )
    end,
}

-- Physical damage plus poison.  dam should be a table containing these elements:
-- - dam - immediate damage
-- - power - damage per turn of the poison effect
-- - duration - optional duration of the poison effect
newDamageType{
    name = "physical poison", type = "PHYSICAL_POISON",
    projector = function(src, x, y, typ, dam)
        local result = DamageType:get(DamageType.PHYSICAL).projector(src, x, y, DamageType.PHYSICAL, dam.dam)
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
