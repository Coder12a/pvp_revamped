local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local remove_text_center = pvp_revamped.remove_text_center
local drop = pvp_revamped.drop
local get_player_by_name = minetest.get_player_by_name

-- Create an empty data sheet for the player.
minetest.register_on_joinplayer(function(player)
    player_persistent_data[player:get_player_name()] = {damage_texture_modifier = player:get_properties().damage_texture_modifier}
end)

-- Clear up memory if the player leaves.
-- Drop any item the player is about to throw on leave.
-- Remove the shield entity.
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local pdata = player_data[name]

    if not pdata then
        return
    end

    local throw_data = pdata.throw
    
    if throw_data then
        drop(player, throw_data.item)
    end

    local entity = pdata.entity

    if entity then
        entity:remove()
    end

    player_data[name] = nil
    player_persistent_data[name] = nil
end)

-- Drop any item the player is about to throw on death.
-- Remove the shield entity.
minetest.register_on_dieplayer(function(player)
    local name = player:get_player_name()
    local pdata = player_data[name]

    if not pdata then
        return
    end

    local throw_data = pdata.throw
    
    if throw_data then
        drop(player, throw_data.item)
        
        pdata.throw = nil
    end

    local entity = pdata.entity

    if entity then
        entity:remove()

        pdata.entity = nil
    end

    player_data[name] = pdata
end)

-- Drop any item the player is about to throw on shutdown.
-- Remove the shield entity.
minetest.register_on_shutdown(function()
    for k, v in pairs(player_data) do
        local throw_data = v.throw

        if throw_data then
            drop(get_player_by_name(k), throw_data.item)
        end
    end
end)

minetest.register_on_player_inventory_action(function(player)
    local name = player:get_player_name()

    if not player_data or not player_data[name] then
        return
    end

    local pdata = player_data[name]
    local data_shield = pdata.shield

    if data_shield and not data_shield.armor_inv and player:get_wielded_item():get_name() ~= data_shield.name then
        player_data[name].shield = nil

        -- Remove un-used hud element.
        remove_text_center(player, "pvp_revamped:shield_pool")

        return
    end

    local data_block = pdata.block

    if data_block and player:get_wielded_item():get_name() ~= data_block.name then
        player_data[name].block = nil

        -- Remove un-used hud element.
        remove_text_center(player, "pvp_revamped:block_pool")
    end
end)
