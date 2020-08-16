local projectile_full_throw_mul = pvp_revamped.config.projectile_full_throw_mul
local projectile_speed_mul = pvp_revamped.config.projectile_speed_mul
local shield_axe_dmg_mul = pvp_revamped.config.shield_axe_dmg_mul
local block_pool_mul = pvp_revamped.config.block_pool_mul
local block_interval_mul = pvp_revamped.config.block_interval_mul
local block_duration_mul = pvp_revamped.config.block_duration_mul
local block_duration = pvp_revamped.config.block_duration
local hasty_guard_duration = pvp_revamped.config.hasty_guard_duration
local hasty_guard_mul = pvp_revamped.config.hasty_guard_mul
local hasty_shield_mul = pvp_revamped.config.hasty_shield_mul
local shield_pool_mul = pvp_revamped.config.shield_pool_mul
local shield_duration = pvp_revamped.config.shield_duration
local shield_duration_mul = pvp_revamped.config.shield_duration_mul
local block_duration = pvp_revamped.config.block_duration
local counter_duration = pvp_revamped.config.counter_duration
local parry_dmg_mul = pvp_revamped.config.parry_dmg_mul
local counter_dmg_mul = pvp_revamped.config.counter_dmg_mul
local armor_3d = pvp_revamped.armor_3d
local get_player_data = pvp_revamped.get_player_data
local create_wield_shield = pvp_revamped.create_wield_shield
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center
local use_player_api = pvp_revamped.use_player_api
local registered_tools = minetest.registered_tools
local get_item_group = minetest.get_item_group
local get_us_time = minetest.get_us_time
local new = vector.new
local max = math.max
local floor = math.floor
local set_textures

if use_player_api then
    set_textures = player_api.set_textures
end

minetest.register_on_mods_loaded(function()
    local max_armor_use

    for k, v in pairs(registered_tools) do
        if v.groups and v.groups.armor_use then
            if not max_armor_use or max_armor_use < v.groups.armor_use then
                -- Get the max armor_use.
                max_armor_use = v.groups.armor_use
            end
        end

        if v.tool_capabilities and v.tool_capabilities.groupcaps and v.tool_capabilities.groupcaps.choppy then
            -- Compute the damage an axe would do to a shield.
            local tool_capabilities = v.tool_capabilities
            local choppy = tool_capabilities.groupcaps.choppy
            local uxml = choppy.uses * choppy.maxlevel
            local shield_axe_dmg_mul = tool_capabilities.shield_axe_dmg_mul or shield_axe_dmg_mul

            tool_capabilities.damage_groups.shield = uxml * shield_axe_dmg_mul

            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities and v.tool_capabilities.full_punch_interval then
            -- Calculate the time it takes to fully throw an item at max velocity and damage.
            local tool_capabilities = v.tool_capabilities
            local projectile_full_throw_mul = tool_capabilities.projectile_full_throw_mul or projectile_full_throw_mul

            tool_capabilities.full_throw = (v.tool_capabilities.full_punch_interval * projectile_full_throw_mul) * 1000000
            
            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities then
            -- Calculate the item throw speed.
            local tool_capabilities = v.tool_capabilities
            local range = 4
            local projectile_speed_mul = tool_capabilities.projectile_speed_mul or projectile_speed_mul

            if v.tool_capabilities.range then
                range = v.tool_capabilities.range
            end

            tool_capabilities.throw_speed = range * projectile_speed_mul

            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end
    end

    for k, v in pairs(registered_tools) do
        if not (max_armor_use and v.groups and v.groups.armor_shield) and v.tool_capabilities and v.tool_capabilities.damage_groups.fleshy and v.tool_capabilities.full_punch_interval then
            -- Block feature for tools with combat ability.
            local tool_capabilities = v.tool_capabilities
            local full_punch_interval = tool_capabilities.full_punch_interval
            local punch_number = max(tool_capabilities.damage_groups.fleshy - full_punch_interval, 0.1)
            local block_pool_mul = tool_capabilities.block_pool_mul or block_pool_mul
            local block_pool = punch_number * block_pool_mul
            local block_interval_mul = tool_capabilities.block_interval_mul or block_interval_mul
            local full_block_interval = (full_punch_interval * block_interval_mul) * 1000000
            local block_duration = tool_capabilities.block_duration or block_duration
            local block_duration_mul = tool_capabilities.block_duration_mul or block_duration_mul
            local duration = block_duration + (punch_number * block_duration_mul)
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place
            local old_on_drop = v.on_drop
            local hasty_guard_mul = tool_capabilities.hasty_guard_mul or hasty_guard_mul
            local hasty_guard_duration = tool_capabilities.hasty_guard_duration or hasty_guard_duration
            
            -- Override some custom capabilities if they are nil.
            tool_capabilities.block_pool = tool_capabilities.block_pool or block_pool
            tool_capabilities.duration = tool_capabilities.duration or duration
            tool_capabilities.parry_dmg_mul = tool_capabilities.parry_dmg_mul or parry_dmg_mul
            tool_capabilities.clash_def_mul = tool_capabilities.clash_def_mul or 0.5
            tool_capabilities.counter_dmg_mul = tool_capabilities.counter_dmg_mul or counter_dmg_mul
            tool_capabilities.counter_duration = tool_capabilities.counter_duration or counter_duration
            tool_capabilities.hasty_guard_duration = tool_capabilities.hasty_guard_duration or hasty_guard_duration + punch_number * hasty_guard_mul
            
            if block_pool > 0 then
                -- Allow the tool to block damage.
                local function block_action(user)
                    local name = user:get_player_name()
                    local player_pdata = player_persistent_data[name]
                    local data = get_player_data(name)

                    -- Use 3d_armor inv shield if available.
                    if armor_3d and player_pdata.inventory_armor_shield and (player_pdata.use_shield or floor(user:get_player_control_bits() / 64) % 2 == 1) then
                        local data_shield = player_pdata.inventory_armor_shield
                        local block_pool = data_shield.block_pool
                        local time = get_us_time()

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
                            hasty_guard_duration = data_shield.hasty_guard_duration,
                            armor_inv = true
                        }

                        data.block = nil
                        player_data[name] = data
                        
                        user:set_properties{damage_texture_modifier = ""}

                        -- Remove un-used hud element.
                        remove_text_center(user, "pvp_revamped:block_pool")

                        if use_player_api then
                            local tex_data = armor.textures[name]
                            -- Remove shield from left arm.
                            set_textures(user, {
                                tex_data.skin,
                                tex_data.armor:gsub("%^" .. data_shield.texture .. ".png", ""),
                                tex_data.wielditem
                            })
                        end

                        return
                    end

                    -- Cancel if the player is throwing something, dodging, or rolling.
                    if data.throw or player_pdata.active_dodges or player_pdata.active_barrel_rolls then
                        return
                    end

                    local aim = data.aim
                    local time = get_us_time()

                    -- Prevent spam blocking.
                    if not data.block or time - data.block.time > full_block_interval then
                        data.block = {pool = block_pool, name = k, initial_time = time, time = time, duration = duration, hasty_guard_duration = hasty_guard_duration}
                        
                        if aim then
                            user:set_bone_position(aim.bone, aim.position, new(-180, 0, 0))
                        end
                        
                        data.aim = {bone = "Arm_Right", position = new(-3, 5.7, 0), rotation = new(-90, 0, 0)}

                        -- Write pool to hud.
                        create_hud_text_center(user, "pvp_revamped:block_pool", block_pool)

                        data.shield = nil

                        -- Remove un-used hud element.
                        remove_text_center(user, "pvp_revamped:shield_pool")
                    end

                    -- Disable the damage texture modifier on tool block.
                    user:set_properties{damage_texture_modifier = ""}

                    player_data[name] = data
                end

                minetest.override_item(k, {on_secondary_use = function(itemstack, user, pointed_thing)
                    block_action(user)

                    return old_on_secondary_use(itemstack, user, pointed_thing)
                end, on_place = function(itemstack, placer, pointed_thing)
                    block_action(placer)

                    return old_on_place(itemstack, placer, pointed_thing)
                end, on_drop = function(itemstack, dropper, pos)
                    local name = itemstack:get_name()
                    local player_name = dropper:get_player_name()
                    local control_bits = dropper:get_player_control_bits()
                    local data = get_player_data(player_name)
                    local throw_data = data.throw
                    local shield_data = data.shield

                    -- If in the process of throwing, either LMB, RMB, or item name is not the same then return the old function.
                    if throw_data or dropper:get_wielded_item():get_name() ~= name or (floor(control_bits / 128) % 2 ~= 1 and floor(control_bits / 256) % 2 ~= 1) then 
                        return old_on_drop(itemstack, dropper, pos)
                    end

                    data.block = nil

                    -- Remove un-used block hud element.
                    remove_text_center(dropper, "pvp_revamped:block_pool")

                    -- Only clear shield if it is not from the armor inv.
                    if shield_data and not shield_data.armor_inv then
                        data.shield = nil
                        -- Remove shield pool hud element.
                        remove_text_center(dropper, "pvp_revamped:shield_pool")
                    end

                    -- Tell the player that a toss is being charged up.
                    create_hud_text_center(dropper, "pvp_revamped:throw_item", "CHARGING")

                    throw_data = {name = name, time = get_us_time(), item = itemstack:take_item(), tool_capabilities = registered_tools[name].tool_capabilities}
                    data.throw = throw_data
                    player_data[player_name] = data

                    return itemstack
                end, tool_capabilities = tool_capabilities})
            end
        elseif max_armor_use and v.groups and v.groups.armor_shield then
            -- Block feature for shields.
            local groups = v.groups
            local armor_heal = groups.armor_heal or 0
            local armor_use = groups.armor_use or 0
            local armor_shield = groups.armor_shield or 1
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place
            local fleshy = 1
            
            if v.armor_groups and v.armor_groups.fleshy then
                fleshy = v.armor_groups.fleshy
            end
            
            local value = armor_heal + armor_shield + fleshy
            local shield_pool_mul = groups.shield_pool_mul or shield_pool_mul
            local block_pool = max_armor_use - armor_use + value * shield_pool_mul
            local shield_duration = groups.shield_duration or shield_duration
            local duration = shield_duration + (armor_use + value) * shield_duration_mul
            local hasty_shield_mul = groups.hasty_shield_mul or hasty_shield_mul

            -- Write new capabilities if they are nil.
            groups.block_pool = groups.block_pool or block_pool
            groups.duration = groups.duration or duration
            groups.hasty_guard_duration = groups.hasty_guard_duration or hasty_guard_duration
            groups.hasty_guard_duration = groups.hasty_guard_duration + value * hasty_shield_mul

            if block_pool > 0 then
                -- Allow the shield to block damage.
                local function block_action(user)
                    local name = user:get_player_name()
                    local player_pdata = player_persistent_data[name]
                    local data = get_player_data(name)

                    -- Use 3d_armor inv shield if available.
                    if armor_3d and player_pdata.inventory_armor_shield and (player_pdata.use_shield or floor(user:get_player_control_bits() / 64) % 2 == 1) then
                        local data_shield = player_pdata.inventory_armor_shield
                        local block_pool = data_shield.block_pool
                        local time = get_us_time()

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
                            hasty_guard_duration = data_shield.hasty_guard_duration,
                            armor_inv = true
                        }

                        data.block = nil
                        player_data[name] = data
                        
                        user:set_properties{damage_texture_modifier = ""}

                        -- Remove un-used hud element.
                        remove_text_center(user, "pvp_revamped:block_pool")

                        if use_player_api then
                            local tex_data = armor.textures[name]
                            -- Remove shield from left arm.
                            set_textures(user, {
                                tex_data.skin,
                                tex_data.armor:gsub("%^" .. data_shield.texture .. ".png", ""),
                                tex_data.wielditem
                            })
                        end

                        return
                    end

                    -- Cancel if the player is throwing something, dodging, or rolling.
                    if data.throw or player_pdata.active_dodges or player_pdata.active_barrel_rolls then
                        return
                    end

                    local time = get_us_time()

                    create_wield_shield(user, name, "Arm_Right", k, groups)

                    -- Write pool to hud.
                    create_hud_text_center(user, "pvp_revamped:shield_pool", block_pool)

                    data.shield = {
                        pool = block_pool,
                        name = k,
                        initial_time = time,
                        time = time,
                        duration = duration,
                        hasty_guard_duration = hasty_guard_duration
                    }
                    
                    data.block = nil

                    player_data[name] = data

                    -- Disable the damage texture modifier on shield block.
                    user:set_properties{damage_texture_modifier = ""}

                    -- Remove un-used hud element.
                    remove_text_center(user, "pvp_revamped:block_pool")

                    if use_player_api then
                        local tex_data = armor.textures[name]
                        -- Remove shield from right arm.
                        set_textures(user, {
                            tex_data.skin,
                            tex_data.armor,
                            "3d_armor_trans.png"
                        })
                    end
                end

                minetest.override_item(k, {on_secondary_use = function(itemstack, user, pointed_thing)
                    block_action(user)

                    return old_on_secondary_use(itemstack, user, pointed_thing)
                end, on_place = function(itemstack, placer, pointed_thing)
                    block_action(placer)

                    return old_on_place(itemstack, placer, pointed_thing)
                end, groups = groups})
            end
        end
    end
end)

-- See if the mod armor_3d is a thing here.
if minetest.global_exists("armor") then
    armor_3d = true
    pvp_revamped.armor_3d = armor_3d
    local old_save_armor_inventory = armor.save_armor_inventory
    local old_load_armor_inventory = armor.load_armor_inventory

    armor.save_armor_inventory = function(self, player)
        local _, inv = self:get_valid_player(player)
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
                        local texture = def.texture or name:gsub("%:", "_")
                        texture = texture:gsub(".png$", "")

                        player_persistent_data[playername].inventory_armor_shield = {
                            name = name,
                            index = i,
                            block_pool = groups.block_pool,
                            duration = groups.duration,
                            hasty_guard_duration = groups.hasty_guard_duration,
                            groups = groups,
                            texture = texture
                        }
                        
                        return old_save_armor_inventory(self, player)
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

        return old_save_armor_inventory(self, player)
    end

    armor.load_armor_inventory = function(self, player)
        local _, inv = self:get_valid_player(player)
        local results = old_load_armor_inventory(self, player)
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
                        local texture = def.texture or name:gsub("%:", "_")
                        texture = texture:gsub(".png$", "")

                        player_persistent_data[playername].inventory_armor_shield = {
                            name = name,
                            index = i,
                            block_pool = groups.block_pool,
                            duration = groups.duration,
                            hasty_guard_duration = groups.hasty_guard_duration,
                            groups = groups,
                            texture = texture
                        }
                        
                        return results
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

        return results
    end

    armor.update_player_visuals = function(self, player)
        if not player then
            return
        end

        local name = player:get_player_name()
        local tex_data = self.textures[name]

        if tex_data then
            local tex_armor = tex_data.armor
            local wielditem = tex_data.wielditem
            local shield_data = get_player_data(name).shield
            local inventory_armor_shield = player_persistent_data[name].inventory_armor_shield

            if inventory_armor_shield and shield_data and shield_data.armor_inv then
                tex_armor = tex_armor:gsub("%^" .. inventory_armor_shield.texture .. ".png", "")
            end

            if shield_data and not shield_data.armor_inv then
                wielditem = "3d_armor_trans.png"
            end

            set_textures(player, {
                tex_data.skin,
                tex_armor,
                wielditem
            })
        end

        self:run_callbacks("on_update", player)
    end
end
