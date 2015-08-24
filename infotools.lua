minetest.register_craftitem("yaba:biome_wand", {
	description = "Biome Wand",
	inventory_image = "farming_tool_diamondhoe.png",
	on_place = function(itemstack, placer, pointed_thing)
		--test_biomed_points(pointed_thing.above)
		--minetest.chat_send_all((yaba.test))
		--minetest.chat_send_all(yaba.pos_to_sector(pointed_thing.above,yaba.test).x)
		minetest.chat_send_all(yaba.get_node_biome(pointed_thing.above,1,yaba.test))
	end,
})

minetest.register_craft({
	output = "yaba:biome_wand",
	recipe = {
		{"default:diamond","default:diamond","default:diamond"},
		{"default:diamond","default:stick",  "default:diamond"},
		{"default:diamond","default:stick",  "default:diamond"},
	},
})
