local head_height = 1.35
local torso_height = 0.75
local leg_height = 0.45
local knee_height = 0.375
local block_duration = 100000
local dodge_duration = 350000
local dodge_cooldown = 1500000
local dash_cooldown = 1500000
local dodge_aerial_cooldown = 3000000
local dash_aerial_cooldown = 3000000
local dash_speed = 9.2
local disarm_chance_mul = 2
local leg_stagger_mul = 0.8
local knee_stagger_mul = 1.5
local block_duration_mul = 100000
local block_interval_mul = 0.15
local block_pool_mul = 2
local shield_pool_mul = 4
local block_wear_mul = 9000
local shield_axe_dmg_mul = 20
local head_dmg_mul = 1.2
local torso_dmg_mul = 1.0
local arm_dmg_mul = 0.6
local leg_dmg_mul = 0.7
local front_dmg_mul = nil
local side_dmg_mul = 1.05
local back_dmg_mul = 1.1
local elevated_dmg_mul = 1.5
local equal_height_dmg_mul = nil
local lower_elevation_dmg_mul = 0.9
local velocity_dmg_mul = 0.15
local optimal_distance_dmg_mul = 0.2
local maximum_distance_dmg_mul = 0.1
local optimal_distance_mul = 0.5
local projectile_full_throw_mul = 2
local projectile_speed_mul = 3
local projectile_dmg_mul = 0.5
local projectile_step = 0.15
local projectile_radius = 2
local projectile_throw_style_dip = 1
local projectile_throw_style_spinning = 2
local projectile_gravity = -10
local lag = 0
local player_data = {}

local hit_points = {{x = 0.3, y = 1.2, z = 0, part = 1}, 
        {x = 0, y = 1.2, z = 0, part = 0}, 
        {x = -0.3, y = 1.2, z = 0, part = 1}}

local registered_tools = minetest.registered_tools
local raycast = minetest.raycast
local get_us_time = minetest.get_us_time
local get_player_by_name = minetest.get_player_by_name
local get_player_information = minetest.get_player_information
local serialize = minetest.serialize
local deserialize = minetest.deserialize
local add_item = minetest.add_item
local add_entity = minetest.add_entity
local get_objects_inside_radius = minetest.get_objects_inside_radius
local maxn = table.maxn
local add = vector.add
local multiply = vector.multiply
local subtract = vector.subtract
local distance = vector.distance
local normalize = vector.normalize
local cos = math.cos
local sin = math.sin
local abs = math.abs
local atan = math.atan
local random = math.random
local max = math.max
local min = math.min
local floor = math.floor
local asin = math.asin
local pi = math.pi
local rad45 = pi * 0.25
local rad90 = pi * 0.5
local rad360 = pi * 2

-- Entity for thrown items.
minetest.register_entity("pvp_revamped:projectile", {
	initial_properties = {
        collisionbox = {-0.3, -0.3, -0.3, 0.3, 0.3, 0.3},
        visual_size = {x = 0.4, y = 0.4, z = 0.4},
        visual = "wielditem",
        textures = {""},
        physical = true,
        collide_with_objects = false,
        static_save = false,
        is_visible = false
    },
    timer = 0,
    spin_rate = 0,
    itemstring = "",
    owner = "",
    tool_capabilities = nil,

    set_item = function(self, owner, item)
        local stack = ItemStack(item or self.itemstring)
        
        self.itemstring = stack:to_string()
       
        if self.itemstring == "" then
			return
		end
        
        local itemname = stack:is_known() and stack:get_name() or "unknown"
        local tool_capabilities = registered_tools[stack:get_name()].tool_capabilities
        
        self.object:set_properties({
            is_visible = true,
			visual = "wielditem",
			textures = {itemname}
        })

        if owner then
            self.owner = owner
        end

        self.tool_capabilities = tool_capabilities
    end,

    throw = function(self, user, speed, acceleration, damage, spin_rate)
        local obj = self.object
        local pos = obj:get_pos()
        local velocity = multiply(user:get_look_dir(), speed)

        obj:set_velocity(velocity)
        obj:set_acceleration(acceleration)
        obj:set_rotation({x = 0, y = user:get_look_horizontal() + rad90, z = asin(-normalize(velocity).y) + rad45})

        if not damage and self.tool_capabilities and self.tool_capabilities.damage_groups and self.tool_capabilities.damage_groups.fleshy then
            self.tool_capabilities.damage_groups.fleshy = self.tool_capabilities.damage_groups.fleshy * projectile_dmg_mul
        elseif damage and self.tool_capabilities and self.tool_capabilities.damage_groups and self.tool_capabilities.damage_groups.fleshy then
            self.tool_capabilities.damage_groups.fleshy = damage
        end

        if spin_rate then
            self.spin_rate = spin_rate
        end

        self.timer = -1 / speed
    end,
    
    get_staticdata = function(self)
        return serialize({
            itemstring = self.itemstring,
            owner = self.owner,
            tool_capabilities = self.tool_capabilities,
            spin_rate = self.spin_rate
        })
    end,
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
        
        local data = deserialize(staticdata)
        
        if data and type(data) == "table" then
            self.itemstring = data.itemstring
            self.owner = data.owner
            self.tool_capabilities = data.tool_capabilities
            self.spin_rate = spin_rate
        end

        self.timer = 0

        self:set_item()
    end,

    on_step = function(self, dtime)
        local tool_capabilities = self.tool_capabilities
        local throw_style = tool_capabilities.throw_style
        local object = self.object

        self.timer = self.timer + dtime

        if throw_style and throw_style == projectile_throw_style_spinning then
            local old_rotation = object:get_rotation()

            object:set_rotation({x = old_rotation.x, y = old_rotation.y, z = old_rotation.z + self.spin_rate})
        elseif throw_style and throw_style == projectile_throw_style_dip then
            local old_rotation = object:get_rotation()

            object:set_rotation({x = old_rotation.x, y = old_rotation.y, z = asin(-normalize(object:get_velocity()).y) + tool_capabilities.flip})
        end

        if self.timer >= projectile_step then
            local velocity = object:get_velocity()
            
            if velocity.y == 0 or velocity.x == 0 and velocity.z == 0 then
                self:die()

                return
            end

            for _, target in pairs(get_objects_inside_radius(object:get_pos(), projectile_radius)) do
                if target:get_armor_groups().fleshy then
                    target:punch(get_player_by_name(self.owner), nil, tool_capabilities, nil)
                    self:die()
                    
                    return
                end
            end

            self.timer = 0
        end
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        -- If this item was punched drop it.
        if puncher and puncher:is_player() and puncher:get_player_name() ~= self.owner then
            self:die()
        end
    end,

    die = function(self, pos)
        -- On death drop the item.
        if not pos then
            pos = self.object:get_pos()
        end

        local obj = add_item(pos, self.itemstring)

        if obj then
            obj:get_luaentity().collect = true

            obj:set_velocity(self.object:get_velocity())
        end

        self.object:remove()
    end
})

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

            tool_capabilities.damage_groups.shield_dmg = uxml * shield_axe_dmg_mul
            tool_capabilities.throw_style = projectile_throw_style_spinning

            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities and v.tool_capabilities.full_punch_interval then
            -- Calculate the time it takes to fully throw an item at max velocity and damage.
            local tool_capabilities = v.tool_capabilities

            tool_capabilities.full_throw = (v.tool_capabilities.full_punch_interval * projectile_full_throw_mul) * 1000000
            
            minetest.override_item(k, {tool_capabilities = tool_capabilities})
        end

        if v.tool_capabilities then
            -- Calculate the item throw speed.
            local tool_capabilities = v.tool_capabilities
            local range = 4

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
            local block_pool = punch_number * block_pool_mul
            local full_block_interval = (full_punch_interval * block_interval_mul) * 1000000
            local duration = block_duration + (punch_number * block_duration_mul)
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place
            local old_on_drop = v.on_drop
            
            if block_pool > 0 then
                -- Allow the tool to block damage.
                local block_action = function(user)
                    local time = get_us_time()
                    local name = user:get_player_name()
                    local data = player_data[name].block

                    -- Prevent spam blocking.
                    if not data or time - data.time > full_block_interval then
                        data = {pool = block_pool, time = time, duration = duration}
                    end

                    -- Disable the damage texture modifier on tool block.
                    user:set_properties{damage_texture_modifier = ""}

                    player_data[name].block = data
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
                    local throw_data = player_data[player_name].throw

                    -- If in the process of throwing, either LMB, RMB, or item name is not the same then return the old function.
                    if throw_data or dropper:get_wielded_item():get_name() ~= name or (floor(control_bits / 128) % 2 ~= 1 and floor(control_bits / 256) % 2 ~= 1) then 
                        return old_on_drop(itemstack, dropper, pos)
                    end

                    throw_data = {name = name, time = get_us_time(), item = itemstack:take_item(), tool_capabilities = registered_tools[name].tool_capabilities}
                    player_data[player_name].throw = throw_data

                    return itemstack
                end})
            end
        elseif max_armor_use and v.groups and v.groups.armor_shield then
            -- Block feature for shields.
            local armor_heal = v.groups.armor_heal or 0
            local armor_use = v.groups.armor_use or 0
            local armor_shield = v.groups.armor_shield or 1
            local old_on_secondary_use = v.on_secondary_use
            local old_on_place = v.on_place
            local fleshy = 1
            
            if v.armor_groups and v.armor_groups.fleshy then
                fleshy = v.armor_groups.fleshy
            end
            
            local block_pool = (max_armor_use - armor_use + armor_heal + armor_shield + fleshy) * shield_pool_mul

            if block_pool > 0 then
                -- Allow the shield to block damage.
                local block_action = function(user)
                    local name = user:get_player_name()
                    local data = player_data[name].shield

                    data = {name = k, pool = block_pool}
                    
                    -- Disable the damage texture modifier on shield block.
                    user:set_properties{damage_texture_modifier = ""}

                    player_data[name].shield = data
                end

                minetest.override_item(k, {on_secondary_use = function(itemstack, user, pointed_thing)
                    block_action(user)

                    return old_on_secondary_use(itemstack, user, pointed_thing)
                end, on_place = function(itemstack, placer, pointed_thing)
                    block_action(placer)

                    return old_on_place(itemstack, placer, pointed_thing)
                end})
            end
        end
    end
end)

minetest.register_globalstep(function(dtime)
    lag = dtime * 1000000

    for k, v in pairs(player_data) do
        local server_lag = lag + get_player_information(k).avg_jitter * 1000000
        local player = get_player_by_name(k)

        if v.block then
            -- Check if the player is holding down the RMB key.
            if floor(player:get_player_control_bits() / 256) % 2 == 1 then
                -- Update the block time.
                player_data[k].block.time = get_us_time()
            end

            local block = v.block
            
            -- Remove the block table if it's past duration.
            if block.time + block.duration + server_lag < get_us_time() then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = player_data[k].damage_texture_modifier}
                player_data[k].block = nil
            end
        end

        if v.throw then
            local control_bits = player:get_player_control_bits()
            
            if floor(control_bits / 128) % 2 ~= 1 and floor(control_bits / 256) % 2 ~= 1 then
                local pos = player:get_pos()

                pos.y = pos.y + player:get_properties().eye_height
                
                local obj = add_entity(pos, "pvp_revamped:projectile")
                local ent = obj:get_luaentity()

                if ent then
                    local throw_data = v.throw
                    local tool_capabilities = throw_data.tool_capabilities
                    local throw_speed = tool_capabilities.throw_speed
                    local damage = tool_capabilities.damage_groups.fleshy
                    local time = get_us_time()
                    local full_throw = throw_data.time + tool_capabilities.full_throw
                    local spin

                    if full_throw > time then
                        local re = (full_throw - time) / 200000

                        if re > 0.5 then
                            damage = tool_capabilities.damage_groups.fleshy - re
                            throw_speed = throw_speed - re
                        end
                    end

                    if tool_capabilities.throw_style == projectile_throw_style_spinning then
                        spin = throw_speed
                    end

                    ent:set_item(player:get_player_name(), throw_data.item)
                    ent:throw(player, throw_speed, {x = 0, y = projectile_gravity, z = 0}, damage * projectile_dmg_mul, spin)
                end

                player_data[k].throw = nil
            end
        end

        if v.stagger then
            local stagger = v.stagger

            -- Check if the stagger duration expired. 
            if stagger.time + stagger.value + server_lag < get_us_time() then
                -- Restore the player's physics.
                get_player_by_name(k):set_physics_override({speed = 1, jump = 1})
                player_data[k].stagger = nil
            end
        end

        if v.dodge then
            local active_dodges = 0
            
            -- Process the player's dodge table cooldown.
            for j, l in pairs(v.dodge) do
                -- Find if it's aerial or not.
                if j > 4 and l + dodge_aerial_cooldown + server_lag < get_us_time() then
                    player_data[k].dodge[j] = nil
                elseif j < 5 and l + dodge_cooldown + server_lag < get_us_time() then
                    player_data[k].dodge[j] = nil
                elseif l + dodge_duration + server_lag > get_us_time() then
                    active_dodges = active_dodges + 1
                end
            end

            if active_dodges < 1 and player:get_properties().damage_texture_modifier == "" then
                -- Revert the damage texture modifier.
                player:set_properties{damage_texture_modifier = player_data[k].damage_texture_modifier}
            end
            
            -- If this table contains no more dodges remove it.
            if maxn(player_data[k].dodge) < 1 then
                player_data[k].dodge = nil
            end
        end

        if v.dash then
            -- Process the player's dash table cooldown.
            for j, l in pairs(v.dash) do
                -- Find if it's aerial or not.
                if j > 4 and l + dash_aerial_cooldown + server_lag < get_us_time() then
                    player_data[k].dash[j] = nil
                elseif j < 5 and l + dash_cooldown + server_lag < get_us_time() then
                    player_data[k].dash[j] = nil
                end
            end

            -- If this table contains no more dashes remove it.
            if maxn(player_data[k].dash) < 1 then
                player_data[k].dash = nil
            end
        end
    end
end)

if sscsm then
    -- Register a sscsm for dodging and dashing.
    sscsm.register({name = "pvp_revamped:movement",
                    file = minetest.get_modpath("pvp_revamped") .. "/movement.lua"})

    -- Helper function to check and set the dodge cooldown.
    local function dodge(name, player, number)
        local dodge_data = player_data[name]
        
        if not dodge_data.dodge then
            dodge_data.dodge = {[number] = get_us_time()}
            player:set_properties{damage_texture_modifier = ""}
        elseif dodge_data.dodge and not dodge_data.dodge[number] then
            dodge_data.dodge[number] = get_us_time()
            player:set_properties{damage_texture_modifier = ""}
        end
    end

    -- Channel for dodge request.
    sscsm.register_on_com_receive("pvp_revamped:dodge", function(name, msg)
        if msg and type(msg) == "string" then
            local player = get_player_by_name(name)
            local velocity = player:get_player_velocity().y
            local aerial_points = 0

            if velocity < 0.0 or velocity > 0.0 then
                aerial_points = 4
            end

            if msg == "dodge_l" then
                dodge(name, player, 1 + aerial_points)
            elseif msg == "dodge_u" then
                dodge(name, player, 2 + aerial_points)
            elseif msg == "dodge_r" then
                dodge(name, player, 3 + aerial_points)
            elseif msg == "dodge_d" then
                dodge(name, player, 4 + aerial_points)
            else
                return false
            end
        end
    end)

    -- Channel for dash request.
    sscsm.register_on_com_receive("pvp_revamped:dash", function(name, msg)
        if msg and type(msg) == "string" then
            local player = get_player_by_name(name)
            local yaw = player:get_look_horizontal()
            local y = dash_speed * 0.5
            local aerial_points = 0
            local dash_key = 0
            local x = 0
            local z = 0

            local velocity = player:get_player_velocity().y

            if velocity < 0.0 or velocity > 0.0 then
                aerial_points = 4
            end

            if msg == "dash_l" then
                x = -dash_speed
                dash_key = 1 + aerial_points
            elseif msg == "dash_u" then
                z = dash_speed
                dash_key = 2 + aerial_points
            elseif msg == "dash_r" then
                x = dash_speed
                dash_key = 3 + aerial_points
            elseif msg == "dash_d" then
                z = -dash_speed
                dash_key = 4 + aerial_points
            else
                return false
            end

            local dash_data = player_data[name]

            local function dash()
                local co = cos(yaw)
                local si = sin(yaw)
                local re_x = co * x - si * z
                local re_z = si * x + co * z

                player:add_player_velocity({x = re_x, y = y, z = re_z})
            end

            if not dash_data.dash then
                dash()

                dash_data.dash = {[dash_key] = get_us_time()}
            elseif dash_data.dash and not dash_data.dash[dash_key] then
                dash()

                dash_data.dash[dash_key] = get_us_time()
            end
        end
    end)
end

-- Create an empty data sheet for the player.
minetest.register_on_joinplayer(function(player)
    player_data[player:get_player_name()] = {damage_texture_modifier = player:get_properties().damage_texture_modifier}
end)

-- Helper function to drop an item.
local function drop(player, item, pos)
    if not pos then
        pos = player:get_pos()
    end

    local obj = add_item(pos, item)

    if obj then
        obj:get_luaentity().collect = true
    end
end

-- Clear up memory if the player leaves.
-- Drop any item the player is about to throw on leave.
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local throw_data = player_data[name].throw
    
    if throw_data then
        drop(player, throw_data.item)
        
        player_data[name].throw = nil
    end

    player_data[name] = nil
end)

-- Drop any item the player is about to throw on death.
minetest.register_on_dieplayer(function(player)
    local name = player:get_player_name()
    local throw_data = player_data[name].throw
    
    if throw_data then
        drop(player, throw_data.item)
        
        player_data[name].throw = nil
    end
end)

-- Drop any item the player is about to throw on shutdown.
minetest.register_on_shutdown(function()
    for k, v in pairs(player_data) do
        local throw_data = v.throw

        if throw_data then
            drop(player, throw_data.item)

            player_data[k].throw = nil
        end
    end
end)

-- Do the damage calculations when the player gets hit.
minetest.register_on_punchplayer(function(player, hitter, time_from_last_punch, tool_capabilities, dir, damage)
    local name = player:get_player_name()
    local data_dodge = player_data[name].data_dodge
    local time = get_us_time()

    -- If the player is dodging return true.
    if data_dodge then
        for k, v in pairs(data_dodge) do
            if v + dodge_duration + lag > time then
                return true
            end
        end
    end

    local hitter_name = hitter:get_player_name()
    local hitter_data_dodge = player_data[hitter_name].data_dodge
    
    -- Cancel any attack if the hitter is in dodge mode.
    if hitter_data_dodge then
        for k, v in pairs(hitter_data_dodge) do
            if v + dodge_duration + lag > time then
                return true
            end
        end
    end
    
    local pos1 = hitter:get_pos()
    local pos2 = player:get_pos()
    local hitter_pos = {x = pos1.x, y = pos1.y, z = pos1.z}
    local item = registered_tools[hitter:get_wielded_item():get_name()]
    local range = 4
    local yaw = player:get_look_horizontal()
    local front
    local side
    local arm
    local leg
    local knee
    local re_yaw
    local full_punch
    local full_punch_interval = 1.4

    if item and item.range then
        range = item.range
    end

    -- Get whether this was a full punch.
    if tool_capabilities and time_from_last_punch >= tool_capabilities.full_punch_interval then
        full_punch = true
        full_punch_interval = tool_capabilities.full_punch_interval
    elseif tool_capabilities then
        full_punch_interval = tool_capabilities.full_punch_interval
    end

    -- Raise the position to eye height.
    hitter_pos.y = hitter_pos.y + hitter:get_properties().eye_height
    
    -- Get the second position from the direction of the hitter.
    local _dir = hitter:get_look_dir()
    local hit_pos1 = add(hitter_pos, _dir)
    local hit_pos2 = add(hit_pos1, multiply(_dir, range))
    local ray = raycast(hit_pos1, hit_pos2):next()

    if ray then
        local hit_point = ray.intersection_point
        local newpos = subtract(hit_point, pos2)
        local y1 = hit_point.y
        local y2 = pos2.y

        if head_height and head_dmg_mul and y1 > y2 + head_height then
            -- If the player was hit in the head add extra damage.
            damage = damage * head_dmg_mul
        elseif torso_height and y1 > y2 + torso_height then
            -- Find if the player was hit in the torso or arm.
            local near_part = 0
            local past_distance = -1

            for _, point in pairs(hit_points) do
                local x = point.x
                local y = point.y
                local z = point.z
                local co = cos(yaw)
                local si = sin(yaw)
                local re_x = co * x - si * z
                local re_z = si * x + co * z
                local dist = distance(newpos, {x = re_x, y = y, z = re_z})
                
                if dist < past_distance or past_distance == -1 then
                    past_distance = dist
                    near_part = point.part
                end
            end

            if near_part == 1 then
                -- Hit in the arm.
                arm = true

                if arm_dmg_mul then
                    damage = damage * arm_dmg_mul
                end
            elseif torso_dmg_mul then
                -- Hit in the torso.
                damage = damage * torso_dmg_mul
            end
        elseif leg_height and y1 > y2 + leg_height then
            -- Hit in the leg.
            leg = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        elseif knee_height and y1 > y2 + knee_height then
            -- Hit in the knee.
            knee = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        else
            -- Hit in the lower leg.
            leg = true

            if leg_dmg_mul then
                damage = damage * leg_dmg_mul
            end
        end

        local dist = distance(hitter_pos, pos2)
        local optimal_range = range * optimal_distance_mul
        local dist_rounded = dist + 0.5 - (dist + 0.5) % 1

        -- If the distance rounded is outside the range skip.
        if dist_rounded <= range + 1 then
        
            -- Add or remove damage based on the distance.
            -- Full punches are not affected by maximum distance.
            if not full_punch and optimal_distance_mul and maximum_distance_dmg_mul and dist_rounded > optimal_range then
                damage = damage - range * maximum_distance_dmg_mul
            elseif optimal_distance_mul and optimal_distance_dmg_mul and dist_rounded < optimal_range then
                damage = damage + optimal_range - dist_rounded * optimal_distance_dmg_mul
            end
        end

        -- Get the yaw from both the player and intersection point.
        local yaw2 = atan(newpos.z / newpos.x) + rad90
        
        if hit_point.x >= pos2.x then
            yaw2 = yaw2 + pi
        end

        re_yaw = rad360 - (yaw - yaw2)

        if re_yaw < 0 then
            re_yaw = rad360 - re_yaw
        end

        if re_yaw > rad360 then
            re_yaw = re_yaw - rad360
        end

        if (re_yaw <= 0.7853982 and re_yaw >= 0) or (re_yaw <= 6.283185 and re_yaw >= 5.497787) then
            -- Hit on the front.
            front = true

            if front_dmg_mul then
                damage = damage * front_dmg_mul
            end
        elseif re_yaw <= 2.356194 then
            -- Hit on the left-side.
            side = true

            if side_dmg_mul then
                damage = damage * side_dmg_mul
            end
        elseif back_dmg_mul and re_yaw <= 3.926991 then
            -- Hit on the back-side.
            damage = damage * back_dmg_mul
        else
            -- Hit on the right-side.
            side = true

            if side_dmg_mul then
                damage = damage * side_dmg_mul
            end
        end

        -- You can only hit the knee-caps in the front.
        if side and knee then
            knee = nil
            leg = true
        end
        
    end

    if elevated_dmg_mul and pos1.y > pos2.y then
        -- Give a damage bonus or drawback to the aggressor if they are above the victim.
        damage = damage * elevated_dmg_mul
    elseif lower_elevation_dmg_mul and pos1.y < pos2.y then
        -- Give a damage bonus or drawback to the aggressor if they are below the victim.
        damage = damage * lower_elevation_dmg_mul
    elseif equal_height_dmg_mul then
        -- Give a damage bonus or drawback to the aggressor if they are equal footing with the victim.
        damage = damage * equal_height_dmg_mul
    end
    
    -- This damage bonus can only be used if this is a full interval punch.
    if full_punch and velocity_dmg_mul then
        local v1 = hitter:get_player_velocity()
        local vv
        if front then
            -- Ignore the victim's speed if you hit them in the front.
            vv = abs(v1.x) + abs(v1.y) + abs(v1.z)
        else
            -- Subtract the victim's velocity from the aggressor if they where not hit in the front.
            local v2 = player:get_player_velocity()
            vv = abs(v1.x) - abs(v2.x) + abs(v1.y) - abs(v2.y) + abs(v1.z) - abs(v2.z)
        end
        if vv > 0 then
            -- Give a damage bonus to the aggressor based on how fast they are running.
            damage = damage + vv * velocity_dmg_mul
        end
    end

    -- If damage is at or below zero set it to a default value.
    damage = max(damage, 0.5)

    -- Remove the hitter's blocking data.
    player_data[hitter_name].block = nil
    player_data[hitter_name].shield = nil

    local data_block = player_data[name].block
    local hp = player:get_hp()
    local wielded_item = player:get_wielded_item()
    local item_name = wielded_item:get_name()

    -- Process if the player is blocking with a tool or not.
    if front and data_block and data_block.pool > 0 and data_block.time + data_block.duration + lag + max(get_player_information(name).avg_jitter - get_player_information(hitter_name).avg_jitter, 0) * 1000000 > time then
        -- Block the damage and add it as wear to the tool.
        wielded_item:add_wear(((damage - full_punch_interval) / 75) * block_wear_mul)
        player:set_wielded_item(wielded_item)
        data_block.pool = data_block.pool - damage

        -- Remove block table if pool is zero or below.
        if data_block.pool <= 0 then
            player_data[name].block = nil
            return true
        end

        player_data[name].block = data_block
        return true
    elseif data_block then
        -- Revert the damage texture modifier.
        player:set_properties{damage_texture_modifier = player_data[name].damage_texture_modifier}
        -- Block attempt failed.
        player_data[name].block = nil
    end

    local data_shield = player_data[name].shield

    -- Process if the player is blocking with a shield or not.
    if data_shield and data_shield.pool > 0 and data_shield.name == item_name and (front or side) then
        -- Block the damage and add it as wear to the tool.
        local axe_wear = 0

        if tool_capabilities and tool_capabilities.damage_groups and tool_capabilities.damage_groups.shield_dmg then
            axe_wear = tool_capabilities.damage_groups.shield_dmg
        end

        wielded_item:add_wear((((damage - full_punch_interval) / 75) * block_wear_mul) + axe_wear)
        player:set_wielded_item(wielded_item)
        data_shield.pool = data_shield.pool - (damage + axe_wear)

        -- Remove shield table if pool is zero or below.
        if data_shield.pool <= 0 then
            player_data[name].shield = nil
            return true
        end

        player_data[name].shield = data_shield
        return true
    elseif data_shield then
        -- Revert the damage texture modifier.
        player:set_properties{damage_texture_modifier = player_data[name].damage_texture_modifier}
        -- Shield block attempt failed.
        player_data[name].shield = nil
    end

    -- Process if the player was hit in the arm.
    if arm then
        local item2 = registered_tools[item_name]
        local chance
        
        if item2 and not data_shield and not data_block and item2.tool_capabilities and item2.tool_capabilities.damage_groups.fleshy and item2.tool_capabilities.full_punch_interval then
            -- Compute the chance to disarm by the victim's hp and tool stats.
            chance = random(0, ((hp + (item2.tool_capabilities.damage_groups.fleshy - item2.tool_capabilities.full_punch_interval) * disarm_chance_mul) - damage) + 1)
        elseif not item2 and not data_shield and not data_block then
            -- Compute the chance to disarm by the victim's hp.
            chance = random(0, (hp - damage) + 1)
        end

        -- Disarm the player if chance equals zero.
        if chance and chance <= 0 then
            local drop_item = wielded_item:take_item()
            local obj = add_item(pos2, drop_item)

            if obj then
                obj:get_luaentity().collect = true
            end

            player:set_wielded_item(wielded_item)
        end
    end

    local function set_stagger_data(speed)
        player:set_physics_override({speed = speed, jump = speed})

        data_stagger = {}
        data_stagger.time = time
        data_stagger.value = (1 / speed) * 500000
        player_data[name].stagger = data_stagger
    end

    -- Process if the player was hit in the leg.
    if leg then
        -- Stagger the player.
        local speed = min(1 / max(damage - hp, 1) * leg_stagger_mul, 0.1)
        local data_stagger = player_data[name].stagger

        if not data_stagger or data_stagger.value > speed then
            set_stagger_data(speed)
        end
    elseif knee then
        -- Stagger the player.
        local speed = min(1 / max(damage - hp, 1.5) * knee_stagger_mul, 0.1)
        local data_stagger = player_data[name].stagger

        if data_stagger then
            -- Add the original value and update all stagger data.
            speed = min(abs(speed - data_stagger.value), 0.1)

            set_stagger_data(speed)
        else
            set_stagger_data(speed)
        end
    end

    -- Damage the player.
    player:set_hp(hp - damage, "punch")

    return true
end)
