yaba = {}

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
--
--
--Point in mem
--	pos
--		vector
--	biome
--		biome def table



--Returns the biome of the closest point from a table
--Must ensure that points cover the Moore environment of the sector
yaba.pos_to_sector = function(pos,layer)
	local lengths = layer.sector_lengths
	local dims = layer.dimensions
	local sector = {x=pos.x,y=pos.y,z=pos.z}
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

test_biomed_points = function(pos)
	local sec = yaba.pos_to_sector(pos, yaba.test)
	local p = yaba.generate_biomed_points(sec,1,yaba.test)
	for i,v in ipairs(p) do
		minetest.debug(v.biome)
	end
end

yaba.get_biome_map_3d_flat = function(self,minp,maxp,layer,seed)
	local mins = yaba.pos_to_sector(minp,layer)
	local maxs = yaba.pos_to_sector(maxp,layer)
	local dims = layer.dimensions
	local points = {}
	--get table of points
	if dims == 3 then
		for x=mins.x-1,maxs.x+1 do
			for y=mins.y-1,maxs.y+1 do
				for z=mins.z-1,maxs.z+1 do
					local temp = yaba.generate_biomed_points(vactor.add(sector,{x=x,y=y,z=z}),seed,layer)
					for i,v in ipairs(temp) do
						table.insert(points,v)
					end
				end
			end
		end
	else
		for x=mins.x-1,maxs.x+1 do
			for z=mins.z-1,maxs.z+1 do
				local temp = yaba.generate_biomed_points(vactor.add(sector,{x=x,y=y,z=z}),seed,layer)
				for i,v in ipairs(temp) do
					table.insert(points,v)
				end
			end
		end
	end
	local geo = layer.geometry
	local ret = {}
	if dims == 3 then
		local nixyz = 1
		for z=minp.z,maxp.z do
			for y=minp.y,maxp.y do
				for x=minp.x,maxp.x do
					ret[nixyz] = find_closest({x=x,y=y,z=z},geo,dims,points)
					nixyz = nixyz + 1
				end
			end
		end
	else
		local nixz = 1
		for z=minp.z,maxp.z do
			for y=minp.y,maxp.y do
				for x=minp.x,maxp.x do
					ret[nixz] = find_closest({x=x,y=0,z=z},geo,dims,points)
					nixz = nixz + 1
				end
			end
		end
	end
	return ret
end


local find_closest = function(pos,geo,dims,points)
	local dist = nil
	local mini = nil
	local biome = nil
	if geo == "taxicab" then
		if dims == 3 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				dist = x+y+z
				mini = mini or dist
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local z=math.abs(pos.z-v.pos.z)
				dist = x+z
				mini = mini or 100000
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	end
	return biome
end

yaba.get_node_biome = function(pos,seed,layer)
	local sector = yaba.pos_to_sector(pos,layer)
	local dims = layer.dimensions
	local points = {}
	if dims ==  3 then
		for x=-1,1 do
			for y=-1,1 do
				for z=-1,1 do
					local temp = yaba.generate_biomed_points(vector.add(sector,{x=x,y=y,z=z}),seed,layer)
					for i,v in ipairs(temp) do
						table.insert(points,v)
					end
				end
			end
		end
	else
		for x=-1,1 do
			for z=-1,1 do
				local temp = yaba.generate_biomed_points(vector.add(sector,{x=x,y=0,z=z}),seed,layer)
				for i,v in ipairs(temp) do
					table.insert(points,v)
				end
			end
		end
	end
	local geo = layer.geometry
	return find_closest(pos,geo,dims,points)
end


local get_biome_num = function(layer)
	return table.getn(layer.biomes)
end

yaba.generate_biomed_points = function(sector,seed,layer)
	local hash = minetest.hash_node_position(sector)
	if layer.cache[hash] then
		return layer.cache[hash]
	end
	local points,prand = yaba.generate_points(sector,seed,layer)
	local biome_meth = layer.biome_types
	local ret = {}
	if biome_meth == "random" then
		for i,v in ipairs(points) do
			local num = prand:next(1,get_biome_num(layer))
			table.insert(ret,{
				pos = v,
				biome = layer.biomes[num],
			})
		end
	else
	end
	layer.cache[hash] = ret 
	return ret
end

yaba.generate_points = function(sector,seed,layer)
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
			local x = prand:next(0,layer.sector_lengths.x-1)
			local y = prand:next(0,layer.sector_lengths.y-1)
			local z = prand:next(0,layer.sector_lengths.z-1)
			local pos = {x=x,y=y,z=z}
			pos = vector.add(pos,yaba.sector_to_pos(sector,layer))
			table.insert(points,pos)
			num = num - 1
		end
	else
		while num > 0 do
			local x = prand:next(0,layer.sector_lengths.x-1)
			local y = 0
			local z = prand:next(0,layer.sector_lengths.z-1)
			local pos = {x=x,y=y,z=z}
			pos = vector.add(pos,yaba.sector_to_pos(sector,layer))
			table.insert(points,pos)
			num = num - 1
		end
	end
	return points , prand
end

yaba.sector_to_pos = function(sector,layer)
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



yaba.new_layer = function(def)
	local name = def.name
	if yaba[name] then
		return
	end
	yaba[name] = def
	local layer = yaba[name]
	layer.cache = setmetatable({},yaba.meta_cache)
end

yaba.meta_cache = {
	__mode = "v",
}


dofile(minetest.get_modpath("yaba").."/infotools.lua")
dofile(minetest.get_modpath("yaba").."/test_layer.lua")
