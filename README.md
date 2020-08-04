# pvp_revamped

New pvp game mechanics are introduced such as evasive maneuvers, damage blocking, and weapon throwing. Also, the damage system was overhauled, players now have hit points that do different amount of damage.

# optional dependencies
[sscsm](https://forum.minetest.net/viewtopic.php?t=23504) - Needed to preform dodging and barrel rolling.

[3d_armor](https://forum.minetest.net/viewtopic.php?t=4654) - Shields are given a buff such as blocking damage 180 degrees around the player when activated.

# controls

#### movement and dodging controls

Double tap any of the movement keys to barrel roll. **(Requires sscsm)**

Double tap any movement key + sneak key to dash. **(Requires sscsm)**

Double tap use key to dodge. **(Requires sscsm)**

#### blocking

Using any tool that can damage. Press RMB *(Right mouse button or double tap)* key to activate the tool block.

Holding down the RMB after activating will maintain the block.

sneak key + RMB will block using the shield in the armor inventory. **(Requires shields from 3d_armor)**

#### throwing

To throw a tool hold down either LMB or RMB then press the drop key to start charging up the toss.

When you are ready to throw release LMB or RMB.

All tools have different throw speeds, charge times, and damages.

# commands
**/tap_speed** [seconds] Set the double tap sensitivity for dashing and dodging. **(Requires sscsm)**

**/tap_speed_reset** [none] Resets the tap sensitivity to 0.15 seconds. **(Requires sscsm)**

**/use_shield** [boolean] If set to true, the shield plate placed in the armor inventory will be used to block all incoming damage when block key is pressed.

**/throw_style** Change how you throw an item. Accepted values are [none|spin|dip]

Thrown items give better damage and distance when charged the longest.

using the /throw_style chat command you can change how you throw items to give both a advantage and disadvantage.

throw styles:
1. *none* Basic throw. The tool's pitch and yaw stay the same. **(On by default)**
2. *spin* When throwing you give the tool a spin. The rotation has an affect gravity.
3. *dip* Throwing on dip cause the tool's pitch to rotate with gravity. Advantage dip gives a velocity damage multipliable. Disadvantage dip is most affected by gravity.

# game mechanics

### damage model
When hitting another player, a ray cast is used to get the absolute position and height.

#### height related damage.
Damage to the:
1. *Head* gives a damage multipliable.
2. *Torso* gives a damage multipliable. **(Also vector related)**
3. *Arm* gives a damage multipliable, and chance to disarm item. **(Also vector related)**
4. *Leg* gives a damage multipliable, and staggers player.
5. Kneecaps stagger the player. **(Slows them down for a short amount of time)**

#### side related damage.
When hitting another player an angle.

Damage from the:
1. *Front* gives a damage multipliable. **(Off by default)**
2. *Left* or right gives a damage multipliable.
3. *Back* side gives a damage multipliable.

#### elevation related damage.
This is related to the player's y position not the pitch or yaw.

Damage from:
1. *Above* gives a damage multipliable.
2. *Equal* levels give a damage multipliable. **(Off by default)**
3. *Below* gives a damage multipliable.

#### velocity related damage.
Damage from speed related on all three-position axis.

#### distance related damage.
Damage from range the distance is spilt into three parts by a multipliable:
1. *Maximum* at long distance gives a damage multipliable.
2. *Normal* grey area between max and optimal no multipliable.
3. *Optimal* short distance gives a damage multipliable.

#### projectile
Damage from a thrown tool mostly depend on charge time, the tool itself, and the throw style.

#### dodge
When a player Dodges, they are temporary invincible. Any damage is not accounted for.

#### barrel roll
Same as dodging but the player rolls in a direction.

#### clashing
Any damage from a punch in pvp is put in a queue for a duration. This makes it possible for players to clash, parry, and counter attacks.

1.	*None* clash duration ended before the victim can hit back meaning all damage is applied from the queue.
2.	*Clash* happens when the victim hits back within the duration. Damage gets mitigated, removed, or reversed.
3.	*Parry* when a player parry’s an attack all damage and bonus damages are used to mitigate the attack. This does not harm the aggressor.
4.	*Counter* reverses all damage plus bonus damage to the aggressor. (Must be within counter duration and full punch only)
