Brief Description
=================

Qi Daozei is an Oriental themed fantasy roguelike.  Fight creatures from folklore and legend and absorb their qi to gain new abilities while fleeing the sinister minions of the Empire and its warlocks.

Qi (pronounced “chee”) is the life energy that flows through all beings and throughout the universe. You are a qi daozei – a “qi rogue” – born with the ability to absorb others' life energy. Your kind is feared and persecuted by the Empire, so for years you've hidden your gifts and tried to live a normal life among the citizenry. Now you've been discovered and must fight your way through caverns and wilderness to escape to safety, knowing that the magics and minions of the Empire are quickly closing in...

To absorb an opponent's qi, weaken them in combat until you can kill them with your next hit, then use your "Focus Qi" technique and deliver the deathblow. Doing so will let you absorb their qi and learn a new technique.

Stats 
=====

5 stats:

* Str - damage, encumbrance.  Maybe some sort of combat maneuver bonus?  Associated with the right hand and perhaps fire.
* Ski - attack.  Maybe critical hits?  Associated with the left hand and perhaps water.
* Con - health points, fortitude save.  Maybe health regeneration?  Associated with the chest and perhaps earth.
* Agi - defense, reflex save.  Maybe speed?  Associated with the feet and perhaps wood.
* Mnd - qi points, will save.  Maybe qi regeneration?  Associated with the head and perhaps metal.

Stat magnitudes are based loosely on D20:

* An "average" character starts with 10 in each stat (50 points total).
* An "elite" character (including PCs) start with 61 points, divided as desired (average 12 each).  (A D20 elite array is 15, 14, 13, 12, 10, 8.  Multiplying this by 5/6, since we have one less stat, gives approximately 61.)
* Add a tier for mook / critter characters with average stats of 8 (40 points total).

Each technique absorbed increments one stat by one point. Max stats will therefore depend on number of techniques permitted.  See below.  For comparison, D20 has a practical stat maximum around 36 (before temporary bonuses like rage) and D&D 4e has a rough max of 30.

Ideas for tier names:

* critter / average / elite / boss (ToME)
* terrestrial / celestial / ??? / infernal
* meek / mundane / elite or exalted or enlightened or heroic / mythical
* lead / iron / gold / jade
* local or familial / district or provincial / imperial?
* novice / practitioner / master / grand master

Levels
======

Level cap of 30.  Rationale:

* 20 is standard for D20 but feels small for a roguelike in which more frequent advancement is expected and you end as a wuxia hero.
* 50 is standard for many roguelikes (Adom, ToME, Angband), but QDZ is intended to be a shorter game.
* Is there any Oriental symbology or numerology that would work well here?  Some suggestions from [Wikipedia](http://en.wikipedia.org/wiki/Numbers_in_Chinese_culture):
    * 28 - double prosperity
    * 38 - triple prosperity
    * 88 - double fortune or double joy
    * 99 - long-lasting or eternal
    * 108 - many references in Hinduism, Buddhism, martial arts, and _Water Margin_.  See [Wikipedia](http://en.wikipedia.org/wiki/108_%28number%29).

Experience Curve
----------------

TO DO: How many monsters per level, and how much experience per monster, will depend in part on how many ideas I can come up with for zones and dungeon levels.

Monster Levels
--------------

Should a vampire be shown as level 10 just because he appears at a dungeon depth for a level 10 player? Or should he be shown as level 1 if he's a base vampire?  Probably the former.

Should a rat at a dungeon depth for a level 10 player automatically be level 10?  Probably not, but some level scaling should be good.

How should monsters level up, given that player characters' levels and stats are so dependent on absorbing techniques?  For simplicity of design and balancing, monsters will probably follow the same rules; I can hand-wave it as creatures' native qi or training gives them comparable abilities.

Techniques
==========

Number of techniques known:

* [Soren Johnson says](http://gamasutra.com/view/news/193428/Seven_Deadly_Sins_of_strategy_game_design.php) that 12 is "a good rule-of-thumb for how many different options a player can keep in his or her mind before everything turns to mush."  (His advice is mostly for strategy games; does it apply equally to a roguelike?)
* Multiply by 2.5 or more to allow for passive, triggered, and sustained abilities?  Additional considerations:
    * Situational and out-of-combat abilities wouldn't count against the limit.
    * Allowing weaker active abilities to give passive boosts to other abilities (à la Diablo II's patch 1.10 skill synergy bonuses) would let me further increase this.
    * Usable items and equipment would have to count against this.
* Higher-level ToME characters seem to have 25-30 abilities without it becoming *too* unmanageable.
* Is there any Oriental symbology or numerology that would work well here?  See above.

Try ~1 per level for now, for a final number around 30. TO DO: How quickly should these be learned? Is 1/level too slow? Do I need to enforce any balance of active versus passive / sustained?

Should characters start with a technique, to ease the first couple of kills?  (This may be particularly important for the scholar background, which otherwise seems harder to get off the ground.)

Skill Checks
============

Skill checks and attack versus defense are handled using a [logistic scale](http://en.wikipedia.org/wiki/Logistic_distribution) to provide diminishing returns (similar to a standard distribution / bell curve, but with less dropoff).  When evenly matched, +1 skill gives about a 5% increase to chance of success, with diminishing returns after that.

For attack and defense, following D20, +2 stat gives +1 to attack / defense.

If I switch to exponential health and damage (below), then should I change this to show exponential numbers in attack and defense also?

Health, Damage, and Scaling
===========================

Goal: 2-3 hits (for a combat-focused character) or 3-4 hits (for other characters) to defeat a monster?

Starting hit points should be high enough to allow for small damage effects (like damage over time effects) without them being overpowering.  (For comparison, in D20, losing even 1 hp per turn could hurt a lot at level 1.)

[Following ToME](http://forums.te4.org/viewtopic.php?f=36&t=38632), hit points and damage should scale linearly with level.

D20 does linear scaling, more or less (?), although how it scales damage is non-obvious (increasing plusses on weapons, more iterative attacks at particular breakpoints, extra damage dice from higher-level spells, etc.), and I'm not sure how to easily apply those ideas here.

Alternate idea: Health and damage scale exponentially (so that, e.g., a character 1 level above you always has +5% HP and damage relative to you).

* Str and Con would scale by a percentage (+2 = +5% of _current_ value, after exponential level scaling is applied) to keep their value relative to Ski and Agi.
    * This percentage should perhaps be higher than the ~5% that Ski and Agi give, since those are a chance to completely avoid damage, while these may not affect the number of hits it takes to kill or be killed.
* Str and Con may also need a small flat effect, since percentage may otherwise be unnoticeable at lower levels.
* Big numbers might feel more in genre for wuxia and anime.

Sample implementation: +10% per level, +2 stat = +5% current
* HP for an elite character is 30 * 1.1 ^ (Level - 1) * (1 + (Con - 10) / 2 * .05)

Qi
==

Qi scales linearly with level and Mnd.

This is subject to change.  For example, scaling by Mnd only would help ensure that Mnd and qi limits remain relevant even at the endgame.

Equipment
=========

Undecided.  A character's strength depending on his equipment is in genre for roguelikes (which this is) and D&D (which is an inspiration) but less in genre for wuxia and anime (which is more my setting).  If I come up with some poetic sounding vaguely martial arts names for magic equipment, it'd probably be okay.

If a player character's strength is gear-dependent, is it harder to balance against non-gear-dependent foes?

Further Reading
===============

[ToME "Infinite" Scaling Design](http://forums.te4.org/viewtopic.php?f=36&t=38632)

