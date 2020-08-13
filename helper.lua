local player_data = pvp_revamped.player_data
local add_item = minetest.add_item
local get_player_by_name = minetest.get_player_by_name
local shield_entity_pos = pvp_revamped.config.shield_entity_pos
local shield_entity_rotate = pvp_revamped.config.shield_entity_rotate
local shield_entity_scale = pvp_revamped.config.shield_entity_scale

-- Helper function to drop an item.
function pvp_revamped.drop(player, item, pos)
    if not pos then
        pos = player:get_pos()
    end

    local obj = add_item(pos, item)

    if obj then
        obj:get_luaentity().collect = true
    end
end

function pvp_revamped.get_player_data(name)
    local data = player_data[name] or {}

    if not player_data[name] then
        player_data[name] = data
    end

    return data
end

local get_player_data = pvp_revamped.get_player_data

function pvp_revamped.create_wield_shield(name, bone, itemname, groups)
    local data = get_player_data(name)
    local player = get_player_by_name(name)
    local object = minetest.add_entity(player:get_pos(), "pvp_revamped:shield", name)

    if object then
        object:set_attach(player, bone, groups.shield_entity_pos or shield_entity_pos, groups.shield_entity_rotate or shield_entity_rotate)
        object:set_properties({
            textures = {itemname},
            visual_size = groups.shield_entity_scale or shield_entity_scale,
        })
        
        if data.entity then
            data.entity:remove()
        end

        data.entity = object
    end
end
