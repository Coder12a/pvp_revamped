pvp_revamped.config = {}
pvp_revamped.config.head_height = tonumber(minetest.settings:get("pvp_revamped.head_height")) or 1.35
pvp_revamped.config.torso_height = tonumber(minetest.settings:get("pvp_revamped.torso_height")) or 0.75
pvp_revamped.config.leg_height = tonumber(minetest.settings:get("pvp_revamped.leg_height")) or 0.45
pvp_revamped.config.knee_height = tonumber(minetest.settings:get("pvp_revamped.knee_height")) or 0.375
pvp_revamped.config.block_duration = tonumber(minetest.settings:get("pvp_revamped.block_duration")) or 100000
pvp_revamped.config.dodge_duration = tonumber(minetest.settings:get("pvp_revamped.dodge_duration"))  or 350000
pvp_revamped.config.barrel_roll_duration = tonumber(minetest.settings:get("pvp_revamped.barrel_roll_duration"))  or 500000
pvp_revamped.config.dodge_cooldown = tonumber(minetest.settings:get("pvp_revamped.dodge_cooldown"))  or 1500000
pvp_revamped.config.barrel_roll_cooldown = tonumber(minetest.settings:get("pvp_revamped.barrel_roll_cooldown"))  or 5000000
pvp_revamped.config.dash_cooldown = tonumber(minetest.settings:get("pvp_revamped.dash_cooldown"))  or 2000000
pvp_revamped.config.dodge_aerial_cooldown = tonumber(minetest.settings:get("pvp_revamped.dodge_aerial_cooldown"))  or 5000000
pvp_revamped.config.barrel_roll_aerial_cooldown = tonumber(minetest.settings:get("pvp_revamped.barrel_roll_aerial_cooldown"))  or 10000000
pvp_revamped.config.dash_aerial_cooldown = tonumber(minetest.settings:get("pvp_revamped.dash_aerial_cooldown"))  or 4000000
pvp_revamped.config.dash_speed = tonumber(minetest.settings:get("pvp_revamped.dash_speed")) or 9.2
pvp_revamped.config.barrel_roll_speed = tonumber(minetest.settings:get("pvp_revamped.barrel_roll_speed")) or 1
pvp_revamped.config.disarm_chance_mul = tonumber(minetest.settings:get("pvp_revamped.disarm_chance_mul")) or 2
pvp_revamped.config.leg_stagger_mul = tonumber(minetest.settings:get("pvp_revamped.leg_stagger_mul")) or 0.8
pvp_revamped.config.knee_stagger_mul = tonumber(minetest.settings:get("pvp_revamped.knee_stagger_mul")) or 1.5
pvp_revamped.config.stagger_mul = tonumber(minetest.settings:get("pvp_revamped.stagger_mul")) or 100000
pvp_revamped.config.block_duration_mul = tonumber(minetest.settings:get("pvp_revamped.block_duration_mul")) or 100000
pvp_revamped.config.block_interval_mul = tonumber(minetest.settings:get("pvp_revamped.block_interval_mul")) or 0.15
pvp_revamped.config.block_pool_mul = tonumber(minetest.settings:get("pvp_revamped.block_pool_mul")) or 2
pvp_revamped.config.shield_duration = tonumber(minetest.settings:get("pvp_revamped.shield_duration")) or 100000
pvp_revamped.config.shield_duration_mul = tonumber(minetest.settings:get("pvp_revamped.shield_duration_mul")) or 100000
pvp_revamped.config.shield_pool_mul = tonumber(minetest.settings:get("pvp_revamped.shield_pool_mul")) or 4
pvp_revamped.config.block_wear_mul = tonumber(minetest.settings:get("pvp_revamped.block_wear_mul")) or 9000
pvp_revamped.config.shield_axe_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.shield_axe_dmg_mul")) or 20
pvp_revamped.config.head_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.head_dmg_mul")) or 1.2
pvp_revamped.config.torso_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.torso_dmg_mul")) or 1.0
pvp_revamped.config.arm_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.arm_dmg_mul")) or 0.6
pvp_revamped.config.leg_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.leg_dmg_mul")) or 0.7
pvp_revamped.config.front_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.front_dmg_mul")) or nil
pvp_revamped.config.side_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.side_dmg_mul")) or 1.05
pvp_revamped.config.back_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.back_dmg_mul")) or 1.1
pvp_revamped.config.elevated_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.elevated_dmg_mul")) or 1.5
pvp_revamped.config.equal_height_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.equal_height_dmg_mul")) or nil
pvp_revamped.config.lower_elevation_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.lower_elevation_dmg_mul")) or 0.9
pvp_revamped.config.velocity_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.velocity_dmg_mul")) or 0.15
pvp_revamped.config.optimal_distance_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.optimal_distance_dmg_mul")) or 0.2
pvp_revamped.config.maximum_distance_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.maximum_distance_dmg_mul")) or 0.1
pvp_revamped.config.takedown = minetest.settings:get_bool("pvp_revamped.takedown")
pvp_revamped.config.optimal_distance_mul = tonumber(minetest.settings:get("pvp_revamped.optimal_distance_mul")) or 0.625
pvp_revamped.config.projectile_full_throw_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_full_throw_mul")) or 2
pvp_revamped.config.projectile_half_throw_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_half_throw_mul")) or 0.000005
pvp_revamped.config.projectile_speed_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_speed_mul")) or 3
pvp_revamped.config.projectile_gravity = tonumber(minetest.settings:get("pvp_revamped.projectile_gravity")) or -10
pvp_revamped.config.projectile_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_dmg_mul")) or 0.5
pvp_revamped.config.projectile_velocity_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_velocity_dmg_mul")) or 0.01
pvp_revamped.config.projectile_step = tonumber(minetest.settings:get("pvp_revamped.projectile_step")) or 0.15
pvp_revamped.config.projectile_dist = tonumber(minetest.settings:get("pvp_revamped.projectile_dist")) or 5
pvp_revamped.config.projectile_spinning_gravity_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_spinning_gravity_mul")) or 0.5
pvp_revamped.config.projectile_dip_gravity_mul = tonumber(minetest.settings:get("pvp_revamped.projectile_dip_gravity_mul")) or 1.2
pvp_revamped.config.parry_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.parry_dmg_mul")) or 1.2
pvp_revamped.config.counter_dmg_mul = tonumber(minetest.settings:get("pvp_revamped.counter_dmg_mul")) or 1.5
pvp_revamped.config.clash_duration = tonumber(minetest.settings:get("pvp_revamped.clash_duration")) or 150000
pvp_revamped.config.counter_duration = tonumber(minetest.settings:get("pvp_revamped.counter_duration")) or 100000
pvp_revamped.config.hasty_guard_duration = tonumber(minetest.settings:get("pvp_revamped.hasty_guard_duration")) or 50000
pvp_revamped.config.hasty_guard_mul = tonumber(minetest.settings:get("pvp_revamped.hasty_guard_mul")) or 1000
pvp_revamped.config.hasty_shield_mul = tonumber(minetest.settings:get("pvp_revamped.hasty_shield_mul")) or 1000

local function split(string, def)
    local settings = minetest.settings:get(string)
    local xyz = settings or def

    if xyz and type(xyz) == "string" then
        xyz = settings:split(" ")
    end

    return xyz
end

local xyz = split("pvp_revamped.projectile_dip_velocity_dmg_mul", {1, 2, 1})
pvp_revamped.config.projectile_dip_velocity_dmg_mul = {x = tonumber(xyz[1]), y = tonumber(xyz[2]), z = tonumber(xyz[3])}

xyz = split("pvp_revamped.shield_entity_pos", {0, 6, 0})
pvp_revamped.config.shield_entity_pos = {x = tonumber(xyz[1]), y = tonumber(xyz[2]), z = tonumber(xyz[3])}

xyz = split("pvp_revamped.shield_entity_rotate", {-90, 180, 180})
pvp_revamped.config.shield_entity_rotate = {x = tonumber(xyz[1]), y = tonumber(xyz[2]), z = tonumber(xyz[3])}

xyz = split("pvp_revamped.shield_entity_scale", {0.35, 0.35})
pvp_revamped.config.shield_entity_scale = {x = tonumber(xyz[1]), y = tonumber(xyz[2]), z = tonumber(xyz[3])}

if pvp_revamped.config.takedown == nil then
    pvp_revamped.config.takedown = true
end
