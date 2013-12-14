Intermediate effects
====================

Tracking of intermediate effects (so that "focused qi" state can be imbued onto
effects and projectiles even after it expires on the player, and so that we can
give more detailed log messages) is non-trivial.  See Qi.lua.

Actor Attributes
================

Some of the more interesting attributes:

* force_crit - The next attack this actor performs is an automatic critical.
* take_crit - The next attack against this actor is an automatic critical.
* never_move - Actor can't move of his own will but isn't actually rooted to the ground.
