local yaba = {}

--Layer def
--	name
--		string
--	dimensions
--		2 or 3
--	sector_lengths
--		vector - norm 300^3 or 2000^3
--	biome_types
--		string - random,heatmap,heatmap_tol
--	biome_type_options
--		table - tollerances for heatmap
--	geometery
--		string - cartesian,taxicab,chess
--
--Layer in mem
--	cache
--		table of tables
--	biome number
--		number of biomes
yaba:get_node_biome = function(pos,seed,layer)
	local sector = yaba:pos_to_sector(pos)
	local points = {}
	if dims ==  3 then
	for x=-1,1 do
		for y=-1,1 do
			for z=-1,1 do
				local temp = yaba:generate_biomed_points(vactor.add(sector,{x=x,y=y,z=z}),seed,layer)
				for i,v in ipairs(temp) do
					table.insert(points,v)
				end
			end
		end
	end
	else
	for x=-1,1 do
		for z=-1,1 do
			local temp = yaba:generate_biomed_points(vactor.add(sector,{x=x,y=0,z=z}),seed,layer)
			for i,v in ipairs(temp) do
				table.insert(points,v)
			end
		end
	end
	end
	local geo = layer.geometry
	return find_closest(pos,geo,points)
end
	


local get_biome_num = function(layer)
	return table.getn(layer.biomes)
end

yaba:generate_biomed_points = function(sector,seed,layer)
	local hash = minetest.hash_node_position(sector)
	if layer.cache[hash] then
		return layer.cache[hash]
	end
	local points,prand = yaba:generate_points(sector,seed,layer)
	local biome_meth = layer.biome_types
	local ret = {}
	if biome_meth = "random" then
		if not layer.biome_number then
			layer.biome_number = get_biome_num(layer)
		end
		for i,v in ipairs(points) do
			local num = prand:next(1,layer.biome_number)
			table.insert({
				pos = v
				biome = layer.biomes[num]
			},ret)
		end
	else
	end
	layer.cache[hash] = ret 
	return ret
end

yaba:generate_points = function(sector,seed,layer)
	local hash = minetest.hash_node_position(sector)
	local prand = PcgRandom(hash + seed)
	local lim = 2
	local num = prand:next(1,20)
	local points = {}
	local dims = layer.dimensions
	if num < 20 then
		num = 1
	else
		num = 2
	end
	if dims == 3 then
		while num > 0 do
			local x = prand:next(0,self[layer].sector_lengths.x-1)
			local y = prand:next(0,self[layer].sector_lengths.y-1)
			local z = prand:next(0,self[layer].sector_lengths.z-1)
			local pos = {x=x,y=y,z=z}
			pos = vector.add(pos,yaba:sector_to_pos_3d(sector,layer))
			table.insert(points,pos)
			num = num - 1
		end
	else
		while num > 0 do
			local x = prand:next(0,self[layer].sector_lengths.x-1)
			local y = 0
			local z = prand:next(0,self[layer].sector_lengths.z-1)
			local pos = {x=x,y=y,z=z}
			pos = vector.add(pos,yaba:sector_to_pos_3d(sector,layer))
			table.insert(points,pos)
			num = num - 1
		end
	end
	return points , prand
end

yaba:sector_to_pos = function(sector,layer)
	local lengths = layer.sector_lengths
	local pos = {}
	local dims = layer.dimensions
	if dims == 3 then
		pos.x = lengths.x * sector.x
		pos.y = lengths.y * sector.y
		pos.z = lengths.z * sector.z
	else
		pos.x = lengths.x * sector.x
		pos.y = 0
		pos.z = lengths.z * sector.z
	end
	return pos
end

yaba:pos_to_sector = function(pos,layer)
	local lengths = layer.sector_lengths
	local dims = layer.dimensions
	local sector = {pos.x,pos.y,pos.z}
	if dims == 3 then
		sector.x = math.floor(sector.x/lengths.x)
		sector.y = math.floor(sector.y/lengths.y)
		sector.z = math.floor(sector.z/lengths.z)
	else
		sector.x = math.floor(sector.x/lengths.x)
		sector.y = 0
		sector.z = math.floor(sector.z/lengths.z)
	end
	return sector
end

yaba:new_layer = function(def)
	local name = def.name
	if self[name] then
		return
	end
	self[name] = def
	local layer = self[name]
	layer.cache = setmetatable({},yaba.meta_cache)
end

yaba.meta_cache = {
	__mode = "v",
}
