local get_player_control = sscsm.get_player_control
local com_send = sscsm.com_send
local max = math.max
local last_control = {}
local timer = 0
local timer_max = 0.15
local dodge_l = 0
local dodge_u = 0
local dodge_r = 0
local dodge_d = 0
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
        if control.left and not last_control.left then
            dodge_l = dodge_l + 1
            timer = 0
        end

        if control.up and not last_control.up then
            dodge_u = dodge_u + 1
            timer = 0
        end

        if control.right and not last_control.right then
            dodge_r = dodge_r + 1
            timer = 0
        end

        if control.down and not last_control.down then
            dodge_d = dodge_d + 1
            timer = 0
        end

        if control.left and dodge_l >= 2 then
            com_send("pvp_revamped:dodge", "dodge_l")
            dodge_l = 0
        end

        if control.up and dodge_u >= 2 then
            com_send("pvp_revamped:dodge", "dodge_u")
            dodge_u = 0
        end

        if control.right and dodge_r >= 2 then
            com_send("pvp_revamped:dodge", "dodge_r")
            dodge_r = 0
        end

        if control.down and dodge_d >= 2 then
            com_send("pvp_revamped:dodge", "dodge_d")
            dodge_d = 0
        end
    end

    if timer > timer_max then
        dodge_l = 0
        dodge_u = 0
        dodge_r = 0
        dodge_d = 0
        dash_l = 0
        dash_u = 0
        dash_r = 0
        dash_d = 0
        timer = 0
    end

    last_control = control
end)

sscsm.register_chatcommand("tap_speed", {
    params = "<seconds>",
    description = "Set how fast you want the double tap speed for dashing and dodging.",
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
    description = "Resets the tap speed to 0.15 seconds.",
    func = function(param)
        timer_max = 0.15

        return true, "Tap speed reset."
    end
})
