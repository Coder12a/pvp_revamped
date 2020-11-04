local get_player_by_name = minetest.get_player_by_name
local player_persistent_data = pvp_revamped.player_persistent_data
local projectile_throw_style_dip = pvp_revamped.projectile_throw_style_dip
local projectile_throw_style_spinning = pvp_revamped.projectile_throw_style_spinning

-- Cmd for changing the way you throw items.
minetest.register_chatcommand("throw_style", {
    params = "[<style>]: Change how you throw an item.",
    description = "Change how you throw an item. Accepted values are [none|spin|dip]",
    privs = {
        interact = true
    },
    func = function(name, param)
        -- Check the given param.
        if param == "none" then
            -- Set the style to none.
            player_persistent_data[name].throw_style = nil
            get_player_by_name(name):get_meta():set_int("pvp_revamped.throw_style", 0)
            
            return true, "Throw style set to none."
        elseif param == "spin" then
            -- Give the item a little spin.
            player_persistent_data[name].throw_style = projectile_throw_style_spinning
            get_player_by_name(name):get_meta():set_int("pvp_revamped.throw_style", projectile_throw_style_spinning)

            return true, "Throw style set to spin."
        elseif param == "dip" then
            -- Bullet drop.
            player_persistent_data[name].throw_style = projectile_throw_style_dip
            get_player_by_name(name):get_meta():set_int("pvp_revamped.throw_style", projectile_throw_style_dip)

            return true, "Throw style set to dip."
        end

        -- throw_style cmd help.
        return false, "Only parameters: 'none', 'spin', and 'dip' are accepted."
    end
})

-- Cmd to give you movement items.
minetest.register_chatcommand("move_item", {
    params = "[<item>]: Gives you a movement item.",
    description = "Gives you a movement item. Accepted values are [dodge|dash_left|dash_up|dash_right|dash_down|dash_all|roll_left"
                  .. "|roll_up|roll_right|roll_down|roll_all|all]",
    privs = {
        interact = true
    },
    func = function(name, param)
        local inv = get_player_by_name(name):get_inventory()
        
        -- Check the given param.
        if param == "dodge" then
            inv:add_item("main", "pvp_revamped:dodge")

            return true
        elseif param == "dash_left" then
            inv:add_item("main", "pvp_revamped:dash_left")

            return true
        elseif param == "dash_up" then
            inv:add_item("main", "pvp_revamped:dash_up")

            return true
        elseif param == "dash_right" then
            inv:add_item("main", "pvp_revamped:dash_right")

            return true
        elseif param == "dash_down" then
            inv:add_item("main", "pvp_revamped:dash_down")

            return true
        elseif param == "dash_all" then
            inv:add_item("main", "pvp_revamped:dash_left")
            inv:add_item("main", "pvp_revamped:dash_up")
            inv:add_item("main", "pvp_revamped:dash_right")
            inv:add_item("main", "pvp_revamped:dash_down")

            return true
        elseif param == "roll_left" then
            inv:add_item("main", "pvp_revamped:roll_left")

            return true
        elseif param == "roll_up" then
            inv:add_item("main", "pvp_revamped:roll_up")

            return true
        elseif param == "roll_right" then
            inv:add_item("main", "pvp_revamped:roll_right")

            return true
        elseif param == "roll_down" then
            inv:add_item("main", "pvp_revamped:roll_down")

            return true
        elseif param == "roll_all" then
            inv:add_item("main", "pvp_revamped:roll_left")
            inv:add_item("main", "pvp_revamped:roll_up")
            inv:add_item("main", "pvp_revamped:roll_right")
            inv:add_item("main", "pvp_revamped:roll_down")

            return true
        elseif param == "all" then
            inv:add_item("main", "pvp_revamped:dodge")
            inv:add_item("main", "pvp_revamped:dash_left")
            inv:add_item("main", "pvp_revamped:dash_up")
            inv:add_item("main", "pvp_revamped:dash_right")
            inv:add_item("main", "pvp_revamped:dash_down")
            inv:add_item("main", "pvp_revamped:roll_left")
            inv:add_item("main", "pvp_revamped:roll_up")
            inv:add_item("main", "pvp_revamped:roll_right")
            inv:add_item("main", "pvp_revamped:roll_down")

            return true
        end

        return false, "Only parameters: 'dodge', 'dash_left', 'dash_up', 'dash_right', 'dash_down', 'dash_all',\n"
                      .. "'roll_left', 'roll_up', 'roll_right', 'roll_down', 'roll_all', and 'all' are accepted."
    end
})

-- See if the mod armor_3d is a thing here.
if minetest.global_exists("armor") then
    return
end

-- Cmd for changing the way you block incoming damage.
minetest.register_chatcommand("use_shield", {
    params = "[<boolean>]: Change how you block incoming damage.",
    description = "If set to true, the shield plate placed in the armor inventory will be used to block all incoming damage when block key is pressed.",
    privs = {
        interact = true
    },
    func = function(name, param)
        -- Check the given param.
        if param == "true" then
            -- block key will now use the shield in the armor inv to block any incoming damage.
            player_persistent_data[name].use_shield = true
            
            return true, "Shield from armor inventory will now be used to block damage."
        elseif param == "false" then
            -- block key will now use whatever tool selected to block any incoming damage.
            player_persistent_data[name].use_shield = nil

            return true, "Tools will now be used to block damage."
        end

        -- use_shield cmd help.
        return false, "Only parameters: 'true', and 'false' are accepted."
    end
})
