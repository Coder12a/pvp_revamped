# pvp_revamped

Introduces new pvp game mechanics such as evasive maneuvers, damage blocking, and weapon throwing. Also, the damage system was overhauled, players now have hit points that do different amount of damage.

# optional dependencies
[sscsm](https://forum.minetest.net/viewtopic.php?t=23504) - Needed for preforming dodge and barrel roll maneuvers.

[3d_armor](https://forum.minetest.net/viewtopic.php?t=4654) - Shields are given a buff such as blocking damage 270 degrees around the player when activated.

# controls

#### movement and dodging

Double tap any of the movement keys to barrel roll. **(Requires sscsm)**

Double tap any movement key + sneak key to dash. **(Requires sscsm)**

Double tap use key to dodge. **(Requires sscsm)**

#### blocking

Using any tool that can damage. Press place *(Right mouse button or double tap)* key to activate the tool block.

Holding down place after activating will maintain the block.

Be careful though tool blocking has a guard pool taking damage reduces it on till the guard breaks and you must re-activate the tool block or risk-taking damage.

#### shield blocking

Same as tool blocking but shields have a bigger guard pool and can cover 270 degrees around the player. **(Requires shields from 3d_armor)**

sneak key + place will block using the shield in the armor inventory. **(Requires shields from 3d_armor)**

#### throwing

To throw a tool hold down either dig or place and then press the drop key to start charging up the toss.

When you are ready to throw release either dig or place.

All tools have different throw speeds, charge times, and damages.

# commands

**/tap_speed** [seconds] Set the double tap sensitivity for dashing, dodging, and rolling. **(Requires sscsm)**

**/tap_speed_reset** [none] Resets the tap sensitivity to 0.15 seconds. **(Requires sscsm)**

**/use_shield** [boolean] If set to true, the shield plate inside your armor inventory will be used to block all incoming damage when place is pressed. **(Requires shields)**

**/move_item** Gives you a movement item. Accepted values are:
- dodge
- dash_left
- dash_up
- dash_right
- dash_down
- dash_all
- roll_left
- roll_up
- roll_right
- roll_down
- roll_all
- all

These items offer a way to still dodge, dash, and roll without the sscsm mod.

**/throw_style** Change how you throw an item. Accepted values are:
- none
- spin
- dip

Thrown items give better damage and distance when charged the longest.

using the /throw_style chat command you can change how you throw items to gain either an advantage or disadvantage.

throw styles:
1. *none* Basic throw. The tool's pitch and yaw stay the same. **(On by default)**
2. *spin* When throwing you give the tool a spin. The rotation has an affect on gravity.
3. *dip* Throwing on dip cause the tool's pitch to rotate with the gravity. dip gives a velocity damage multipliable but is most affected by gravity.

# game mechanics
Explaining the new different gameplay mechanics that affect you as a player.

### damage model
When hitting another player, a ray cast is used to get the absolute position and height.

#### height related damage.
Damage to the:
1. *Head* gives a damage multipliable.
2. *Torso* gives a damage multipliable. **(Also vector related)**
3. *Arm* gives a damage multipliable, and chance to disarm item. **(Also vector related)**
4. *Leg* gives a damage multipliable, and immobilizes player.
5. Kneecaps immobilize the player. **(Slows them down for a short amount of time)**

#### side related damage.
When hitting another player at an angle.

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
Velocity damage requires a full punch. Damage from speed is related to the hitter’s velocity. Hitting the victim on the side or back while they are running will reduce this multiplier. If the victim is running at you and you hit them in the front you will get a perfect damage multiplier.

#### distance related damage.
Damage from range the distance is spilt into three parts by a multipliable:
1. *Maximum* at long distance gives a damage multipliable.
2. *Normal* grey area between max and optimal no multipliable.
3. *Optimal* short distance gives a damage multipliable.

#### projectile
Damage from a thrown tool mostly depend on charge time, the tool itself, and the throw style.

#### dodge
When a player dodges, they are temporary invincible. Any damage done to a dodging player is not accounted for, but the player can not damage anyone during the dodge duration.

#### barrel roll
Same as dodging but the player rolls in a direction.

#### clashing
Any damage from a punch in pvp is put in a queue for a duration. This makes it possible for players to clash, parry, and counter attacks.

1.	*None* clash duration ended before the victim can hit back meaning all damage is applied from the queue.
2.	*Clash* happens when the victim hits back within the duration. Damage gets mitigated, removed, or reversed.
3.	*Parry* when a player parry’s an attack all damage and bonus damages are used to mitigate the attack. This does not harm the aggressor.
4.	*Counter* reverses all damage plus bonus damage to the aggressor. (Must be within counter duration and full punch only)
5. *Hasty guard* when you block immediately after being hit you can block the any damage from any angle, but this has a small-time window to activate. (depends on config or tool settings)

#### takedown
If enabled full punches can only kill a player. Spam punches will only bring the hp to one (half a heart).

### effects

#### disarming
Hitting a player in the arms gives a random chance to cause them to drop whatever item they are holding. The chance to disarm is affected by what item they are holding and the player health. Lesser health means better chance at disarming.

#### immobilizeing
The immobilize effect makes a player move slow. To immobilize a player hit them in the legs or kneecaps.

### maneuvers
Explaining in detail the different evasive maneuvers you can pull off in-game.

#### movement
You have four ground dashes and four aerial dashes, bring a total of eight possible dashes. When performing a dash, the player hops and flies forward or sideways depending on the key press. Dash has a cooldown so use them wisely.

#### dodging
You have one ground dodge and one aerial dodge. bring a short total of two possible dodge. When you perform a dodge, the player is invincible for a duration of time. Dodge has a cooldown, so you must wait before being able to perform another one.

#### rolling
You have four ground barrel rolls and four aerial barrel rolls, bring a total of eight possible barrel rolls. When performing a barrel roll the player is invincible and will roll in a specific direction for a duration.

# config
Change these variables in minetest.conf or all settings.

#### limb height
Any punch directed at or above this height will be headshots.
``` lua
pvp_revamped.head_height = 1.35
```
Any punch directed at or above this height will hit the torso.
``` lua
pvp_revamped.torso_height = 0.75
```
Any punch directed at or above this height will be legshots.
``` lua
pvp_revamped.leg_height = 0.45
```
Any punch directed at or above this height will hit the kneecaps.
``` lua
pvp_revamped.knee_height = 0.375
```

#### duration
Base value for the tool block duration in microseconds.
``` lua
pvp_revamped.block_duration = 100000
```
Total duration for player dodge in microseconds.
``` lua
pvp_revamped.dodge_duration = 350000
```
Total duration for barrel roll in microseconds.
``` lua
pvp_revamped.barrel_roll_duration = 500000
```
This multiplies fleshy subtracted by full_punch_interval by the given value in microseconds. The resulting value is an add-on to the block duration.
``` lua
pvp_revamped.block_duration_mul = 100000
```
Base value for the shield block duration in microseconds.
``` lua
pvp_revamped.shield_duration = 100000
```
armor_use + armor_heal + armor_shield + fleshy multiplied by this value in microseconds. The resulting value is an add-on to the shield block duration.
``` lua
pvp_revamped.shield_duration_mul = 100000
```
In microseconds. Set how long you want damage to sit in the queue.
``` lua
pvp_revamped.clash_duration = 150000
```
In microseconds. Set the time frame where a player can counter a punch.
``` lua
pvp_revamped.counter_duration = 100000
```
Multiples full_punch_interval by this value in seconds.
``` lua
pvp_revamped.block_interval_mul = 0.15
```

#### cooldown
Set how long it takes to perform another dodge. In microseconds.
``` lua
pvp_revamped.dodge_cooldown = 1500000
```
Set how long it takes to perform another barrel roll. In microseconds.
``` lua
pvp_revamped.barrel_roll_cooldown = 5000000
```
Set how long it takes to perform another dash. In microseconds.
``` lua
pvp_revamped.dash_cooldown = 2000000
```
Set how long it takes to perform another aerial dodge. In microseconds.
``` lua
pvp_revamped.dodge_aerial_cooldown = 5000000
```
Set how long it takes to perform another aerial barrel roll. In microseconds.
``` lua
pvp_revamped.barrel_roll_aerial_cooldown = 10000000
```
Set how long it takes to perform another aerial dash. In microseconds.
``` lua
pvp_revamped.dash_aerial_cooldown = 4000000
```

#### damage
Multiplies how much wear an axe does to a shield, also affects the shield’s guard pool.
``` lua
pvp_revamped.shield_axe_dmg_mul =20
```
Damage multiplier for headshots.
``` lua
pvp_revamped.head_dmg_mul = 1.2
```
Damage multiplier for torso shots.
``` lua
pvp_revamped.torso_dmg_mul = 1.0
```
Damage multiplier for arm shots.
``` lua
pvp_revamped.arm_dmg_mul = 0.6
```
Damage multiplier for leg shots.
``` lua
pvp_revamped.leg_dmg_mul = 0.7
```
Damage multiplier for punching a player facing you.
``` lua
pvp_revamped.front_dmg_mul = nil
```
Damage multiplier for punching a player on any side.
``` lua
pvp_revamped.side_dmg_mul = 1.05
```
Damage multiplier for punching a player on the back.
``` lua
pvp_revamped.back_dmg_mul = 1.1
```
Damage multiplier for being above the victim's y position.
``` lua
pvp_revamped.elevated_dmg_mul = 1.1
```
Damage multiplier for having equal y position.
``` lua
pvp_revamped.equal_height_dmg_mul = nil
```
Damage multiplier for being below the victim's y position.
``` lua
pvp_revamped.lower_elevation_dmg_mul = 0.9
```
Damage multiplier for how fast the hitter is moving.
``` lua
pvp_revamped.velocity_dmg_mul = 0.15
```
Damage multiplier when the hitter is within optimal range.
``` lua
pvp_revamped.optimal_distance_dmg_mul = 0.2
```
Damage multiplier when the hitter is at maximum range.
``` lua
pvp_revamped.maximum_distance_dmg_mul = 0.1
```
Damage multiplier for thrown tools.
``` lua
pvp_revamped.projectile_dmg_mul = 0.5
```
Damage multiplier for a thrown tool's velocity.
``` lua
pvp_revamped.projectile_velocity_dmg_mul = 0.01
```
Damage multiplier for velocity of a tool thrown with dip style. Values are x, y, and z separated by spaces.
``` lua
pvp_revamped.projectile_dip_velocity_dmg_mul = "1 2 1"
```
Damage multiplier for how much damage gets mitigated when performing a parry attack.
``` lua
pvp_revamped.parry_dmg_mul = 1.2
```
Damage multiplier when performing a counter.
``` lua
pvp_revamped.counter_dmg_mul = 1.5
```
This is used to divide the range value into two parts. The parts being optimal and maximum range.
``` lua
pvp_revamped.optimal_distance_mul = 0.625
```
If true you would need a full punch in order to kill a player. Spam punches will only bring the hp to one.
``` lua
pvp_revamped.takedown = true
```

#### maneuvers
Set how fast eachh player should dash.
``` lua
pvp_revamped.dash_speed = 9.2
```
Set the barrel roll speed.
``` lua
pvp_revamped.barrel_roll_speed = 1
```

#### blocking
The value is used to multiply tool damage subtracted by full_punch_interval.
``` lua
pvp_revamped.block_pool_mul = 4
```
The value is used to multiply armor use, heal, shield, and fleshy after they are added first.
``` lua
pvp_revamped.shield_pool_mul = 4
```
Used to multiply wear from any tool blocking or shielding.
``` lua
pvp_revamped.block_wear_mul = 9000
```
Base time window to perform a hasty guard.
``` lua
pvp_revamped.hasty_guard_duration = 50000
```
Multiplies by the tool's full_punch_interval, and damage to add on to the duration.
``` lua
pvp_revamped.hasty_guard_mul = 1000
```
Multiplies by the shield's heal, armor_shield, and fleshy to add on to the duration.
``` lua
pvp_revamped.hasty_shield_mul = 1000
```

#### effects
Value is used to decrease the chance of disarming another player.
``` lua
pvp_revamped.disarm_chance_mul = 2
```
Value multiplies damage subtracted by health to set the new walk speed.
``` lua
pvp_revamped.knee_immobilize_mul = 1.5
```
Value multiplies damage subtracted by health to set the new walk speed.
``` lua
pvp_revamped.leg_immobilize_mul = 0.8
```
Multiplies the immobilize duration In microseconds.
``` lua
pvp_revamped.immobilize_mul = 100000
```

#### projectile
This value multiplies full_punch_interval to create the time need to fully throw a tool at max speed and damage.
``` lua
pvp_revamped.projectile_full_throw_mul = 2
```
Reduces both speed and damage when not thrown at full time in microseconds.
``` lua
pvp_revamped.projectile_half_throw_mul = 0.000005
```
Multiplies tool range by this value to create the throw speed.
``` lua
pvp_revamped.projectile_speed_mul = 3
```
Sets the projectile's downward acceleration.
``` lua
pvp_revamped.projectile_gravity = -10
```
Sets how often the projectile would check collision and speed.
``` lua
pvp_revamped.projectile_step = 0.15
```
Set the ray cast collision range in nodes.
``` lua
pvp_revamped.projectile_dist = 5
```
Spin throw style gravity modifier.
``` lua
pvp_revamped.projectile_spinning_gravity_mul = 0.5
```
Dip throw style gravity modifier.
``` lua
pvp_revamped.projectile_dip_gravity_mul = 1.2
```

#### visual
Shield entity position.
``` lua
pvp_revamped.shield_entity_pos = "0 6 0"
```
Shield entity rotate.
``` lua
pvp_revamped.shield_entity_rotate = "-90 180 180"
```
Shield entity scale.
``` lua
pvp_revamped.shield_entity_scale = "0.35 0.35"
```

# api
Tools can define their own values independent of the config.
tool capabilities can work in registered armor as well, but not the other around.

### tool capabilities
``` lua
tool_capabilities = {
    -- Wears both a shield's health and guard pool.
    damage_groups = {shield = 1000},
    -- See head_height in config.
    head_height = 1.35,
    -- See torso_height in config.
    torso_height = 0.75,
    -- See leg_height in config.
    leg_height = 0.45,
    -- See knee_height in config.
    knee_height = 0.375,
    -- See block_duration in config.
    block_duration = 100000,
    -- See disarm_chance_mul in config.
    disarm_chance_mul = 2,
    -- See leg_immobilize_mul in config.
    leg_immobilize_mul = 0.8,
    -- See knee_immobilize_mul in config.
    knee_immobilize_mul = 1.5,
    -- See immobilize_mul in config.
    immobilize_mul = 100000,
    -- See block_duration_mul in config.
    block_duration_mul = 100000,
    -- See block_interval_mul in config.
    block_interval_mul = 0.15,
    -- See block_pool_mul in config.
    block_pool_mul = 4,
    -- See block_wear_mul in config.
    block_wear_mul = 9000,
    -- See shield_axe_dmg_mul in config.
    shield_axe_dmg_mul = 20,
    -- See head_dmg_mul in config.
    head_dmg_mul = 1.2,
    -- See torso_dmg_mul in config.
    torso_dmg_mul = 1.0,
    -- See arm_dmg_mul in config.
    arm_dmg_mul = 0.6,
    -- See leg_dmg_mul in config.
    leg_dmg_mul = 0.7,
    -- See front_dmg_mul in config.
    front_dmg_mul = nil,
    -- See side_dmg_mul in config.
    side_dmg_mul = 1.05,
    -- See back_dmg_mul in config.
    back_dmg_mul = 1.1,
    -- See elevated_dmg_mul in config.
    elevated_dmg_mul = 1.1,
    -- See equal_height_dmg_mul in config.
    equal_height_dmg_mul = nil,
    -- See lower_elevation_dmg_mul in config.
    lower_elevation_dmg_mul = 0.9,
    -- See velocity_dmg_mul in config.
    velocity_dmg_mul = 0.15,
    -- See optimal_distance_dmg_mul in config.
    optimal_distance_dmg_mul = 0.2,
    -- See maximum_distance_dmg_mul in config.
    maximum_distance_dmg_mul = 0.1,
    -- See optimal_distance_mul in config.
    optimal_distance_mul = 0.625,
    -- See projectile_full_throw_mul in config.
    projectile_full_throw_mul = 2,
    -- See projectile_half_throw_mul in config.
    projectile_half_throw_mul = 0.000005,
    -- See projectile_speed_mul in config.
    projectile_speed_mul = 3,
    -- See projectile_gravity in config.
    projectile_gravity = -10,
    -- See projectile_dmg_mul in config.
    projectile_dmg_mul = 0.5,
    -- See projectile_velocity_dmg_mul in config.
    projectile_velocity_dmg_mul = 0.01,
    -- See projectile_step in config.
    projectile_step = 0.15,
    -- See projectile_dist in config.
    projectile_dist = 5,
    -- See projectile_spinning_gravity_mul in config.
    projectile_spinning_gravity_mul = 0.5,
    -- See projectile_dip_gravity_mul in config.
    projectile_dip_gravity_mul = 1.2,
    -- See projectile_dip_velocity_dmg_mul in config.
    projectile_dip_velocity_dmg_mul = {x = 1, y = 2, z = 1},
    -- See parry_dmg_mul in config.
    parry_dmg_mul = 1.2,
    -- See counter_dmg_mul in config.
    counter_dmg_mul = 1.5,
    -- The clash defense multiplier.
    clash_def_mul = 0.5,
    -- See counter_duration in config.
    counter_duration = 100000,
    -- See hasty_guard_duration in config.
    hasty_guard_duration = 50000,
    -- See hasty_guard_mul in config.
    hasty_guard_mul = 1000
}
```

### shield groups only
``` lua
armor:register_armor("test:shield_test", {
    groups = {
        -- See shield_pool_mul in config.
        shield_pool_mul = 4,
        -- See shield_duration in config.
        shield_duration = 100000,
        -- The health of the guard pool when block is activated.
        block_pool = 1960,
        -- Guard pool's max duration in microseconds.
        duration = 100802,
        -- See hasty_guard_duration in config.
        hasty_guard_duration = 50000,
        -- See hasty_shield_mul in config.
        hasty_shield_mul = 1000,
        -- See shield_entity_pos in config.
        shield_entity_pos = {x = 0, y = 6, z = 0},
        -- See shield_entity_rotate in config.
        shield_entity_rotate = {x = -90, y = 180, z = 180},
        -- See shield_entity_scale in config.
        shield_entity_scale = {x = 0.35, y = 0.35}}
})
```
