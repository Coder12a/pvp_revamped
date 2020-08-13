local projectile_dmg_mul = pvp_revamped.config.projectile_dmg_mul
local projectile_velocity_dmg_mul = pvp_revamped.config.projectile_velocity_dmg_mul
local projectile_step = pvp_revamped.config.projectile_step
local projectile_dist = pvp_revamped.config.projectile_dist
local projectile_dip_velocity_dmg_mul = pvp_revamped.config.projectile_dip_velocity_dmg_mul
local projectile_throw_style_dip = pvp_revamped.projectile_throw_style_dip
local projectile_throw_style_spinning = pvp_revamped.projectile_throw_style_spinning
local projectile_data = pvp_revamped.projectile_data
local registered_tools = minetest.registered_tools
local serialize = minetest.serialize
local deserialize = minetest.deserialize
local raycast = minetest.raycast
local get_player_by_name = minetest.get_player_by_name
local add_item = minetest.add_item
local add = vector.add
local multiply = vector.multiply
local distance = vector.distance
local normalize = vector.normalize
local asin = math.asin
local abs = math.abs
local max = math.max
local min = math.min
local pi = math.pi
local rad45 = pi * 0.25
local rad90 = pi * 0.5

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
    step = 0,
    timer = 0,
    spin_rate = 0,
    throw_style = 0,
    itemstring = "",
    owner = "",
    itemname = "",
    tool_capabilities = nil,

    set_item = function(self, owner, item)
        -- Get the stack from item or itemstring.
        local stack = ItemStack(item or self.itemstring)
        
        self.itemstring = stack:to_string()
       
        if self.itemstring == "" then
			return
		end
        
        local itemname = stack:is_known() and stack:get_name() or "unknown"
        -- Get the name of the stack item.
        local tool_capabilities = registered_tools[itemname].tool_capabilities
        local max_count = stack:get_stack_max()
		local count = min(stack:get_count(), max_count)
        local size = 0.2 + 0.1 * (count / max_count) ^ (1 / 3)
        
        -- Set the entity properties.
        self.object:set_properties({
            is_visible = true,
			visual = "wielditem",
            textures = {itemname},
            visual_size = {x = size, y = size},
			collisionbox = {-size, -size, -size, size, size, size}
        })

        if owner then
            self.owner = owner
        end

        self.tool_capabilities = tool_capabilities
        self.itemname = itemname
        self.step = tool_capabilities.projectile_step or projectile_step
    end,

    throw = function(self, user, speed, acceleration, damage, throw_style, spin_rate)
        local obj = self.object
        local pos = obj:get_pos()
        local velocity = multiply(user:get_look_dir(), speed)

        -- Set the entities speed and gravity.
        obj:set_velocity(velocity)
        obj:set_acceleration(acceleration)
        obj:set_rotation({x = 0, y = user:get_look_horizontal() + rad90, z = asin(-normalize(velocity).y) + rad45})

        -- If no damage value, auto set the damage times projectile_dmg_mul.
        if not damage and self.tool_capabilities and self.tool_capabilities.damage_groups and self.tool_capabilities.damage_groups.fleshy then
            self.tool_capabilities.damage_groups.fleshy = self.tool_capabilities.damage_groups.fleshy * projectile_dmg_mul
        elseif damage and self.tool_capabilities and self.tool_capabilities.damage_groups and self.tool_capabilities.damage_groups.fleshy then
            self.tool_capabilities.damage_groups.fleshy = damage
        end

        if spin_rate then
            self.spin_rate = spin_rate
        end

        self.throw_style = throw_style
        -- Set the hp to the damage.
        self.object:set_hp(max(self.tool_capabilities.damage_groups.fleshy, 1))
    end,
    
    get_staticdata = function(self)
        -- Serialize the entitiy's data.
        return serialize({
            itemstring = self.itemstring,
            itemname = self.itemname,
            owner = self.owner,
            tool_capabilities = self.tool_capabilities,
            throw_style = self.throw_style,
            spin_rate = self.spin_rate,
            step = self.step
        })
    end,
    
    on_activate = function(self, staticdata)
        self.object:set_armor_groups({fleshy = 100})
        
        local data = deserialize(staticdata)
        
        -- Read data only if it is a table.
        if data and type(data) == "table" then
            self.itemstring = data.itemstring
            self.itemname = data.itemname
            self.owner = data.owner
            self.tool_capabilities = data.tool_capabilities
            self.throw_style = data.throw_style
            self.spin_rate = data.spin_rate
            self.step = data.step
        end

        self.timer = self.step

        self:set_item()
    end,

    on_step = function(self, dtime)
        local tool_capabilities = self.tool_capabilities
        local throw_style = self.throw_style
        local object = self.object

        self.timer = self.timer + dtime

        -- Two different throwing styles.
        if throw_style and throw_style == projectile_throw_style_spinning then
            -- This style has the item spining at a fixed rate.
            local old_rotation = object:get_rotation()

            object:set_rotation({x = old_rotation.x, y = old_rotation.y, z = old_rotation.z + self.spin_rate})
        elseif throw_style and throw_style == projectile_throw_style_dip then
            -- This style gives the item a bullet drop effect.
            local old_rotation = object:get_rotation()

            object:set_rotation({x = old_rotation.x, y = old_rotation.y, z = asin(-normalize(object:get_velocity()).y) + rad45})
        end

        if self.timer >= self.step then
            local velocity = object:get_velocity()
            
            local dir = normalize(velocity)
            local pos = object:get_pos()
            local p1 = add(pos, dir)
            local projectile_dist = tool_capabilities.projectile_dist or projectile_dist
            local p2 = add(pos, multiply(dir, projectile_dist))
            local ray = raycast(p1, p2)

            for pointed_thing in ray do
                if pointed_thing.type == "object" then
                    local obj = pointed_thing.ref

                    if obj:get_armor_groups().fleshy then
                        -- Add up the velocity damage.
                        local projectile_velocity_dmg_mul = tool_capabilities.projectile_velocity_dmg_mul or projectile_velocity_dmg_mul

                        if projectile_velocity_dmg_mul and tool_capabilities.damage_groups and tool_capabilities.damage_groups.fleshy then
                            local vv
                            
                            if throw_style and throw_style == projectile_throw_style_dip then
                                local projectile_dip_velocity_dmg_mul = tool_capabilities.projectile_dip_velocity_dmg_mul or projectile_dip_velocity_dmg_mul
                                vv = max(abs(velocity.x * projectile_dip_velocity_dmg_mul.x), abs(velocity.y * projectile_dip_velocity_dmg_mul.y), abs(velocity.z * projectile_dip_velocity_dmg_mul.z))
                            else
                                vv = max(abs(velocity.x), abs(velocity.y), abs(velocity.z))
                            end

                            if vv > 0 then
                                -- Give a damage bonus based on the tool's velocity.
                                tool_capabilities.damage_groups.fleshy = tool_capabilities.damage_groups.fleshy + vv * projectile_velocity_dmg_mul
                            end
                        end

                        -- Set the table for later use in the punch function.
                        projectile_data = {pos = pos, name = self.itemname, dir = dir, velocity = velocity, intersection_point = pointed_thing.intersection_point}

                        obj:punch(get_player_by_name(self.owner), nil, tool_capabilities)
                        self:die()
                        
                        return
                    end
                end
            end

            -- If there is no velocity then drop the item.
            if velocity.y == 0 or velocity.x == 0 and velocity.z == 0 then
                self:die()

                return
            end

            self.timer = 0
        end
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        local object = self.object
        local velocity = object:get_velocity()
        local throw_style = self.throw_style
        local vv
        
        -- Reduce the damage that will be done by the object's velocity.
        if throw_style and throw_style == projectile_throw_style_dip then
            vv = max(abs(velocity.x * projectile_dip_velocity_dmg_mul.x), abs(velocity.y * projectile_dip_velocity_dmg_mul.y), abs(velocity.z * projectile_dip_velocity_dmg_mul.z))
        else
            vv = max(abs(velocity.x), abs(velocity.y), abs(velocity.z))
        end

        if vv > 0 then
            damage = max(damage - vv * projectile_velocity_dmg_mul, 0)
        end

        -- Reduce the item's damage.
        self.tool_capabilities.damage_groups.fleshy = max(self.tool_capabilities.damage_groups.fleshy - damage, 0)
        
        -- Knockback.
        object:add_velocity(multiply(dir, calculate_knockback(puncher, nil, time_from_last_punch, tool_capabilities, dir, distance(object:get_pos(), puncher:get_pos()), damage)))
        object:set_hp(object:get_hp() - damage)
        
        return true
    end,

    die = function(self, pos)
        -- Drop the item while giving it the same velocity.
        if not pos then
            pos = self.object:get_pos()
        end

        local obj = add_item(pos, self.itemstring)

        if obj then
            obj:get_luaentity().collect = true

            obj:set_velocity(self.object:get_velocity())
        end

        self.object:remove()
    end,

    on_death = function(self)
        -- On death drop the item.
        self:die()
    end
})
