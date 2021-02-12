local get_player_information = minetest.get_player_information
local add_item = minetest.add_item
local get_us_time = minetest.get_us_time
local add_entity = minetest.add_entity
local player_data = pvp_revamped.player_data
local shield_entity_pos = pvp_revamped.config.shield_entity_pos
local shield_entity_rotate = pvp_revamped.config.shield_entity_rotate
local shield_entity_scale = pvp_revamped.config.shield_entity_scale
local armor_3d = minetest.global_exists("armor")
local new = vector.new
local floor = math.floor
local y = 0

-- Get or create player data.
function pvp_revamped.get_player_data(name)
    -- Get or set the table.
    local data = player_data[name] or {}

    if not player_data[name] then
        player_data[name] = data
    end

    return data
end

local get_player_data = pvp_revamped.get_player_data

-- Create the wield shield entity and attach it to the player.
function pvp_revamped.create_wield_shield(player, name, bone, itemname, groups)
    local object = add_entity(player:get_pos(), "pvp_revamped:shield", name)

    if not object or not object:get_luaentity() then
        return
    end

    local data = get_player_data(name)

    object:set_attach(player, bone, groups.shield_entity_pos or shield_entity_pos, groups.shield_entity_rotate or shield_entity_rotate)
    object:set_properties({
        textures = {itemname},
        visual_size = groups.shield_entity_scale or shield_entity_scale
    })

    local entity = data.entity
    
    if entity and entity.object then
        player:set_bone_position(entity.bone, entity.position, new(-180, 0, 0))

        entity.object:remove()
    end

    entity = {object = object, bone = bone, rotation = new(-90, 0, 0)}

    if bone == "Arm_Left" then
        entity.position = new(3.2, 5.3, 0)
    elseif bone == "Arm_Right" then
        entity.position = new(-3.2, 5.3, 0)
    end

    data.entity = entity
end

function pvp_revamped.remove_text_center(player, hud_name)
    if hudkit:exists(player, hud_name) then
        hudkit:remove(player, hud_name)

        y = y - 1
    end
end

function pvp_revamped.create_hud_text_center(player, hud_name, text)
    if not hudkit:exists(player, hud_name) then
        local name = player:get_player_name()

        hudkit:add(player, hud_name, {
            hud_elem_type = "text",
            position = {x = 0, y = 0.59},
            scale = {x = 200, y = 100},
            text = text,
            number = "0x00FF00",
            offset = {x = 800, y = y * 18},
            alignment = {x = 0, y = 0}
        })

        y = y + 1
    else
        hudkit:change(player, hud_name, "text", text)
    end
end

local create_wield_shield = pvp_revamped.create_wield_shield
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center

local function remove_hits(player, name)
    local hit_data = get_player_data(name).hit

    if hit_data then
        for i = #hit_data, 1, -1 do
            local data = hit_data[i]

            -- Restore any lost health.
            if not data.parry then
                player:set_hp(player:get_hp() + data.damage)
            end
        end
    end

    hit_data = nil
end

-- Creates a table with the entry or sets it.
local function add_entry(table, sub, entry, number)
    local t = table[sub]

    if t and not t[number] then
        table[sub][number] = entry

        return true
    elseif not t then
        table[sub] = {[number] = entry}

        return true
    end

    return false
end

function pvp_revamped.clear_blockdata(block, player, name)
    if block then
        local on_block_deactivated = block.on_block_deactivated

        -- Invoke deactivate block function if any.
        if on_block_deactivated then
            on_block_deactivated(player)
        end

        if not name then
            name = player:get_player_name()
        end

        -- Remove block data.
        player_data[name].block = nil

        -- Remove un-used hud element.
        remove_text_center(player, "pvp_revamped:block_pool")
    end
end

function pvp_revamped.clear_shielddata(shield, player, name)
    if shield then
        on_block_deactivated = shield.on_block_deactivated

        -- Invoke deactivate block function if any.
        if on_block_deactivated then
            on_block_deactivated(player)
        end

        if not name then
            name = player:get_player_name()
        end

        -- Remove shield block data.
        player_data[name].shield = nil

        -- Remove un-used hud element.
        remove_text_center(player, "pvp_revamped:shield_pool")
    end
end

local clear_blockdata = pvp_revamped.clear_blockdata
local clear_shielddata = pvp_revamped.clear_shielddata

-- Helper function to check and set the dodge cooldown.
function pvp_revamped.dodge(name, player, number)
    local dodge_data = get_player_data(name)
    
    if add_entry(dodge_data, "dodge", get_us_time(), number) then
        player:set_properties{damage_texture_modifier = ""}
        -- Clear out any hit data on dodge.
        remove_hits(player, name)
        clear_blockdata(dodge_data.block, player, name)
        clear_shielddata(dodge_data.shield, player, name)

        -- Display words invincible to player.
        create_hud_text_center(player, "pvp_revamped:dodge", "INVINCIBLE")
    end
end

-- Helper function to check and set the barrel_roll cooldown.
function pvp_revamped.barrel_roll(name, player, number, x, z)
    local barrel_roll_data = get_player_data(name)

    if add_entry(barrel_roll_data, "barrel_roll", {time = get_us_time(), x = x, z = z}, number) then
        player:set_properties{damage_texture_modifier = ""}
        -- Clear out any hit data on barrel roll.
        remove_hits(player, name)
        clear_blockdata(barrel_roll_data.block, player, name)
        clear_shielddata(barrel_roll_data.shield, player, name)

        -- Display words invincible to player.
        create_hud_text_center(player, "pvp_revamped:barrel_roll", "INVINCIBLE")
    else
        return
    end

    local re_x, re_z = rotate_point(player:get_look_horizontal(), x, z)

    player:add_player_velocity({x = re_x, y = 0, z = re_z})
end

function pvp_revamped.dash(player, name, dash_key, x, y, z)
    local dash_data = get_player_data(name)
    
    if not add_entry(dash_data, "dash", get_us_time(), dash_key) then
        return 
    end
    
    local re_x, re_z = rotate_point(player:get_look_horizontal(), x, z)

    player:add_player_velocity({x = re_x, y = y, z = re_z})
end

function pvp_revamped.restore_hits(hitdata, name, user)
    if hitdata then
        local player_lag = get_player_information(name).avg_jitter * 1000000
        local timeframe = get_us_time() - player_lag

        local count = #hitdata

        for i = count, 1, -1 do
            local hd = hitdata[i]
            
            if hd.time >= timeframe then
                user:set_hp(user:get_hp() + hd.damage)
                
                hitdata[i] = hitdata[count]
                hitdata[count] = nil
            end

            count = count - 1
        end

        return hitdata
    end
end

local restore_hits = pvp_revamped.restore_hits

function pvp_revamped.shield_inv(user, name, player_pdata, data)
    -- Use 3d_armor inv shield if available.
    if armor_3d and player_pdata.inventory_armor_shield and (player_pdata.use_shield or floor(user:get_player_control_bits() / 64) % 2 == 1) then
        local data_shield = player_pdata.inventory_armor_shield
        local time = get_us_time()

        -- Prevent spam blocking.
        if data.shield and time - data.shield.initial_time < data.shield.block_cooldown then
            return false
        end

        local block_pool = data_shield.block_pool
        local on_block_activate = data_shield.on_block_activate or nil

        create_wield_shield(user, name, "Arm_Left", data_shield.name, data_shield.groups)

        -- Write pool to hud.
        create_hud_text_center(user, "pvp_revamped:shield_pool", block_pool)

        data.shield = {
            pool = block_pool,
            name = data_shield.name,
            index = data_shield.index,
            initial_time = time,
            time = time,
            duration = data_shield.duration,
            block_cooldown = data_shield.block_cooldown,
            hasty_guard_duration = data_shield.hasty_guard_duration,
            armor_inv = true,
            on_block_activate = data_shield.on_block_activate,
            on_block_deactivated = data_shield.on_block_deactivated,
            on_block_damage = data_shield.on_block_damage,
            on_guard_break = data_shield.on_guard_break,
            on_hasty_guard = data_shield.on_hasty_guard
        }

        clear_blockdata(data.block, user, name)

        data.hit = restore_hits(data.hit, name, user)

        player_data[name] = data

        user:set_properties{damage_texture_modifier = ""}

        -- Run user func if any.
        if on_block_activate then
            on_block_activate(user)
        end

        return true
    end

    return false
end
