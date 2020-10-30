local head_height = pvp_revamped.config.head_height
local torso_height = pvp_revamped.config.torso_height
local leg_height = pvp_revamped.config.leg_height
local knee_height = pvp_revamped.config.knee_height
local disarm_chance_mul = pvp_revamped.config.disarm_chance_mul
local leg_immobilize_mul = pvp_revamped.config.leg_immobilize_mul
local knee_immobilize_mul = pvp_revamped.config.knee_immobilize_mul
local immobilize_mul = pvp_revamped.config.immobilize_mul
local block_wear_mul = pvp_revamped.config.block_wear_mul
local head_dmg_mul = pvp_revamped.config.head_dmg_mul
local torso_dmg_mul = pvp_revamped.config.torso_dmg_mul
local arm_dmg_mul = pvp_revamped.config.arm_dmg_mul
local leg_dmg_mul = pvp_revamped.config.leg_dmg_mul
local front_dmg_mul = pvp_revamped.config.front_dmg_mul
local side_dmg_mul = pvp_revamped.config.side_dmg_mul
local back_dmg_mul = pvp_revamped.config.back_dmg_mul
local elevated_dmg_mul = pvp_revamped.config.elevated_dmg_mul
local equal_height_dmg_mul = pvp_revamped.config.equal_height_dmg_mul
local lower_elevation_dmg_mul = pvp_revamped.config.lower_elevation_dmg_mul
local velocity_dmg_mul = pvp_revamped.config.velocity_dmg_mul
local optimal_distance_dmg_mul = pvp_revamped.config.optimal_distance_dmg_mul
local maximum_distance_dmg_mul = pvp_revamped.config.maximum_distance_dmg_mul
local optimal_distance_mul = pvp_revamped.config.optimal_distance_mul
local parry_dmg_mul = pvp_revamped.config.parry_dmg_mul
local counter_dmg_mul = pvp_revamped.config.counter_dmg_mul
local counter_duration = pvp_revamped.config.counter_duration
local get_player_data = pvp_revamped.get_player_data
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local hit_points = pvp_revamped.hit_points
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center
local point_arm = pvp_revamped.point_arm
local registered_tools = minetest.registered_tools
local raycast = minetest.raycast
local get_us_time = minetest.get_us_time
local get_player_information = minetest.get_player_information
local add_item = minetest.add_item
local get_inventory = minetest.get_inventory
local armor_3d = minetest.global_exists("armor")
local insert = table.insert
local add = vector.add
local multiply = vector.multiply
local subtract = vector.subtract
local distance = vector.distance
local cos = math.cos
local sin = math.sin
local abs = math.abs
local atan = math.atan
local random = math.random
local max = math.max
local min = math.min
local floor = math.floor
local pi = math.pi
local rad90 = pi * 0.5
local rad360 = pi * 2

-- Do the damage calculations when the player gets hit.
local function punch(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local name = player:get_player_name()
    local victim_data = get_player_data(name)

    -- If the player is dodging return true.
    if victim_data.active_barrel_rolls or victim_data.active_dodges then
        return true
    end

    local hitter_name = hitter:get_player_name()
    local hitter_data = get_player_data(hitter_name)
    local projectile_data = pvp_revamped.projectile_data

    -- Cancel any attack if the hitter is in barrel_roll or dodge mode.
    -- Or if the hitter is in the process of throwing.
    if (hitter_data.active_barrel_rolls or hitter_data.active_dodges or hitter_data.throw) and not projectile_data then
        return true
    end

    local pos1
    local pos2 = player:get_pos()
    local hitter_pos
    local hitter_velocity
    local item
    local range = 4
    local yaw = player:get_look_horizontal()
    local front
    local side
    local arm
    local leg
    local knee
    local re_yaw
    local full_punch
    local full_punch_interval = 1.4
    local _dir
    local projectile
    local projectile_intersection_point

    -- Use projectile_data if a thrown entity was the one that punched.
    if projectile_data then
        pos1 = projectile_data.pos
        hitter_pos = {x = pos1.x, y = pos1.y, z = pos1.z}
        item = registered_tools[projectile_data.name]
        _dir = projectile_data.dir
        hitter_velocity = projectile_data.velocity
        projectile_intersection_point = projectile_data.intersection_point
        projectile = true

        -- Set the projectile table to nil.
        projectile_data = nil
    else
        pos1 = hitter:get_pos()
        hitter_pos = {x = pos1.x, y = pos1.y, z = pos1.z}
        item = registered_tools[hitter:get_wielded_item():get_name()]
        -- Raise the position to eye height.
        hitter_pos.y = hitter_pos.y + hitter:get_properties().eye_height
        _dir = hitter:get_look_dir()
        hitter_velocity = hitter:get_player_velocity()
    end

    if item then
        tool_capabilities = item.tool_capabilities
    end

    -- I got this rare error where tool_capabilities was nil so I put this here to safe guard.
    if not tool_capabilities then
        return true
    end

    if item and item.range then
        range = item.range
    end

    -- Get whether this is a full punch.
    if tool_capabilities and time_from_last_punch >= tool_capabilities.full_punch_interval then
        full_punch = true
        full_punch_interval = tool_capabilities.full_punch_interval
    elseif tool_capabilities and tool_capabilities.full_punch_interval then
        full_punch_interval = tool_capabilities.full_punch_interval
    end

    -- Get the second position from the direction of the hitter.
    local hit_pos1 = add(hitter_pos, _dir)
    local hit_pos2 = add(hit_pos1, multiply(_dir, range))
    local ray = raycast(hit_pos1, hit_pos2)

    local function hit(intersection_point)
        local newpos = subtract(intersection_point, pos2)
        local y1 = intersection_point.y
        local y2 = pos2.y
        
        -- Get the tool's modifiers or use the default ones.
        local head_height = tool_capabilities.head_height or head_height
        local torso_height = tool_capabilities.torso_height or torso_height
        local leg_height = tool_capabilities.leg_height or leg_height
        local knee_height = tool_capabilities.knee_height or knee_height
        local head_dmg_mul = tool_capabilities.head_dmg_mul or head_dmg_mul
        local torso_dmg_mul = tool_capabilities.torso_dmg_mul or torso_dmg_mul
        local arm_dmg_mul = tool_capabilities.arm_dmg_mul or arm_dmg_mul
        local leg_dmg_mul = tool_capabilities.leg_dmg_mul or leg_dmg_mul

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

            if near_part == point_arm then
                -- Hit in the arm.
                arm = true

                if arm_dmg_mul then
                    damage = damage * arm_dmg_mul
                end
            elseif torso_dmg_mul then
                -- Hit in the torso.
                damage = damage * torso_dmg_mul
            end
        elseif leg_height and y1 > y2 + leg_height then
            -- Hit in the leg.
            leg = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        elseif knee_height and y1 > y2 + knee_height then
            -- Hit in the knee.
            knee = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        else
            -- Hit in the lower leg.
            leg = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        end

        local dist = distance(hitter_pos, pos2)
        local optimal_distance_mul = tool_capabilities.optimal_distance_mul or optimal_distance_mul
        local dist_rounded = dist + 0.5 - (dist + 0.5) % 1

        -- If the distance rounded is outside the range skip.
        if optimal_distance_mul and dist_rounded <= range + 1 then
            local optimal_distance_dmg_mul = tool_capabilities.optimal_distance_dmg_mul or optimal_distance_dmg_mul
            local maximum_distance_dmg_mul = tool_capabilities.maximum_distance_dmg_mul or maximum_distance_dmg_mul
            local optimal_range = range * optimal_distance_mul

            -- Add or remove damage based on the distance.
            -- Full punches are not affected by any maximum distance.
            if (not full_punch or maximum_distance_dmg_mul < 0) and maximum_distance_dmg_mul and dist_rounded > optimal_range then
                damage = damage - range * maximum_distance_dmg_mul
            elseif (not full_punch or optimal_distance_dmg_mul > 0) and optimal_distance_dmg_mul and dist_rounded < optimal_range then
                damage = damage + range * optimal_distance_dmg_mul
            end
        end

        -- Get the yaw from both the player and intersection point.
        local yaw2 = atan(newpos.z / newpos.x) + rad90
        
        if intersection_point.x >= pos2.x then
            yaw2 = yaw2 + pi
        end

        re_yaw = rad360 - (yaw - yaw2)

        if re_yaw < 0 then
            re_yaw = rad360 - re_yaw
        end

        if re_yaw > rad360 then
            re_yaw = re_yaw - rad360
        end

        local back_dmg_mul = tool_capabilities.back_dmg_mul or back_dmg_mul

        if (re_yaw <= 0.7853982 and re_yaw >= 0) or (re_yaw <= 6.283185 and re_yaw >= 5.497787) then
            -- Hit on the front.
            front = true

            local front_dmg_mul = tool_capabilities.front_dmg_mul or front_dmg_mul

            if front_dmg_mul then
                damage = damage * front_dmg_mul
            end
        elseif re_yaw <= 2.356194 then
            -- Hit on the left-side.
            side = true

            local side_dmg_mul = tool_capabilities.side_dmg_mul or side_dmg_mul

            if side_dmg_mul then
                damage = damage * side_dmg_mul
            end
        elseif back_dmg_mul and re_yaw <= 3.926991 then
            -- Hit on the back-side.
            damage = damage * back_dmg_mul
        else
            -- Hit on the right-side.
            side = true

            local side_dmg_mul = tool_capabilities.side_dmg_mul or side_dmg_mul

            if side_dmg_mul then
                damage = damage * side_dmg_mul
            end
        end

        -- You can only hit the knee-caps in the front.
        if side and knee then
            knee = nil
            leg = true
        end
    end

    if not projectile then
        for pointed_thing in ray do
            if pointed_thing.type == "object" and pointed_thing.ref:is_player() and pointed_thing.ref:get_player_name() == name then
                hit(pointed_thing.intersection_point)

                -- End the loop we got what we came for.
                break
            end
        end
    else
        hit(projectile_intersection_point)
    end

    local elevated_dmg_mul = tool_capabilities.elevated_dmg_mul or elevated_dmg_mul
    local lower_elevation_dmg_mul = tool_capabilities.lower_elevation_dmg_mul or lower_elevation_dmg_mul
    local equal_height_dmg_mul = tool_capabilities.equal_height_dmg_mul or equal_height_dmg_mul

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
    local velocity_dmg_mul = tool_capabilities.velocity_dmg_mul or velocity_dmg_mul

    if full_punch and velocity_dmg_mul then
        local vv

        if front then
            -- Ignore the victim's speed if you hit them in the front.
            vv = max(abs(hitter_velocity.x), abs(hitter_velocity.y), abs(hitter_velocity.z))
        else
            -- Subtract the victim's velocity from the aggressor if they where not hit in the front.
            local v2 = player:get_player_velocity()
            vv = max(abs(hitter_velocity.x) - abs(v2.x), abs(hitter_velocity.y) - abs(v2.y), abs(hitter_velocity.z) - abs(v2.z))
        end

        if vv > 0 then
            -- Give a damage bonus to the aggressor based on how fast they are running.
            damage = damage + vv * velocity_dmg_mul
        end
    end

    -- If damage is at or below zero set it to a default value.
    damage = max(damage, 0.1)

    if not projectile then
        -- Remove the hitter's blocking data.
        hitter_data.block = nil
        hitter_data.shield = nil
        player_data[hitter_name] = hitter_data

        -- Remove un-used hud element.
        remove_text_center(hitter, "pvp_revamped:block_pool")
        remove_text_center(hitter, "pvp_revamped:shield_pool")
    end

    local data_throw = victim_data.throw
    local data_block = victim_data.block
    local hp = player:get_hp()
    local wielded_item = player:get_wielded_item()
    local item_name = wielded_item:get_name()
    local block_wear_mul = tool_capabilities.block_wear_mul or block_wear_mul

    -- Process if the player is blocking with a tool or not.
    if front and not data_throw and data_block and data_block.pool > 0 and data_block.name == item_name then
        -- Block the damage and add it as wear to the tool.
        wielded_item:add_wear(((damage - full_punch_interval) / 75) * block_wear_mul)
        player:set_wielded_item(wielded_item)
        local pool = data_block.pool
        pool = pool - damage

        -- Remove block table if pool is zero or below.
        if pool <= 0 then
            victim_data.block = nil

            -- Remove un-used hud element.
            remove_text_center(player, "pvp_revamped:block_pool")

            return true
        end

        -- Update block pool text.
        create_hud_text_center(player, "pvp_revamped:block_pool", pool)

        data_block.pool = pool
        victim_data.block = data_block

        return true
    end

    local data_shield = victim_data.shield

    -- Process if the player is blocking with a shield or not.
    if data_shield and not data_shield.armor_inv and not data_throw and data_shield.pool > 0 and data_shield.name == item_name and (front or side) then
        -- Block the damage and add it as wear to the tool.
        local axe_wear = 0
        local pool = data_shield.pool

        if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.shield then
            axe_wear = tool_capabilities.damage_groups.shield
        end

        -- Wear down the shield plus axe damage.
        wielded_item:add_wear((((damage - full_punch_interval) / 75) * block_wear_mul) + axe_wear)
        player:set_wielded_item(wielded_item)
        -- pool minus damage + axe_wear.
        pool = pool - (damage + axe_wear)

        -- Remove shield table if pool is zero or below.
        if pool <= 0 then
            victim_data.shield = nil

            -- Remove un-used hud element.
            remove_text_center(player, "pvp_revamped:shield_pool")

            return true
        end

        -- Update shield pool text.
        create_hud_text_center(player, "pvp_revamped:shield_pool", pool)

        data_shield.pool = pool
        victim_data.shield = data_shield

        return true
    elseif armor_3d and data_shield and data_shield.armor_inv and not data_throw and data_shield.pool > 0 and (front or side) then
        local inv = get_inventory({type = "detached", name = name .. "_armor"})

        if inv then
            -- Block the damage and add it as wear to the tool.
            local axe_wear = 0
            local inventory_armor_shield = player_persistent_data[name].inventory_armor_shield
            local index = inventory_armor_shield.index
            local stack = inv:get_stack("armor", index)

            if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.shield then
                axe_wear = tool_capabilities.damage_groups.shield
            end
            if stack and stack:get_name() == inventory_armor_shield.name then
                local pool = data_shield.pool
                -- Wear down the shield plus axe damage.
                stack:add_wear((((damage - full_punch_interval) / 75) * block_wear_mul) + axe_wear)
                inv:set_stack("armor", index, stack)
                -- pool minus damage + axe_wear.
                pool = pool - (damage + axe_wear)

                -- Remove shield table if pool is zero or below.
                if pool <= 0 then
                    victim_data.shield = nil

                    -- Remove un-used hud element.
                    remove_text_center(player, "pvp_revamped:shield_pool")

                    return true
                end

                -- Update shield pool text.
                create_hud_text_center(player, "pvp_revamped:shield_pool", pool)

                data_shield.pool = pool
                victim_data.shield = data_shield
                
                return true
            else
                -- Remove the data if we either can't find the stack or the name is different.
                player_persistent_data[name].inventory_armor_shield = nil
            end
        else
            -- No inv so remove data.
            player_persistent_data[name].inventory_armor_shield = nil
        end
    end

    -- Process if the player was hit in the arm.
    if arm then
        local item2 = registered_tools[item_name]
        local chance
        
        if item2 and not data_shield and not data_block and item2.tool_capabilities and item2.tool_capabilities.damage_groups.fleshy and item2.tool_capabilities.full_punch_interval then
            -- Compute the chance to disarm by the victim's hp and tool stats.
            local disarm_chance_mul = tool_capabilities.disarm_chance_mul or disarm_chance_mul

            chance = random(0, ((hp + (item2.tool_capabilities.damage_groups.fleshy - item2.tool_capabilities.full_punch_interval) * disarm_chance_mul) - damage) + 1)
        elseif not item2 and not data_shield and not data_block then
            -- Compute the chance to disarm by the victim's hp.
            chance = random(0, (hp - damage) + 1)
        end

        -- Disarm the player if chance equals zero.
        if chance and chance <= 0 then
            local drop_item = wielded_item:take_item()
            local obj = add_item(pos2, drop_item)

            if obj then
                obj:get_luaentity().collect = true
            end

            player:set_wielded_item(wielded_item)
        end
    end

    local function set_immobilize_data(speed, damage)
        player:set_physics_override({speed = speed, jump = speed})

        local immobilize_mul = tool_capabilities.immobilize_mul or immobilize_mul
        
        victim_data.immobilize = {time = get_us_time(), value = damage * immobilize_mul}
    end

    -- Process if the player was hit in the leg.
    if leg then
        -- immobilize the player.
        local leg_immobilize_mul = tool_capabilities.leg_immobilize_mul or leg_immobilize_mul
        local dmg = max(damage - hp, 1)
        local speed = min(1 / dmg * leg_immobilize_mul, 0.1)
        local data_immobilize = victim_data.immobilize

        if not data_immobilize or data_immobilize.value > speed then
            set_immobilize_data(speed, dmg)
        end
    elseif knee then
        -- immobilize the player.
        local knee_immobilize_mul = tool_capabilities.knee_immobilize_mul or knee_immobilize_mul
        local speed = min(1 / max(damage - hp, 1.5) * knee_immobilize_mul, 0.1)
        local data_immobilize = victim_data.immobilize

        if data_immobilize then
            -- Add the original value and update all immobilize data.
            speed = min(abs(speed - data_immobilize.value), 0.1)

            set_immobilize_data(speed, dmg)
        else
            set_immobilize_data(speed, dmg)
        end
    end

    if player:get_properties().damage_texture_modifier == "" then
        -- Revert the damage texture modifier.
        player:set_properties{damage_texture_modifier = player_persistent_data[name].damage_texture_modifier}
    end

    -- If there is a damage queue for the hitter tigger the clash.
    local hitter_hitdata = hitter_data.hit

    if hitter_hitdata then
        for i = #hitter_hitdata, 1, -1 do
            local hd = hitter_hitdata[i]

            if not hd.resolved and hd.name == name then
                if floor(hitter:get_player_control_bits() / 256) % 2 == 1 then
                    -- Attempt to parry the attack if place is down.
                    local parry_dmg_mul = tool_capabilities.parry_dmg_mul or parry_dmg_mul
                    local clash_def_mul = tool_capabilities.clash_def_mul or 0
                    local c_damage = damage * clash_def_mul
                    
                    hd.damage = max(hd.damage - (damage + c_damage) * parry_dmg_mul, 0)
                elseif full_punch and tool_capabilities.counter_duration and hd.time + tool_capabilities.counter_duration + pvp_revamped.lag + get_player_information(hitter_name).avg_jitter * 1000000 > get_us_time() then
                    -- All damage gets reversed on counter.
                    -- Current damage gets added to it plus the damage multipliable.
                    local counter_dmg_mul = tool_capabilities.counter_dmg_mul or counter_dmg_mul

                    hd.damage = -(hd.damage + (damage * counter_dmg_mul))
                else
                    -- Reduce, remove, or reverse the damage and resolve the clash.
                    -- Negative damage will be applied to the hitter.
                    local clash_def_mul = tool_capabilities.clash_def_mul or 0
                    local c_damage = damage * clash_def_mul

                    hd.damage = hd.damage - damage

                    if hd.damage > 0 and hd.damage - c_damage < 0 then
                        hd.damage = 0
                    elseif hd.damage > 0 and hd.damage - c_damage >= 0 then
                        hd.damage = hd.damage - c_damage
                    end
                end

                hd.resolved = true
                hd.full_punch = true

                break
            end
        end
    elseif victim_data.hit then
        insert(victim_data.hit, 1, {name = hitter_name, damage = damage, full_punch = full_punch, time = get_us_time()})
    else
        victim_data.hit = {{name = hitter_name, damage = damage, full_punch = full_punch, time = get_us_time()}}
    end

    victim_data.block = nil
    victim_data.shield = nil

    -- Remove un-used hud element.
    remove_text_center(player, "pvp_revamped:block_pool")
    remove_text_center(player, "pvp_revamped:shield_pool")

    -- Save new player data to the table.
    player_data[name] = victim_data

    return true
end

-- This needs to be the first punch function to prevent knockback on a immobilizeed player.
insert(minetest.registered_on_punchplayers, 1, punch)

minetest.callback_origins[punch] = {
    mod = "pvp_revamped",
    name = "register_on_punchplayer"
}
