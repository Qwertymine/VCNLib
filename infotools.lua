minetest.register_craftitem("yaba:biome_wand", {
	description = "Biome Wand",
	inventory_image = "farming_tool_diamondhoe.png",
	on_place = function(itemstack, placer, pointed_thing)
		minetest.chat_send_all(yaba.get_node_biome(pointed_thing.above,minetest.get_node(pointed_thing.above)))
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
