-- See if the mod armor_3d is a thing here.
if not minetest.global_exists("armor") then
    return
end

local hasty_guard_duration = pvp_revamped.config.hasty_guard_duration
local get_player_data = pvp_revamped.get_player_data
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local remove_text_center = pvp_revamped.remove_text_center
local get_item_group = minetest.get_item_group
local old_save_armor_inventory = armor.save_armor_inventory
local old_load_armor_inventory = armor.load_armor_inventory

local function get_inventory_armor_shield(player, inv)
    local playername = player:get_player_name()

    -- Create new shield inv data.
    if inv then
        for i, stack in pairs(inv:get_list("armor")) do
            if stack:get_count() == 1 then
                local name = stack:get_name()
                local armor_shield = get_item_group(name, "armor_shield") or 0

                if armor_shield > 0 then
                    local def = stack:get_definition()
                    local groups = def.groups

                    player_persistent_data[playername].inventory_armor_shield = {
                        name = name,
                        index = i,
                        block_pool = groups.block_pool,
                        duration = groups.duration,
                        block_cooldown = groups.block_cooldown,
                        hasty_guard_duration = groups.hasty_guard_duration,
                        groups = groups,
                        on_block_activate = def.on_block_activate,
                        on_block_deactivated = def.on_block_deactivated,
                        on_block_damage = def.on_block_damage,
                        on_guard_break = def.on_guard_break,
                        on_hasty_guard = def.on_hasty_guard
                    }
                    
                    return
                end
            end
        end
    end

    local data = get_player_data(playername)

    data.shield = nil
    player_data[playername] = data
    player_persistent_data[playername].inventory_armor_shield = nil

    -- Remove un-used hud element.
    remove_text_center(player, "pvp_revamped:shield_pool")
end

armor.save_armor_inventory = function(self, player)
    local _, inv = self:get_valid_player(player)
    
    get_inventory_armor_shield(player, inv)
    return old_save_armor_inventory(self, player)
end

armor.load_armor_inventory = function(self, player)
    local _, inv = self:get_valid_player(player)

    get_inventory_armor_shield(player, inv)
    return old_load_armor_inventory(self, player)
end
