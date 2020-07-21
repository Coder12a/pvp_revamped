local head_height = 1.2
local torso_height = 0.75
local block_duration = 100000
local block_duration_mul = 100000
local block_interval_mul = 0.15
local block_pool_mul = 2
local block_dmg_mul = 50
local head_dmg_mul = 1.2
local torso_dmg_mul = 1.0
local arm_dmg_mul = 0.9
local leg_dmg_mul = 0.8
local front_dmg_mul = nil
local side_dmg_mul = 1.05
local back_dmg_mul = 1.1
local elevated_dmg_mul = 1.5
local equal_height_dmg_mul = nil
local lower_elevation_dmg_mul = 0.9
local velocity_dmg_mul = 0.15
local optimal_distance_dmg_mul = 0.2
local maximum_distance_dmg_mul = 0.1
local optimal_distance_mul = 0.5
local players_blocking = {}
local players_dodging = {}
local players_dashing = {}

local hit_points = {{x = 0.3, y = 1.2, z = 0, part = 1}, 
        {x = 0, y = 1.2, z = 0, part = 0}, 
        {x = -0.3, y = 1.2, z = 0, part = 1}}

local registered_tools = minetest.registered_tools
local raycast = minetest.raycast
local get_us_time = minetest.get_us_time
local add = vector.add
local multiply = vector.multiply
local subtract = vector.subtract
local distance = vector.distance
local cos = math.cos
local sin = math.sin
local abs = math.abs
local atan = math.atan
local pi = math.pi

minetest.register_on_mods_loaded(function()
    for k, v in pairs(registered_tools) do
        if v.tool_capabilities and v.tool_capabilities.damage_groups.fleshy and v.tool_capabilities.full_punch_interval then
            
            local tool_capabilities = v.tool_capabilities
            local full_punch_interval = tool_capabilities.full_punch_interval
            local punch_number = abs(tool_capabilities.damage_groups.fleshy - full_punch_interval)
            local block_pool = punch_number * block_pool_mul
            local full_block_interval = (full_punch_interval * block_interval_mul) * 1000000
            local duration = block_duration + (punch_number * block_duration_mul)
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place

            if block_pool > 0 then
                -- Allow the tool to block damage.
                local block_action = function(itemstack, user, pointed_thing)
                    local time = get_us_time()
                    local name = user:get_player_name()
                    local data = players_blocking[name]

                    -- Prevent spam blocking.
                    if not data or time - data.time > full_block_interval then
                        players_blocking[user:get_player_name()] = {pool = block_pool, time = time, duration = duration}
                    end
                end

                minetest.override_item(k, {on_secondary_use = function(itemstack, user, pointed_thing)
                    block_action(itemstack, user, pointed_thing)
                    return old_on_secondary_use(itemstack, user, pointed_thing)
                end, on_place = function(itemstack, placer, pointed_thing)
                    block_action(itemstack, placer, pointed_thing)
                    return old_on_place(itemstack, placer, pointed_thing)
                end})

                registered_tools[k] = v
            end
        end
    end
end)

-- Clear up memory if the player leaves.
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    players_blocking[name] = nil
    players_dodging[name] = nil
    players_dashing[name] = nil
end)

-- Do the damage calculations when the player gets hit.
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local pos1 = hitter:get_pos()
    local pos2 = player:get_pos()
    local name = player:get_player_name()
    local hitter_pos = {x = pos1.x, y = pos1.y, z = pos1.z}
    local item = registered_tools[hitter:get_wielded_item():get_name()]
    local range = 4
    local yaw = player:get_look_horizontal()
    local front
    local full_punch

    -- Get whether this was a full punch.
    if tool_capabilities and time_from_last_punch >= tool_capabilities.full_punch_interval then
        full_punch = true
    end

    -- May remove.
    if item and item.alt_range then
        range = item.alt_range
    elseif item and item.range then
        range = item.range
    end
    
    -- Raise the position to eye height.
    hitter_pos.y = hitter_pos.y + hitter:get_properties().eye_height
    
    -- Get the second position from the direction of the hitter.
    local _dir = hitter:get_look_dir()
    local hit_pos1 = add(hitter_pos, _dir)
    local hit_pos2 = add(hit_pos1, multiply(_dir, range))

    local ray = raycast(hit_pos1, hit_pos2):next()

    if ray then
        local hit_point = ray.intersection_point
        local newpos = subtract(hit_point, pos2)
        local y1 = hit_point.y
        local y2 = pos2.y

        if head_height and head_dmg_mul and y1 > y2 + head_height then
            -- If the player was hit in the head add extra damage.
            damage = damage * head_dmg_mul
        elseif torso_height and y1 > y2 + torso_height then
            -- Find if the player was hit in the torso or arm.
            local near_part = 0
            local past_distance = -1

            for _, point in pairs(hit_points) do
                local x = point.x
                local y = point.y
                local z = point.z
                local co = cos(yaw)
                local si = sin(yaw)
                local re_x = co * x - si * z
                local re_z = si * x + co * z
                local dist = distance(newpos, {x = re_x, y = y, z = re_z})
                if dist < past_distance or past_distance == -1 then
                    past_distance = dist
                    near_part = point.part
                end
            end

            if arm_dmg_mul and near_part == 1 then
                -- Hit in the arm.
                damage = damage * arm_dmg_mul
            elseif torso_dmg_mul then
                -- Hit in the torso.
                damage = damage * torso_dmg_mul
            end
        elseif leg_dmg_mul then
            -- Hit in the leg.
            damage = damage * leg_dmg_mul
        end

        local dist = distance(hitter_pos, pos2)
        local optimal_range = range * optimal_distance_mul
        local dist_rounded = dist + 0.5 - (dist + 0.5) % 1
        
        -- Add or remove damage based on the distance.
        -- Full punches are not affected by maximum distance.
        if not full_punch and optimal_distance_mul and maximum_distance_dmg_mul and dist_rounded > optimal_range then
            damage = damage - range * maximum_distance_dmg_mul
        elseif optimal_distance_mul and optimal_distance_dmg_mul and dist_rounded < optimal_range then
            damage = damage + optimal_range - dist_rounded * optimal_distance_dmg_mul
        end

        -- Get the yaw from both the player and intersection point.
        local yaw2 = atan(newpos.z / newpos.x) + pi * 0.5
        if hit_point.x >= pos2.x then
            yaw2 = yaw2 + pi
        end

        local re_yaw = yaw - yaw2

        if re_yaw <= 0.7853982 and re_yaw >= -0.7853982 then
            -- Hit on the front.
            front = true
            if front_dmg_mul then
                damage = damage * front_dmg_mul
            end
        elseif side_dmg_mul and re_yaw <= -0.7853982 and re_yaw >= -2.356194 then
            -- Hit on the left-side.
            damage = damage * side_dmg_mul
        elseif back_dmg_mul and re_yaw <= -2.356194 and re_yaw >= -3.926991 then
            -- Hit on the back-side.
            damage = damage * back_dmg_mul
        elseif side_dmg_mul then
            -- Hit on the right-side.
            damage = damage * side_dmg_mul
        end
        
    end

    if elevated_dmg_mul and pos1.y > pos2.y then
        -- Give a damage bonus or drawback to the aggressor if they are above the victim.
        damage = damage * elevated_dmg_mul
    elseif lower_elevation_dmg_mul and pos1.y < pos2.y then
        -- Give a damage bonus or drawback to the aggressor if they are below the victim.
        damage = damage * lower_elevation_dmg_mul
    elseif equal_height_dmg_mul then
        -- Give a damage bonus or drawback to the aggressor if they are equal footing with the victim.
        damage = damage * equal_height_dmg_mul
    end
    
    -- This damage bonus can only be used if this is a full interval punch.
    if full_punch and velocity_dmg_mul then
        local v1 = hitter:get_player_velocity()
        local vv
        if front then
            -- Ignore the victim's speed if you hit them in the front.
            vv = abs(v1.x) + abs(v1.y) + abs(v1.z)
        else
            -- Subtract the victim's velocity from the aggressor if they where not hit in the front.
            local v2 = player:get_player_velocity()
            vv = abs(v1.x) - abs(v2.x) + abs(v1.y) - abs(v2.y) + abs(v1.z) - abs(v2.z)
        end
        if vv > 0 then
            -- Give a damage bonus to the aggressor based on how fast they are running.
            damage = damage + vv * velocity_dmg_mul
        end
    end

    -- If damage is below zero set it to a default value.
    if damage <= 0 then
        damage = 1
    end

    -- Remove the hitter's blocking data.
    players_blocking[hitter:get_player_name()] = nil

    -- Process if the player is blocking or not.
    local data = players_blocking[name]

    if front and data and data.pool > 0 and data.time + data.duration > get_us_time() then
        -- Block the damage and add it as wear to the tool.
        local wielded_item = player:get_wielded_item()
        wielded_item:add_wear(damage * block_dmg_mul)
        player:set_wielded_item(wielded_item)
        data.pool = data.pool - damage
        players_blocking[name] = data
        return true
    elseif data then
        -- Block attempt failed.
        players_blocking[name] = nil
    end

    -- Damage the player.
    player:set_hp(player:get_hp() - damage, "punch")

    return true
end)
