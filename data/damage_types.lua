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

-- The basic stuff used to damage a grid
setDefaultProjector(function(src, x, y, type, dam)
    local target = game.level.map(x, y, Map.ACTOR)
    if target then
        local flash = game.flash.NEUTRAL
        if target == game.player then flash = game.flash.BAD end
        if src == game.player then flash = game.flash.GOOD end

        game.logSeen(target, flash, "%s hits %s for %s%0.2f %s damage#LAST#.", src.name:capitalize(), target.name, DamageType:get(type).text_color or "#aaaaaa#", dam, DamageType:get(type).name)
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

        game.level.times_dug = (game.level.times_dug or 0) + 1
        if src.talentCallbackAllOn then src:talentCallbackAllOn("on_dig", x, y, feat) end
    end,
}

