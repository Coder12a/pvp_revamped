-- Entity to display when ever a player blocks with a shield.
minetest.register_entity("pvp_revamped:shield", {
    initial_properties = {
        physical = false,
        visual = "wielditem",
        ["selectionbox"] = {0, 0, 0, 0, 0, 0},
        static_save = false
    },

    on_activate = function(self, staticdata)
        self.object:set_armor_groups({immortal = 1})
    end
})
