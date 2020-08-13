if sscsm then
    local dash_speed = pvp_revamped.config.dash_speed
    local barrel_roll_speed = pvp_revamped.config.barrel_roll_speed
    local get_player_data = pvp_revamped.get_player_data
    local player_data = pvp_revamped.player_data
    local player_persistent_data = pvp_revamped.player_persistent_data
    local create_wield_shield = pvp_revamped.create_wield_shield
    local get_us_time = minetest.get_us_time
    local get_player_by_name = minetest.get_player_by_name
    local cos = math.cos
    local sin = math.sin

    -- Register a sscsm for dodging and dashing.
    sscsm.register({name = "pvp_revamped:movement",
                    file = minetest.get_modpath("pvp_revamped") .. "/movement.lua"})

    local function remove_hits(name)
        local hit_data = get_player_data(name).hit

        if hit_data then
            for i = #hit_data, 1, -1 do
                local data = hit_data[i]

                if not data.resolved then
                    local count = #hit_data
                    
                    hit_data[i] = hit_data[count]
                    hit_data[count] = nil
                end
            end
        end
    end

    -- Helper function to check and set the dodge cooldown.
    local function dodge(name, player, number)
        local dodge_data = get_player_data(name)
        
        if not dodge_data.dodge then
            dodge_data.dodge = {[number] = get_us_time()}
            player:set_properties{damage_texture_modifier = ""}
            -- Clear out any hit data on dodge.
            remove_hits(name)
        elseif dodge_data.dodge and not dodge_data.dodge[number] then
            dodge_data.dodge[number] = get_us_time()
            player:set_properties{damage_texture_modifier = ""}
            -- Clear out any hit data on dodge.
            remove_hits(name)
        end
    end

    -- Channel for dodge request.
    sscsm.register_on_com_receive("pvp_revamped:dodge", function(name, msg)
        if msg and type(msg) == "string" then
            local player = get_player_by_name(name)
            local velocity = player:get_player_velocity().y
            local aerial_points = 0

            if velocity < 0.0 or velocity > 0.0 then
                aerial_points = 1
            end

            if msg == "dodge" then
                dodge(name, player, 1 + aerial_points)
            else
                return false
            end
        end
    end)
    
    -- Helper function to check and set the barrel_roll cooldown.
    local function barrel_roll(name, player, number, x, z)
        local barrel_roll_data = get_player_data(name)

        if not barrel_roll_data.barrel_roll then
            barrel_roll_data.barrel_roll = {[number] = {time = get_us_time(), x = x, z = z}}
            player:set_properties{damage_texture_modifier = ""}
            -- Clear out any hit data on barrel roll.
            remove_hits(name)
        elseif barrel_roll_data.barrel_roll and not barrel_roll_data.barrel_roll[number] then
            barrel_roll_data.barrel_roll[number] = {time = get_us_time(), x = x, z = z}
            player:set_properties{damage_texture_modifier = ""}
            -- Clear out any hit data on barrel roll.
            remove_hits(name)
        else
            return
        end

        local yaw = player:get_look_horizontal()
        local co = cos(yaw)
        local si = sin(yaw)
        local re_x = co * x - si * z
        local re_z = si * x + co * z

        player:add_player_velocity({x = re_x, y = 0, z = re_z})
    end

    -- Channel for barrel_roll request.
    sscsm.register_on_com_receive("pvp_revamped:barrel_roll", function(name, msg)
        if msg and type(msg) == "string" then
            local player = get_player_by_name(name)
            local yaw = player:get_look_horizontal()
            local velocity = player:get_player_velocity().y
            local aerial_points = 0

            if velocity < 0.0 or velocity > 0.0 then
                aerial_points = 4
            end

            if msg == "barrel_roll_l" then
                barrel_roll(name, player, 1 + aerial_points, -barrel_roll_speed, 0)
            elseif msg == "barrel_roll_u" then
                barrel_roll(name, player, 2 + aerial_points, 0, barrel_roll_speed)
            elseif msg == "barrel_roll_r" then
                barrel_roll(name, player, 3 + aerial_points, barrel_roll_speed, 0)
            elseif msg == "barrel_roll_d" then
                barrel_roll(name, player, 4 + aerial_points, 0, -barrel_roll_speed)
            else
                return false
            end
        end
    end)

    local function dash(player, name, dash_key, x, y, z)
        local dash_data = get_player_data(name)
        
        if not dash_data.dash then
            dash_data.dash = {[dash_key] = get_us_time()}
        elseif dash_data.dash and not dash_data.dash[dash_key] then
            dash_data.dash[dash_key] = get_us_time()
        else
            return 
        end
        
        local yaw = player:get_look_horizontal()
        local co = cos(yaw)
        local si = sin(yaw)
        local re_x = co * x - si * z
        local re_z = si * x + co * z

        player:add_player_velocity({x = re_x, y = y, z = re_z})
    end

    -- Channel for dash request.
    sscsm.register_on_com_receive("pvp_revamped:dash", function(name, msg)
        if msg and type(msg) == "string" then
            local player = get_player_by_name(name)
            local y = dash_speed * 0.5
            local aerial_points = 0
            local velocity = player:get_player_velocity().y

            if velocity < 0.0 or velocity > 0.0 then
                aerial_points = 4
            end

            if msg == "dash_l" then
                dash(player, name, 1 + aerial_points, -dash_speed, y, 0)
            elseif msg == "dash_u" then
                dash(player, name, 2 + aerial_points, 0, y, dash_speed)
            elseif msg == "dash_r" then
                dash(player, name, 3 + aerial_points, dash_speed, y, 0)
            elseif msg == "dash_d" then
                dash(player, name, 4 + aerial_points, 0, y, -dash_speed)
            else
                return false
            end
        end
    end)

    -- Channel for shield_block request.
    if minetest.global_exists("armor") then
        sscsm.register_on_com_receive("pvp_revamped:shield_block", function(name, msg)
            if msg and type(msg) == "string" then
                local data_shield = player_persistent_data[name].inventory_armor_shield

                if data_shield then
                    local data = get_player_data(name)
                    local time = get_us_time()

                    create_wield_shield(name, "Arm_Left", data_shield.name, data_shield.groups)
                    
                    data.shield = {pool = data_shield.block_pool, name = data_shield.name, index = data_shield.index, initial_time = time, time = time, duration = data_shield.duration, hasty_guard_duration = data_shield.hasty_guard_duration, armor_inv = true}
                    data.block = nil
                    player_data[name] = data

                    get_player_by_name(name):set_properties{damage_texture_modifier = ""}
                end
            end
        end)
    end
end
