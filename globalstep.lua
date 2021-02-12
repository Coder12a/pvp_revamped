local dodge_duration = pvp_revamped.config.dodge_duration
local barrel_roll_duration = pvp_revamped.config.barrel_roll_duration
local dodge_cooldown = pvp_revamped.config.dodge_cooldown
local barrel_roll_cooldown = pvp_revamped.config.barrel_roll_cooldown
local dash_cooldown = pvp_revamped.config.dash_cooldown
local dodge_aerial_cooldown = pvp_revamped.config.dodge_aerial_cooldown
local barrel_roll_aerial_cooldown = pvp_revamped.config.barrel_roll_aerial_cooldown
local dash_aerial_cooldown = pvp_revamped.config.dash_aerial_cooldown
local projectile_half_throw_mul = pvp_revamped.config.projectile_half_throw_mul
local projectile_gravity = pvp_revamped.config.projectile_gravity
local projectile_dmg_mul = pvp_revamped.config.projectile_dmg_mul
local projectile_spinning_gravity_mul = pvp_revamped.config.projectile_spinning_gravity_mul
local projectile_dip_gravity_mul = pvp_revamped.config.projectile_dip_gravity_mul
local clash_duration = pvp_revamped.config.clash_duration
local projectile_throw_style_dip = pvp_revamped.projectile_throw_style_dip
local projectile_throw_style_spinning = pvp_revamped.projectile_throw_style_spinning
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center
local clear_blockdata = pvp_revamped.clear_blockdata
local clear_shielddata = pvp_revamped.clear_shielddata
local get_player_information = minetest.get_player_information
local get_player_by_name = minetest.get_player_by_name
local get_us_time = minetest.get_us_time
local add_entity = minetest.add_entity
local maxn = table.maxn
local new = vector.new
local max = math.max
local floor = math.floor
local check_item_time = 1
local check_item_iterate = 0

minetest.register_globalstep(function(dtime)
    local lag = dtime * 1000000
    local check_item = check_item_iterate >= check_item_time

    for k, v in pairs(player_data) do
        local player_lag = get_player_information(k).avg_jitter * 1000000
        local player = get_player_by_name(k)
        local time = get_us_time()
        local pp_data = player_persistent_data[k]
        local active

        if v.block and v.aim then
            -- Check if the player is holding down the place key.
            if floor(player:get_player_control_bits() / 256) % 2 == 1 then
                -- Update the block time.
                v.block.time = time
            end

            local block = v.block
            local aim = v.aim
            -- Hand aims forward.
            player:set_bone_position(aim.bone, aim.position, aim.rotation)
            
            -- Remove the block table if it's past duration.
            -- Or if the guard item is not selected.
            if block.time + block.duration + player_lag < time or
               (check_item and player:get_wielded_item():get_name() ~= block.name) then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = pp_data.damage_texture_modifier}

                clear_blockdata(v.block, player, k)
            end
            
            active = true
        elseif not v.block and v.aim then
            local aim = v.aim
            -- Drop hand.
            player:set_bone_position(aim.bone, aim.position, new(-180, 0, 0))

            v.aim = nil
            active = true
        end

        if v.shield and v.entity then
            -- Check if the player is holding down the place key.
            if floor(player:get_player_control_bits() / 256) % 2 == 1 then
                -- Update the shield time.
                v.shield.time = time
            end

            local shield = v.shield

            -- Remove the shield table if it's past duration.
            if shield.time + shield.duration + player_lag < time or
            (check_item and not shield.armor_inv and player:get_wielded_item():get_name() ~= shield.name) then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = pp_data.damage_texture_modifier}
                
                clear_shielddata(v.shield, player, k)
            end

            local entity = v.entity
            -- Point arm forward.
            player:set_bone_position(entity.bone, entity.position, entity.rotation)

            active = true
        elseif not v.shield and v.entity then
            local entity = v.entity
            -- Drop arms.
            player:set_bone_position(entity.bone, entity.position, new(-180, 0, 0))

            v.entity.object:remove()
            v.entity = nil
            active = true
        end

        if v.throw then
            local control_bits = player:get_player_control_bits()
            local throw_data = v.throw
            local tool_capabilities = throw_data.tool_capabilities
            local full_throw = throw_data.time + tool_capabilities.full_throw
            
            -- If neither dig or place is down then throw the item.
            if (floor(control_bits / 128) % 2 ~= 1 and
               floor(control_bits / 256) % 2 ~= 1 and
               floor(control_bits / 512) % 2 ~= 1 and
               floor(control_bits / 32) % 2 ~= 1) or
               pp_data.active_dodges or
               pp_data.active_barrel_rolls then
                
                local pos = player:get_pos()

                pos.y = pos.y + player:get_properties().eye_height
                
                local obj = add_entity(pos, "pvp_revamped:projectile")

                if obj then
                    local ent = obj:get_luaentity()

                    if ent then
                        local throw_style = pp_data.throw_style
                        local throw_speed = tool_capabilities.throw_speed
                        local damage = tool_capabilities.damage_groups.fleshy
                        local projectile_gravity = tool_capabilities.projectile_gravity or projectile_gravity
                        local gravity = projectile_gravity
                        local projectile_dmg_mul = tool_capabilities.projectile_dmg_mul or projectile_dmg_mul
                        local projectile_spinning_gravity_mul = tool_capabilities.projectile_spinning_gravity_mul or projectile_spinning_gravity_mul
                        local projectile_dip_gravity_mul = tool_capabilities.projectile_dip_gravity_mul or projectile_dip_gravity_mul
                        local spin

                        if not throw_data.ready then
                            local projectile_half_throw_mul = tool_capabilities.projectile_half_throw_mul or projectile_half_throw_mul
                            local re = (full_throw - time) * projectile_half_throw_mul

                            if re > 0.5 then
                                damage = damage - re
                                throw_speed = throw_speed - re
                            end
                        end

                        if throw_style == projectile_throw_style_spinning then
                            spin = throw_speed
                            gravity = gravity * projectile_spinning_gravity_mul
                        elseif throw_style == projectile_throw_style_dip then
                            gravity = gravity * projectile_dip_gravity_mul
                        end
                        
                        ent:set_item(k, throw_data.item)
                        ent:throw(player, throw_speed, {x = 0, y = gravity, z = 0}, max(damage * projectile_dmg_mul, 1), throw_style, spin)
                    end
                end

                -- Remove throwing hud.
                remove_text_center(player, "pvp_revamped:throw_item")

                v.throw = nil
            elseif not throw_data.ready and full_throw < time + player_lag then
                -- To prevent changing the hud repeatedly.
                v.throw.ready = true

                create_hud_text_center(player, "pvp_revamped:throw_item", "READY")
            end

            active = true
        end

        if v.immobilize then
            local immobilize = v.immobilize

            -- Check if the immobilize duration expired. 
            if immobilize.time + immobilize.value + player_lag < time then
                -- Restore the player's physics.
                get_player_by_name(k):set_physics_override({speed = 1, jump = 1})
                v.immobilize = nil
            end

            active = true
        end

        if v.barrel_roll then
            local active_barrel_rolls = nil
            
            -- Process the player's barrel_roll table cooldown.
            for j, l in pairs(v.barrel_roll) do
                -- Find if it's aerial or not.
                if j > 4 and l.time + barrel_roll_aerial_cooldown + player_lag < time then
                    v.barrel_roll[j] = nil
                elseif j < 5 and l.time + barrel_roll_cooldown + player_lag < time then
                    v.barrel_roll[j] = nil
                elseif l.time + barrel_roll_duration + player_lag > time then
                    local re_x, re_z = rotate_point(player:get_look_horizontal(), l.x, l.z)

                    player:add_player_velocity({x = re_x, y = 0, z = re_z})
                    active_barrel_rolls = true
                end
            end

            if not active_barrel_rolls and player:get_properties().damage_texture_modifier == "" then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = pp_data.damage_texture_modifier}
            end

            -- Store the barrel_roll amount for later use.
            player_persistent_data[k].active_barrel_rolls = active_barrel_rolls

            -- If this table contains no more barrel_rolls remove it.
            if maxn(v.barrel_roll) < 1 then
                v.barrel_roll = nil
            end

            -- Remove un-used barrel roll text.
            if not active_barrel_rolls then
                remove_text_center(player, "pvp_revamped:barrel_roll")
            end

            active = true
        end

        if v.dodge then
            local active_dodges = nil
            
            -- Process the player's dodge table cooldown.
            for j, l in pairs(v.dodge) do
                -- Find if it's aerial or not.
                if j > 4 and l + dodge_aerial_cooldown + player_lag < time then
                    v.dodge[j] = nil
                elseif j < 5 and l + dodge_cooldown + player_lag < time then
                    v.dodge[j] = nil
                elseif l + dodge_duration + player_lag > time then
                    active_dodges = true
                end
            end

            if not active_dodges and player:get_properties().damage_texture_modifier == "" then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = pp_data.damage_texture_modifier}
            end

            -- Store the dodge amount for later use.
            player_persistent_data[k].active_dodges = active_dodges

            -- If this table contains no more dodges remove it.
            if maxn(v.dodge) < 1 then
                v.dodge = nil
            end

            -- Remove un-used dodge text.
            if not active_dodges then
                remove_text_center(player, "pvp_revamped:dodge")
            end

            active = true
        end

        if v.dash then
            -- Process the player's dash table cooldown.
            for j, l in pairs(v.dash) do
                -- Find if it's aerial or not.
                if j > 4 and l + dash_aerial_cooldown + player_lag < time then
                    v.dash[j] = nil
                elseif j < 5 and l + dash_cooldown + player_lag < time then
                    v.dash[j] = nil
                end
            end

            -- If this table contains no more dashes remove it.
            if maxn(v.dash) < 1 then
                v.dash = nil
            end

            active = true
        end

        if v.hit then
            local hit_data = v.hit
            local count = #hit_data

            for i = count, 1, -1 do
                local data = hit_data[i]

                if data.time + clash_duration + player_lag < time then
                    hit_data[i] = hit_data[count]
                    hit_data[count] = nil
                    
                    count = count - 1
                end
            end

            -- If this table contains no more hits remove it.
            if maxn(hit_data) < 1 then
                v.hit = nil
            end

            active = true
        end

        if not active then
            -- Just in case there is still guard pool stuff on screen.
            remove_text_center(player, "pvp_revamped:block_pool")
            remove_text_center(player, "pvp_revamped:shield_pool")

            player_data[k] = nil
        end
    end
    
    -- Reset or add the check item iterater.
    if check_item then
        check_item_iterate = 0
    else
        check_item_iterate = check_item_iterate + dtime
    end
end)
