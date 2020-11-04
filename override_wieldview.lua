if not minetest.global_exists("wieldview") then
    return
end

local player_data = pvp_revamped.player_data

function wieldview.update_wielded_item(self, player)
    if not player then
		return
    end
    
	local name = player:get_player_name()
	local stack = player:get_wielded_item()
    local item = stack:get_name()
    
	if not item then
		return
    end
    
    if self.wielded_item[name] then
        local pdata = player_data[name]

        if pdata and pdata.shield then
            armor.textures[name].wielditem = "3d_armor_trans.png"
            armor:update_player_visuals(player)
            return
        end

		if self.wielded_item[name] == item then
			return
        end

        armor.textures[name].wielditem = self:get_item_texture(item)
		armor:update_player_visuals(player)
    end
    
	self.wielded_item[name] = item
end
