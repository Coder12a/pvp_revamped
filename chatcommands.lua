local player_persistent_data = pvp_revamped.player_persistent_data
local projectile_throw_style_dip = pvp_revamped.projectile_throw_style_dip
local projectile_throw_style_spinning = pvp_revamped.projectile_throw_style_spinning

-- Cmd for changing the way you throw items.
minetest.register_chatcommand("throw_style", {
    params = "[<style>]: Change how you throw an item.",
    description = "Change how you throw an item. Accepted values are [none|spin|dip]",
    privs = {
        interact = true,
    },
    func = function(name, param)
        -- Check the given param.
        if param == "none" then
            -- Set the style to none.
            player_persistent_data[name].throw_style = nil
            
            return true, "Throw style set to none."
        elseif param == "spin" then
            -- Give the item a little spin.
            player_persistent_data[name].throw_style = projectile_throw_style_spinning

            return true, "Throw style set to spin."
        elseif param == "dip" then
            -- Bullet drop.
            player_persistent_data[name].throw_style = projectile_throw_style_dip

            return true, "Throw style set to dip."
        end

        -- throw_style cmd help.
        return false, "Only parameters: 'none', 'spin', and 'dip' are accepted."
    end
})

-- See if the mod armor_3d is a thing here.
if minetest.global_exists("armor") then
    -- Cmd for changing the way you block incoming damage.
    minetest.register_chatcommand("use_shield", {
        params = "[<boolean>]: Change how you block incoming damage.",
        description = "If set to true, the shield plate placed in the armor inventory will be used to block all incoming damage when block key is pressed.",
        privs = {
            interact = true,
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
end
