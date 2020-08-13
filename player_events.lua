local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local drop = pvp_revamped.drop

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
            drop(player, throw_data.item)
        end

        local entity = v.entity

        if entity then
            entity:remove()
        end
    end
end)
