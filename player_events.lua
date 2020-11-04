local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local remove_text_center = pvp_revamped.remove_text_center
local drop = pvp_revamped.drop
local get_player_by_name = minetest.get_player_by_name
local new = vector.new

-- Create an empty data sheet for the player.
minetest.register_on_joinplayer(function(player)
    player_persistent_data[player:get_player_name()] = {
        damage_texture_modifier = player:get_properties().damage_texture_modifier,
        throw_style = player:get_meta():get_int("pvp_revamped.throw_style")
    }
end)

-- Clear up memory if the player leaves.
-- Drop any item the player is about to throw on leave.
-- Remove the shield entity.
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local pdata = player_data[name]

    player_persistent_data[name] = nil

    if not pdata then
        return
    end

    local throw_data = pdata.throw
    
    if throw_data then
        drop(player, throw_data.item)
    end

    local entity = pdata.entity

    if entity then
        entity.object:remove()
    end

    player_data[name] = nil
end)

-- Drop any item the player is about to throw on death.
-- Remove the shield entity.
minetest.register_on_dieplayer(function(player)
    local name = player:get_player_name()
    local pdata = player_data[name]
    local old_ppd = player_persistent_data[name]

    player_persistent_data[name] = {
        damage_texture_modifier = old_ppd.damage_texture_modifier,
        throw_style = old_ppd.throw_style
    }

    if not pdata then
        return
    end

    local throw_data = pdata.throw
    
    if throw_data then
        drop(player, throw_data.item)
    end

    local entity = pdata.entity

    if entity then
        entity.object:remove()
    end

    local aim = pdata.aim

    if aim then
        -- Drop hand.
        player:set_bone_position(aim.bone, aim.position, new(-180, 0, 0))
    end

    player_data[name] = nil
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
    end

    local data_block = pdata.block

    if data_block and player:get_wielded_item():get_name() ~= data_block.name then
        player_data[name].block = nil

        -- Remove un-used hud element.
        remove_text_center(player, "pvp_revamped:block_pool")
    end
end)

local function break_guard(player, name)
    if not player_data or not player_data[name] then
        return
    end

    local pdata = player_data[name]

    if pdata.shield then
        local on_block_deactivated = pdata.shield.on_block_deactivated

        -- Invoke deactivate block function if any.
        if on_block_deactivated then
            on_block_deactivated(player)
        end

        player_data[name].shield = nil

        -- Remove hud element.
        remove_text_center(player, "pvp_revamped:shield_pool")
    end

    if pdata.block then
        local on_block_deactivated = pdata.block.on_block_deactivated

        -- Invoke deactivate block function if any.
        if on_block_deactivated then
            on_block_deactivated(player)
        end

        player_data[name].block = nil

        -- Remove hud element.
        remove_text_center(player, "pvp_revamped:block_pool")
    end
end

minetest.register_on_placenode(function(pos, newnode, placer)
    if placer then
        local name = placer:get_player_name()
        
        -- Break guard if player placed a node.
        break_guard(placer, name)
    end
end)

minetest.register_on_dignode(function(pos, oldnode, digger)
    if digger then
        local name = digger:get_player_name()
        
        -- Break guard if player dug a node.
        break_guard(digger, name)
    end
end)