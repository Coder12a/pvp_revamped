local player_data = pvp_revamped.player_data
local calculate_knockback = minetest.calculate_knockback

--Disable knockback on stagger.
function minetest.calculate_knockback(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage)
    local pdata = player_data[player:get_player_name()]

    if pdata and pdata.stagger then
        return 0.0
    end
    
    return calculate_knockback(player, hitter, time_from_last_punch, tool_capabilities, dir, distance, damage)
end
