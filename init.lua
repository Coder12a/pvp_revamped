pvp_revamped = {}

local modpath = minetest.get_modpath("pvp_revamped")
local format = string.format

dofile(format("%s/hudkit.lua", modpath))
dofile(format("%s/config.lua", modpath))
dofile(format("%s/constant.lua", modpath))
dofile(format("%s/globaldata.lua", modpath))
dofile(format("%s/helper.lua", modpath))
dofile(format("%s/projectile_entity.lua", modpath))
dofile(format("%s/shield_entity.lua", modpath))
dofile(format("%s/overrides.lua", modpath))
dofile(format("%s/override_wieldview.lua", modpath))
dofile(format("%s/globalstep.lua", modpath))
dofile(format("%s/sscsm.lua", modpath))
dofile(format("%s/player_events.lua", modpath))
dofile(format("%s/knockback.lua", modpath))
dofile(format("%s/punch.lua", modpath))
dofile(format("%s/chatcommands.lua", modpath))
dofile(format("%s/moveitems.lua", modpath))

modpath = nil
format = nil
