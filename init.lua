pvp_revamped = {}

local modpath = minetest.get_modpath("pvp_revamped")

dofile(string.format("%s/config.lua", modpath))
dofile(string.format("%s/constant.lua", modpath))
dofile(string.format("%s/globaldata.lua", modpath))
dofile(string.format("%s/helper.lua", modpath))
dofile(string.format("%s/projectile_entity.lua", modpath))
dofile(string.format("%s/shield_entity.lua", modpath))
dofile(string.format("%s/overrides.lua", modpath))
dofile(string.format("%s/globalstep.lua", modpath))
dofile(string.format("%s/sscsm.lua", modpath))
dofile(string.format("%s/player_events.lua", modpath))
dofile(string.format("%s/knockback.lua", modpath))
dofile(string.format("%s/punch.lua", modpath))
dofile(string.format("%s/chatcommands.lua", modpath))
