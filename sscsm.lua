if not sscsm then
    return
end

local dash_speed = pvp_revamped.config.dash_speed
local barrel_roll_speed = pvp_revamped.config.barrel_roll_speed
local get_player_data = pvp_revamped.get_player_data
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local create_wield_shield = pvp_revamped.create_wield_shield
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center
local use_player_api = pvp_revamped.use_player_api
local shield_inv = pvp_revamped.shield_inv
local dash = pvp_revamped.dash
local barrel_roll = pvp_revamped.barrel_roll
local dodge = pvp_revamped.dodge
local get_us_time = minetest.get_us_time
local get_player_by_name = minetest.get_player_by_name
local set_textures
local cos = math.cos
local sin = math.sin

if use_player_api then
    set_textures = player_api.set_textures
end

-- Register a sscsm for dodging and dashing.
sscsm.register({name = "pvp_revamped:movement",
                file = minetest.get_modpath("pvp_revamped") .. "/movement.lua"})

-- Channel for dodge request.
sscsm.register_on_com_receive("pvp_revamped:dodge", function(name, msg)
    local player = get_player_by_name(name)
    local velocity = player:get_player_velocity().y
    local aerial_points = 0

    if velocity < 0.0 or velocity > 0.0 then
        aerial_points = 1
    end

    dodge(name, player, 1 + aerial_points)
end)

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

if not minetest.global_exists("armor") then
    return
end

-- Channel for shield_block request.
sscsm.register_on_com_receive("pvp_revamped:shield_block", function(name, msg)
    local data = get_player_data(name)
    local player = get_player_by_name(name)
    local player_pdata = player_persistent_data[name]

    shield_inv(player, name, player_pdata, data)
end)
