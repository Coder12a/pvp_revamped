local head_height = 1.2
local torso_height = 0.75
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

local hit_points = {{x = 0.3, y = 1.2, z = 0, part = 1}, 
        {x = 0, y = 1.2, z = 0, part = 0}, 
        {x = -0.3, y = 1.2, z = 0, part = 1}}

local registered_tools = minetest.registered_tools
local raycast = minetest.raycast
local add = vector.add
local multiply = vector.multiply
local subtract = vector.subtract
local distance = vector.distance
local cos = math.cos
local sin = math.sin
local abs = math.abs
local atan = math.atan
local pi = math.pi

-- Do the damage calculations when the player gets hit.
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local pos1 = hitter:get_pos()
    local pos2 = player:get_pos()
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
            -- Hit in the torso.
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

            -- Hit in the arm.
            if arm_dmg_mul and near_part == 1 then
                damage = damage * arm_dmg_mul
            elseif torso_dmg_mul then
                damage = damage * torso_dmg_mul
            end
        elseif leg_dmg_mul then
            -- Hit in the leg.
            damage = damage * leg_dmg_mul
        end

        local dist = vector.distance(hitter_pos, pos2)
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

        if front_dmg_mul and re_yaw <= 0.7853982 and re_yaw >= -0.7853982 then
            -- Hit in the front.
            front = true
            damage = damage * front_dmg_mul
        elseif side_dmg_mul and re_yaw <= -0.7853982 and re_yaw >= -2.356194 then
            -- Hit in the left.
            damage = damage * side_dmg_mul
        elseif back_dmg_mul and re_yaw <= -2.356194 and re_yaw >= -3.926991 then
            -- Hit in the back.
            damage = damage * back_dmg_mul
        elseif side_dmg_mul then
            -- Hit in the right.
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
            -- Ignore the victim's speed if you hit him in the front.
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

    -- Damage the player.
    player:set_hp(player:get_hp() - damage, "punch")

    return true
end)
