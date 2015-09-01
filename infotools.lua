local seed = minetest.get_mapgen_params().seed
minetest.register_craftitem("yaba:biome_wand", {
	description = "Biome Wand",
	inventory_image = "farming_tool_diamondhoe.png",
	on_place = function(itemstack, placer, pointed_thing)
		--test_biomed_points(pointed_thing.above)
		--minetest.chat_send_all((yaba.test))
		--minetest.chat_send_all(yaba.pos_to_sector(pointed_thing.above,yaba.test).x)
		local pos = pointed_thing.above
		local scale = yaba.layers.test.scale
		if scale then
			minetest.chat_send_all(yaba.get_node_biome(({x=math.floor(pos.x/scale),y=math.floor(pos.y/scale),z=math.floor(pos.z/scale)}),seed,yaba.layers.test))
		else
			minetest.chat_send_all(yaba.get_node_biome(pos,seed,yaba.layers.test))
		end
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
