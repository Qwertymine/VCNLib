yaba = {}
yaba.layers = {}

--Layer def
--	name
--		string
--	dimensions
--		2 or 3
--	sector_lengths
--		vector - norm 300^3 or 2000^3
--	scale
--		interger - the sector lengths are multiplied by this, but the
--			noise produced has a lower resolution
--	biome_types
--		string - random,heatmap,heatmap_tol
--	biome_type_options
--		table - tollerances for heatmap
--	geometery
--		string - euclidean,manhattan,chebyshev
--
--Layer in mem
--	cache
--		table of tables
--	add_biome
--		function to add biomes to the layer
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

local greatest = function(x,y,z)
	if x>y then
		if x>z then
			return x
		else
			return z
		end
	else
		if y>z then
			return y
		else
			return z
		end
	end
end

local find_closest = function(pos,geo,dims,points)
	local dist = nil
	local mini = math.huge
	local biome = nil
	if geo == "manhattan" then
		if dims == 3 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				dist = x+y+z
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
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo == "chebyshev" then
		if dims == 3 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				dist = greatest(x,y,z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local z=math.abs(pos.z-v.pos.z)
				dist = greatest(x,0,z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo == "euclidean" then
		if dims == 3 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				dist = math.sqrt(x*x+y*y+z*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local z=math.abs(pos.z-v.pos.z)
				dist = math.sqrt(x*x+z*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo =="ekdohibs" then
		if dims == 2 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local z=math.abs(pos.z-v.pos.z)
				dist = (x*x)+(z*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				dist =	(x*x)+(y*y)+(z*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo =="oddprod" then
		if dims == 2 then
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local z=math.abs(pos.z-v.pos.z)
				if x == 0 then
					x=1
				end
				if z == 0 then
					z=1
				end
				dist = math.abs(x*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in pairs(points) do
				local x=math.abs(pos.x-v.pos.x)
				local y=math.abs(pos.y-v.pos.y)
				local z=math.abs(pos.z-v.pos.z)
				if x == 0 then
					x=1
				end
				if y == 0 then
					y=1
				end
				if z == 0 then
					z=1
				end
				dist =	math.abs(x*y*z)
				if dist <= mini then
					mini = dist
					biome = v.biome
				end
			end
		end

	end
	return biome
end

yaba.get_biome_map_3d_flat = function(minp,maxp,layer,seed)
	local minp,rmin = minp,minp
	local maxp,rmax = maxp,maxp
	if layer.scale then
		minp = {x=math.floor(minp.x/scale),y=math.floor(minp.y/scale),z=math.floor(minp.z/scale)}
		maxp = {x=math.floor(maxp.x/scale),y=math.floor(maxp.y/scale),z=math.floor(maxp.z/scale)}
	end
	local mins = yaba.pos_to_sector(minp,layer)
	local maxs = yaba.pos_to_sector(maxp,layer)
	local dims = layer.dimensions
	local points = {}
	--get table of points
	if dims == 3 then
		for x=mins.x-1,maxs.x+1 do
			for y=mins.y-1,maxs.y+1 do
				for z=mins.z-1,maxs.z+1 do
					local temp = yaba.generate_biomed_points(vector.add(sector,{x=x,y=y,z=z}),seed,layer)
					for i,v in ipairs(temp) do
						table.insert(points,v)
					end
				end
			end
		end
	elseif dims == 2 then
		points = yaba.get_biome_map_2d_flat(minp,maxp,layer,seed)
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
	elseif dims == 2 then
		local nixz = 1
		local nixyz = 1
		local xsid = math.abs(maxp.x - minp.x) + 1
		for z=minp.z,maxp.z do
			for y=minp.y,maxp.y do
				for x=minp.x,maxp.x do
					ret[nixyz] = points[nixz]
					nixz = nixz + 1
					nixyz = nixyz + 1
				end
				nixz = nixz - xsid
			end
			nixz = nixz + xsid
		end
	end
	if layer.scale and dims == 3 then
		local nixyz = 1
		local scalxyz = 1
		local scalsidx = math.abs(maxp.x - minp.x) + 1
		local scalsidy = math.abs(maxp.y - minp.y) + 1
		local sx,sy,sz = 1,1,1
		local newret = {}
		for z=rmin.z,rmax.z do
			for y=rmin.y,rmax.y do
				for x=rmin.x,rmax.x do
					newret[nixyz] = ret[scalxyz]
					nixyz = nixyz + 1
					sx = sx + 1
					if sx == layer.scale then
						scalxyz = scalxyz + 1
						sx = 1
					end
				end
				sy = sy + 1
				if sy ~= layer.scale then
					scalxyz = scalxyz - scalsidx
				else
					sy = 1
				end
			end
			sz = sz + 1
			if sz ~= layer.scale then
				scalxyz = scalxyz - scalsidx*scalsidy
			else
				sz = 1
			end
		end
		ret = newret
	end
	return ret
end

yaba.get_biome_map_2d_flat = function(minp,maxp,layer,seed)
	local minp,rmin = minp,minp
	local maxp,rmax = maxp,maxp
	if layer.scale then
		minp = {x=math.floor(minp.x/scale),y=math.floor(minp.y/scale),z=math.floor(minp.z/scale)}
		maxp = {x=math.floor(maxp.x/scale),y=math.floor(maxp.y/scale),z=math.floor(maxp.z/scale)}
	end
	local mins = yaba.pos_to_sector(minp,layer)
	local maxs = yaba.pos_to_sector(maxp,layer)
	local dims = layer.dimensions
	local points = {}
	--get table of points
	if dims ~= 2 then
		return
	else
		for x=mins.x-1,maxs.x+1 do
			for z=mins.z-1,maxs.z+1 do
				local temp = yaba.generate_biomed_points({x=x,y=0,z=z},seed,layer)
				for i,v in ipairs(temp) do
					table.insert(points,v)
				end
			end
		end
	end
	local geo = layer.geometry
	local ret = {}
	if dims == 2 then
		local nixz = 1
		for z=minp.z,maxp.z do
			for x=minp.x,maxp.x do
				ret[nixz] = find_closest({x=x,y=0,z=z},geo,dims,points)
				nixz = nixz + 1
			end
		end
	end
	if layer.scale then
		local nixz = 1
		local scalxz = 1
		local scalsidx = math.abs(maxp.x - minp.x) + 1
		local sx,sz = 1,1
		local newret = {}
		for z=rmin.z,rmax.z do
			for x=rmin.x,rmax.x do
				newret[nixz] = ret[scalxz]
				nixz = nixz + 1
				sx = sx + 1
				if sx == layer.scale then
					scalxz = scalxz + 1
					sx = 1
				end
			end
			sz = sz + 1
			if sz ~= layer.scale then
				scalxz = scalxz - scalsidx
			else
				sz = 1
			end
		end
		ret = newret
	end
	return ret
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
	local prand = PcgRandom(hash + seed % 100000)
	local lim = 2
	local num = prand:next(1,20)
	local points = {}
	local dims = layer.dimensions
	local seen = {}
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
			local hashed = minetest.hash_node_position(pos)
			if not seen[hashed] then
				pos = vector.add(pos,yaba.sector_to_pos(sector,layer))
				table.insert(points,pos)
				seen[hashed] = pos
			end
			num = num - 1
		end
	else
		while num > 0 do
			local x = prand:next(0,layer.sector_lengths.x-1)
			local y = 0
			local z = prand:next(0,layer.sector_lengths.z-1)
			local pos = {x=x,y=y,z=z}
			local hashed = minetest.hash_node_position(pos)
			if not seen[hashed] then
				pos = vector.add(pos,yaba.sector_to_pos(sector,layer))
				table.insert(points,pos)
				seen[hashed] = pos
			end
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
	if yaba.layers[name] then
		return
	end
	yaba.layers[name] = def
	local layer = yaba.layers[name]
	layer.biomes = {}
	layer.biome_defs ={}
	layer.add_biome = function(self,biome_def)
		table.insert(self.biomes,biome_def.name)
		table.insert(self.biome_defs,biome_def)
	end
	layer.get_biome_def = function(self,to_get)
		return self.biome_defs[to_get]
	end
	if layer.biome_types == "heatmap"
	or layer.biome_types == "tollerance heatmap" then
		layer.heat = minetest.get_perlin(layer.biome_maps.heat)
		layer.humidity = minetest.get_perlin(layer.biome_maps.humidity)
	end
	layer.cache = setmetatable({},yaba.meta_cache)
	return layer
end

yaba.get_layer = function(to_get)
	return yaba.layers[name]
end

yaba.meta_cache = {
	__mode = "v",
}


dofile(minetest.get_modpath("yaba").."/infotools.lua")
dofile(minetest.get_modpath("yaba").."/test_layer.lua")
