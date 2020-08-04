local get_player_control = sscsm.get_player_control
local com_send = sscsm.com_send
local max = math.max
local last_control = {}
local timer = 0
local timer_max = 0.15
local dodge = 0
local barrel_roll_l = 0
local barrel_roll_u = 0
local barrel_roll_r = 0
local barrel_roll_d = 0
local dash_l = 0
local dash_u = 0
local dash_r = 0
local dash_d = 0

minetest.register_globalstep(function(dtime)
    local control = get_player_control()
    timer = timer + dtime

    if control.sneak then
        if control.left and not last_control.left then
            dash_l = dash_l + 1
            timer = 0
        end

        if control.up and not last_control.up then
            dash_u = dash_u + 1
            timer = 0
        end

        if control.right and not last_control.right then
            dash_r = dash_r + 1
            timer = 0
        end

        if control.down and not last_control.down then
            dash_d = dash_d + 1
            timer = 0
        end

        if control.left and dash_l >= 2 then
            com_send("pvp_revamped:dash", "dash_l")
            dash_l = 0
        end

        if control.up and dash_u >= 2 then
            com_send("pvp_revamped:dash", "dash_u")
            dash_u = 0
        end

        if control.right and dash_r >= 2 then
            com_send("pvp_revamped:dash", "dash_r")
            dash_r = 0
        end

        if control.down and dash_d >= 2 then
            com_send("pvp_revamped:dash", "dash_d")
            dash_d = 0
        end
    else
        if control.aux1 and not last_control.aux1 then
            dodge = dodge + 1
            timer = 0
        end

        if control.left and not last_control.left then
            barrel_roll_l = barrel_roll_l + 1
            timer = 0
        end

        if control.up and not last_control.up then
            barrel_roll_u = barrel_roll_u + 1
            timer = 0
        end

        if control.right and not last_control.right then
            barrel_roll_r = barrel_roll_r + 1
            timer = 0
        end

        if control.down and not last_control.down then
            barrel_roll_d = barrel_roll_d + 1
            timer = 0
        end

        if control.aux1 and dodge >= 2 then
            com_send("pvp_revamped:dodge", "dodge")
            dodge = 0
        end

        if control.left and barrel_roll_l >= 2 then
            com_send("pvp_revamped:barrel_roll", "barrel_roll_l")
            barrel_roll_l = 0
        end

        if control.up and barrel_roll_u >= 2 then
            com_send("pvp_revamped:barrel_roll", "barrel_roll_u")
            barrel_roll_u = 0
        end

        if control.right and barrel_roll_r >= 2 then
            com_send("pvp_revamped:barrel_roll", "barrel_roll_r")
            barrel_roll_r = 0
        end

        if control.down and barrel_roll_d >= 2 then
            com_send("pvp_revamped:barrel_roll", "barrel_roll_d")
            barrel_roll_d = 0
        end
    end

    if timer > timer_max then
        dodge = 0
        barrel_roll_l = 0
        barrel_roll_u = 0
        barrel_roll_r = 0
        barrel_roll_d = 0
        dash_l = 0
        dash_u = 0
        dash_r = 0
        dash_d = 0
        timer = 0
    end

    -- sneak + RMB = armor inv shield block.
    if (not last_control.sneak or not last_control.RMB) and control.sneak and control.RMB then
        com_send("pvp_revamped:shield_block", "block")
    end

    last_control = control
end)

sscsm.register_chatcommand("tap_speed", {
    params = "<seconds>",
    description = "Set the double tap sensitivity for dashing and dodging.",
    func = function(param)
        if param and tonumber(param) then
            timer_max = tonumber(param)

            return true, "Tap speed set to " .. timer_max .. " seconds."
        else
            return false, "Failed to change tap speed."
        end
    end
})

sscsm.register_chatcommand("tap_speed_reset", {
    params = "<none>",
    description = "Resets the tap sensitivity to 0.15 seconds.",
    func = function(param)
        timer_max = 0.15

        return true, "Tap speed reset."
    end
})
