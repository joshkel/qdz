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

newTalentType{ type="basic/qi", name = "qi", description = "Basic manipulation of your qi (life energy)" }
newTalentType{ type="basic/combat", name = "combat", description = "Basic combat techniques" }
newTalentType{ type="basic/proficiencies", name = "proficiencies", description = "Proficiencies are various (mostly) mundane skills. Most beings learn these through instinct, training, or practice. As a qi dao zei, you can instead be granted them through the abilities you absorb from your foes."}

newTalentType{ type="qi abilities/right hand", name = "right hand", description = "Qi abilities bound to your right hand. These are typically direct, physical, hand-to-hand attacks." }
newTalentType{ type="qi abilities/left hand", name = "left hand", description = "Qi abilities bound to your left hand. These are typically indirect, magical, and / or ranged attacks." }
newTalentType{ type="qi abilities/chest", name = "chest", description = "Qi abilities bound to your chest. Chest abilities provide defense, enhancement, and healing." }
newTalentType{ type="qi abilities/feet", name = "feet", description = "Qi abilities bound to your feet. These relate to movement and mobility." }
newTalentType{ type="qi abilities/head", name = "head", description = "Qi abilities bound to your head. These may provide perception or knowledge, let you acquire and enhance allies to assist you in combat, or provide other strange and wonderful effects." }

--- Formats some flavor text plus rules text.
function flavorText(rules_text, flavor_text)
    if flavor_text then
        return rules_text .. "\n\n#{italic}#" .. flavor_text .. "#{normal}#"
    else
        return rules_text
    end
end

load("/data/talents/basic.lua")
load("/data/talents/proficiencies.lua")
load("/data/talents/humanoid.lua")

