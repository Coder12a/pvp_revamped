local dodge = pvp_revamped.dodge
local dash = pvp_revamped.dash
local barrel_roll = pvp_revamped.barrel_roll
local dash_speed = pvp_revamped.config.dash_speed
local barrel_roll_speed = pvp_revamped.config.barrel_roll_speed

local function dodge_func(player)
    local velocity = player:get_player_velocity().y
    local aerial_points = 0

    if velocity < 0.0 or velocity > 0.0 then
        aerial_points = 1
    end

    dodge(player:get_player_name(), player, 1 + aerial_points)
end

local function dash_func(player, dir)
    local y = dash_speed * 0.5
    local aerial_points = 0
    local velocity = player:get_player_velocity().y

    if velocity < 0.0 or velocity > 0.0 then
        aerial_points = 4
    end

    if dir == 1 then
        dash(player, player:get_player_name(), 1 + aerial_points, -dash_speed, y, 0)
    elseif dir == 2 then
        dash(player, player:get_player_name(), 2 + aerial_points, 0, y, dash_speed)
    elseif dir == 3 then
        dash(player, player:get_player_name(), 3 + aerial_points, dash_speed, y, 0)
    elseif dir == 4 then
        dash(player, player:get_player_name(), 4 + aerial_points, 0, y, -dash_speed)
    end
end

local function roll_func(player, dir)
    local yaw = player:get_look_horizontal()
    local velocity = player:get_player_velocity().y
    local aerial_points = 0

    if velocity < 0.0 or velocity > 0.0 then
        aerial_points = 4
    end

    if dir == 1 then
        barrel_roll(player:get_player_name(), player, 1 + aerial_points, -barrel_roll_speed, 0)
    elseif dir == 2 then
        barrel_roll(player:get_player_name(), player, 2 + aerial_points, 0, barrel_roll_speed)
    elseif dir == 3 then
        barrel_roll(player:get_player_name(), player, 3 + aerial_points, barrel_roll_speed, 0)
    elseif dir == 4 then
        barrel_roll(player:get_player_name(), player, 4 + aerial_points, 0, -barrel_roll_speed)
    end
end

for i = 1, 4 do
    local name = "left"
    
    if i == 2 then
        name = "up"
    elseif i == 3 then
        name = "right"
    elseif i == 4 then
        name = "down"
    end

    minetest.register_craftitem("pvp_revamped:dash_" .. name, {
        description = "Dash " .. name:gsub("^%l", string.upper),
        inventory_image = "pvp_revamped_dash" .. name .. ".png",
        stack_max = 1,
    
        on_use = function(itemstack, user)
            dash_func(user, i)
        end,
    
        on_secondary_use = function(itemstack, user)
            dash_func(user, i)
        end,
    
        on_place = function(itemstack, placer)
            dash_func(placer, i)
        end
    })

    minetest.register_craftitem("pvp_revamped:roll_" .. name, {
        description = "Roll " .. name:gsub("^%l", string.upper),
        inventory_image = "pvp_revamped_roll" .. name .. ".png",
        stack_max = 1,
    
        on_use = function(itemstack, user)
            roll_func(user, i)
        end,
    
        on_secondary_use = function(itemstack, user)
            roll_func(user, i)
        end,
    
        on_place = function(itemstack, placer)
            roll_func(placer, i)
        end
    })
end

minetest.register_craftitem("pvp_revamped:dodge", {
    description = "Dodge",
    inventory_image = "pvp_revamped_dodge.png",
    stack_max = 1,

    on_use = function(itemstack, user)
        dodge_func(user)
    end,

    on_secondary_use = function(itemstack, user)
        dodge_func(user)
    end,

    on_place = function(itemstack, placer)
        dodge_func(placer)
    end
})
