local projectile_full_throw_mul = pvp_revamped.config.projectile_full_throw_mul
local projectile_speed_mul = pvp_revamped.config.projectile_speed_mul
local spam_damage = pvp_revamped.config.spam_damage
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
local counter_duration = pvp_revamped.config.counter_duration
local parry_dmg_mul = pvp_revamped.config.parry_dmg_mul
local counter_dmg_mul = pvp_revamped.config.counter_dmg_mul
local get_player_data = pvp_revamped.get_player_data
local create_wield_shield = pvp_revamped.create_wield_shield
local player_data = pvp_revamped.player_data
local player_persistent_data = pvp_revamped.player_persistent_data
local create_hud_text_center = pvp_revamped.create_hud_text_center
local remove_text_center = pvp_revamped.remove_text_center
local shield_inv = pvp_revamped.shield_inv
local registered_tools = minetest.registered_tools
local get_us_time = minetest.get_us_time
local new = vector.new
local max = math.max
local floor = math.floor

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

            tool_capabilities.damage_groups.shield = tool_capabilities.damage_groups.shield or uxml * shield_axe_dmg_mul

            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities and v.tool_capabilities.full_punch_interval then
            -- Calculate the time it takes to fully throw an item at max velocity and damage.
            local tool_capabilities = v.tool_capabilities
            local projectile_full_throw_mul = tool_capabilities.projectile_full_throw_mul or projectile_full_throw_mul

            tool_capabilities.full_throw = tool_capabilities.full_throw or (v.tool_capabilities.full_punch_interval * projectile_full_throw_mul) * 1000000
            
            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities then
            -- Calculate the item throw speed.
            local tool_capabilities = v.tool_capabilities
            local range = v.tool_capabilities.range or 4
            local projectile_speed_mul = tool_capabilities.projectile_speed_mul or projectile_speed_mul

            tool_capabilities.throw_speed = tool_capabilities.throw_speed or range * projectile_speed_mul

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
            local block_pool = tool_capabilities.block_pool or punch_number * block_pool_mul
            local block_interval_mul = tool_capabilities.block_interval_mul or block_interval_mul
            local block_cooldown = tool_capabilities.block_cooldown or (full_punch_interval * block_interval_mul) * 1000000
            local block_duration = tool_capabilities.block_duration or block_duration
            local block_duration_mul = tool_capabilities.block_duration_mul or block_duration_mul
            local duration = tool_capabilities.duration or block_duration + (punch_number * block_duration_mul)
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place
            local old_on_drop = v.on_drop
            local hasty_guard_mul = tool_capabilities.hasty_guard_mul or hasty_guard_mul
            local hasty_guard_duration = tool_capabilities.hasty_guard_duration or hasty_guard_duration
            local on_block_activate = v.on_block_activate
            local on_block_deactivated = v.on_block_deactivated
            local on_block_damage = v.on_block_damage
            local on_guard_break = v.on_guard_break
            local on_hasty_guard = v.on_hasty_guard

            -- Override some custom capabilities if they are nil.
            tool_capabilities.block_pool = tool_capabilities.block_pool or block_pool
            tool_capabilities.duration = tool_capabilities.duration or duration
            tool_capabilities.parry_dmg_mul = tool_capabilities.parry_dmg_mul or parry_dmg_mul
            tool_capabilities.clash_def_mul = tool_capabilities.clash_def_mul or 0.5
            tool_capabilities.counter_dmg_mul = tool_capabilities.counter_dmg_mul or counter_dmg_mul
            tool_capabilities.counter_duration = tool_capabilities.counter_duration or counter_duration
            tool_capabilities.hasty_guard_duration = tool_capabilities.hasty_guard_duration or hasty_guard_duration + punch_number * hasty_guard_mul
            tool_capabilities.spam_damage = tool_capabilities.spam_damage or spam_damage
            
            if block_pool > 0 then
                -- Allow the tool to block damage.
                local function block_action(user)
                    local name = user:get_player_name()
                    local player_pdata = player_persistent_data[name]
                    local data = get_player_data(name)
                    local time = get_us_time()

                    -- Prevent spam blocking.
                    if data.block and time - data.block.initial_time < data.block.block_cooldown then
                        return
                    end

                    if shield_inv(user, name, player_pdata, data) then
                        return
                    end

                    -- Cancel if the player is throwing something, dodging, or rolling.
                    if data.throw or player_pdata.active_dodges or player_pdata.active_barrel_rolls then
                        return
                    end

                    local aim = data.aim

                    data.block = {
                        pool = block_pool,
                        name = k,
                        initial_time = time,
                        time = time,
                        duration = duration,
                        block_cooldown = block_cooldown,
                        hasty_guard_duration = hasty_guard_duration,
                        on_block_activate = on_block_activate,
                        on_block_deactivated = on_block_deactivated,
                        on_block_damage = on_block_damage,
                        on_guard_break = on_guard_break,
                        on_hasty_guard = on_hasty_guard
                    }
                    
                    if aim then
                        user:set_bone_position(aim.bone, aim.position, new(-180, 0, 0))
                    end
                    
                    data.aim = {bone = "Arm_Right", position = new(-3.2, 5.3, 0), rotation = new(-90, 0, 0)}

                    -- Write pool to hud.
                    create_hud_text_center(user, "pvp_revamped:block_pool", block_pool)

                    if data.shield then
                        local on_block_deactivated = data.shield.on_block_deactivated

                        -- Invoke deactivate block function if any.
                        if on_block_deactivated then
                            on_block_deactivated(user)
                        end
                        
                        data.shield = nil

                        -- Remove un-used hud element.
                        remove_text_center(user, "pvp_revamped:shield_pool")
                    end

                    -- Run user on_block_activate function.
                    if on_block_activate then
                        on_block_activate(user)
                    end

                    -- Disable the damage texture modifier on tool block.
                    user:set_properties{damage_texture_modifier = ""}

                    player_data[name] = data
                end

                minetest.override_item(k, {
                on_secondary_use = function(itemstack, user, pointed_thing)
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

                    -- If in the process of throwing, either dig, place, or item name is not the same then return the old function.
                    if throw_data or dropper:get_wielded_item():get_name() ~= name or 
                       (floor(control_bits / 128) % 2 ~= 1 and
                       floor(control_bits / 256) % 2 ~= 1 and
                       floor(control_bits / 512) % 2 ~= 1 and
                       floor(control_bits / 32) % 2 ~= 1) then
                        
                        return old_on_drop(itemstack, dropper, pos)
                    end

                    if data.block then
                        local on_block_deactivated = data.block.on_block_deactivated

                        -- Invoke deactivate block function if any.
                        if on_block_deactivated then
                            on_block_deactivated(dropper)
                        end

                        data.block = nil

                        -- Remove un-used block hud element.
                        remove_text_center(dropper, "pvp_revamped:block_pool")
                    end

                    -- Only clear shield if it is not from the armor inv.
                    if shield_data and not shield_data.armor_inv then
                        local on_block_deactivated = shield_data.on_block_deactivated

                        -- Invoke deactivate block function if any.
                        if on_block_deactivated then
                            on_block_deactivated(dropper)
                        end
                        
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
        elseif v.groups and v.groups.armor_shield then
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
            local block_pool
            local shield_duration = groups.shield_duration or shield_duration
            local duration = groups.duration or shield_duration + (armor_use + value) * shield_duration_mul
            local hasty_shield_mul = groups.hasty_shield_mul or hasty_shield_mul
            local hasty_guard_duration = hasty_guard_duration
            local on_block_activate = v.on_block_activate
            local on_block_deactivated = v.on_block_deactivated
            local on_block_damage = v.on_block_damage
            local on_guard_break = v.on_guard_break
            local on_hasty_guard = v.on_hasty_guard

            if max_armor_use then
                block_pool = groups.block_pool or max_armor_use - armor_use + value * shield_pool_mul
            else
                block_pool = groups.block_pool or 40
            end

            local block_cooldown = groups.block_cooldown or block_pool * 100000

            -- Write new capabilities if they are nil.
            groups.block_pool = groups.block_pool or block_pool
            groups.duration = groups.duration or duration

            if not groups.hasty_guard_duration then
                hasty_guard_duration = hasty_guard_duration + value * hasty_shield_mul
                groups.hasty_guard_duration = hasty_guard_duration
            else
                hasty_guard_duration = groups.hasty_guard_duration
            end

            if block_pool > 0 then
                -- Allow the shield to block damage.
                local function block_action(user)
                    local name = user:get_player_name()
                    local player_pdata = player_persistent_data[name]
                    local data = get_player_data(name)
                    local time = get_us_time()

                    -- Prevent spam blocking.
                    if data.shield and time - data.shield.initial_time < data.shield.block_cooldown then
                        return
                    end

                    if shield_inv(user, name, player_pdata, data) then
                        return
                    end

                    -- Cancel if the player is throwing something, dodging, or rolling.
                    if data.throw or player_pdata.active_dodges or player_pdata.active_barrel_rolls then
                        return
                    end

                    create_wield_shield(user, name, "Arm_Right", k, groups)

                    -- Write pool to hud.
                    create_hud_text_center(user, "pvp_revamped:shield_pool", block_pool)

                    data.shield = {
                        pool = block_pool,
                        name = k,
                        initial_time = time,
                        time = time,
                        duration = duration,
                        block_cooldown = block_cooldown,
                        hasty_guard_duration = hasty_guard_duration,
                        on_block_activate = on_block_activate,
                        on_block_deactivated = on_block_deactivated,
                        on_block_damage = on_block_damage,
                        on_guard_break = on_guard_break,
                        on_hasty_guard = on_hasty_guard
                    }

                    if data.block then
                        local on_block_deactivated = data.block.on_block_deactivated

                        -- Invoke deactivate block function if any.
                        if on_block_deactivated then
                            on_block_deactivated(user)
                        end
                        
                        data.block = nil

                        -- Remove un-used hud element.
                        remove_text_center(user, "pvp_revamped:block_pool")
                    end

                    player_data[name] = data

                    -- Disable the damage texture modifier on shield block.
                    user:set_properties{damage_texture_modifier = ""}

                    -- Run user on_block_activate function.
                    if on_block_activate then
                        on_block_activate(user)
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
