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

newTalentType{ type="basic/qi", name = "qi", description = "Basic manipulation of your qi (life energy)" }
newTalentType{ type="basic/combat", name = "combat", description = "Basic combat techniques" }
newTalentType{ type="basic/proficiencies", name = "proficiencies", description = "Proficiencies are various (mostly) mundane skills. Most beings learn these through instinct, training, or practice. As a qi daozei, you can instead be granted them through the techniques you absorb from your foes."}

newTalentType{ type="basic/weapons", name = "weapons", description = "Various weapon techniques." }
newTalentType{ type="basic/items", name = "items", description = "Various item effects." }

newTalentType{ type="qi techniques/right hand", name = "right hand", description = "Qi techniques bound to your right hand. These are typically direct, physical, hand-to-hand attacks.", slot="rhand" }
newTalentType{ type="qi techniques/left hand", name = "left hand", description = "Qi techniques bound to your left hand. These are typically indirect, magical, and / or ranged attacks.", slot="lhand" }
newTalentType{ type="qi techniques/chest", name = "chest", description = "Qi techniques bound to your chest. Chest techniques provide defense, enhancement, and healing.", slot="chest" }
newTalentType{ type="qi techniques/feet", name = "feet", description = "Qi techniques bound to your feet. These relate to movement and mobility.", slot="feet" }
newTalentType{ type="qi techniques/head", name = "head", description = "Qi techniques bound to your head. These may provide perception or knowledge, let you acquire and enhance allies to assist you in combat, or provide other strange and wonderful effects.", slot="head" }

newTalentType{ type="infernal qi/power", name = "power", description = "Infernal qi may offer a shortcut to power, but at a cost." }

--- Formats some flavor text plus rules text.
function flavorText(rules_text, flavor_text)
    if flavor_text then
        return rules_text .. "\n\n#{italic}#" .. flavor_text .. "#{normal}#"
    else
        return rules_text
    end
end

function meleeTalent(f)
    return function(self, t)
        local tg = {type="hit", range=self:getTalentRange(t)}
        local x, y, target = self:getTarget(tg)
        if not x or not y or not target then return nil end
        if core.fov.distance(self.x, self.y, x, y) > 1 then return nil end

        return f(self, t, target, x, y)
    end
end

load("/data/talents/basic.lua")
load("/data/talents/proficiencies.lua")
load("/data/talents/weapons.lua")
load("/data/talents/items.lua")

load("/data/talents/bat.lua")
load("/data/talents/humanoid.lua")
load("/data/talents/infernal.lua")
load("/data/talents/insect.lua")

