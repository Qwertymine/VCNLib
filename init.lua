vcnlib = {}
vcnlib.layers = {}

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

--[[
--TODO list
--Optimisation re-write of entire code base
--Docs
--loop flattening (optimisation)
--Add better ways for adding custom maps
--add more types of noise - cubic cell noise especially
--]]
local minetest = minetest
local abs = math.abs
local floor = math.floor
local hash_pos = minetest.hash_node_position

local get_biome_num = function(layer)
	return table.getn(layer.biomes)
end


local sector_to_pos = function(sector,layer)
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

vcnlib.sector_to_pos = sector_to_pos

local pos_to_sector = function(pos,layer)
	local lengths = layer.sector_lengths
	local dims = layer.dimensions
	local sector = {x=pos.x,y=pos.y,z=pos.z}
	if dims == 3 then
		sector.x = floor(sector.x/lengths.x)
		sector.y = floor(sector.y/lengths.y)
		sector.z = floor(sector.z/lengths.z)
	else
		sector.x = floor(sector.x/lengths.x)
		sector.y = 0
		sector.z = floor(sector.z/lengths.z)
	end
	return sector
end

vcnlib.pos_to_sector = pos_to_sector 

local find_closest = function(pos,geo,dims,points)
	local dist = nil
	local mini = math.huge
	local biome = nil
	if geo == "manhattan" then
		if dims == 3 then
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local y=abs(pos.y-v.pos.y)
				local z=abs(pos.z-v.pos.z)
				dist = x+y+z
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local z=abs(pos.z-v.pos.z)
				dist = x+z
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo == "chebyshev" then
		if dims == 3 then
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local y=abs(pos.y-v.pos.y)
				local z=abs(pos.z-v.pos.z)
				dist = greatest(x,y,z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local z=abs(pos.z-v.pos.z)
				dist = greatest(x,0,z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo =="euclidean" then
		if dims == 2 then
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local z=abs(pos.z-v.pos.z)
				dist = (x*x)+(z*z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local y=abs(pos.y-v.pos.y)
				local z=abs(pos.z-v.pos.z)
				dist =	(x*x)+(y*y)+(z*z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		end
	elseif geo =="oddprod" then
		if dims == 2 then
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local z=abs(pos.z-v.pos.z)
				if x == 0 then
					x=1
				end
				if z == 0 then
					z=1
				end
				dist = abs(x*z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		else
			for i,v in ipairs(points) do
				local x=abs(pos.x-v.pos.x)
				local y=abs(pos.y-v.pos.y)
				local z=abs(pos.z-v.pos.z)
				if x == 0 then
					x=1
				end
				if y == 0 then
					y=1
				end
				if z == 0 then
					z=1
				end
				dist =	abs(x*y*z)
				if dist < mini then
					mini = dist
					biome = v.biome
				end
			end
		end

	end
	return biome
end


local blockstart = function(block,blocksize,tablesize)
	return (1+block.x*blocksize.x)+(block.y*tablesize.x)+(block.z*tablesize.y*tablesize.x)
end

--block locations must start at (0,0,0)
--for 2d use (x,y) rather than (x,0,z)
local blockfiller = function(blockdata,blocksize,table,tablesize,blockstart)
	local tableit = blockstart 
	local ybuf,zbuf = tablesize.x - blocksize.x,(tablesize.y - blocksize.y)*tablesize.x
	local x,y,z = 1,1,1
	local blocklength = blocksize.x*blocksize.y*(blocksize.z or 1)
	for i=1,blocklength do
		if x > blocksize.x then
			x = 1
			y = y + 1
			tableit = tableit + ybuf
		end
		if y > blocksize.y then
			y = 1
			z = z + 1
			tableit = tableit + zbuf
		end
		--[[
		if z > blocksize.z then
			minetest.error("iterator has exceed block size")
		end
		--]]
		table[tableit] = blockdata[i]
		tableit = tableit + 1
		x = x + 1
	end
end

--for 2d use (x,y) rather than (x,0,z)
local solidblockfiller = function(blockvalue,blocksize,table,tablesize,blockstart)
	local tableit = blockstart 
	local blockflatsize = blocksize.x*blocksize.y*blocksize.z
	local ybuf,zbuf = tablesize.x - blocksize.x,(tablesize.y - blocksize.y)*tablesize.x
	local x,y,z = 1,1,1
	for i = 1,blockflatsize do
		if x > blocksize.x then
			x = 1
			y = y + 1
			tableit = tableit + ybuf
		end
		if y > blocksize.y then
			y = 1
			z = z + 1
			tableit = tableit + zbuf
		end
		--[[
		if z > blocksize.z then
			minetest.error("iterator has exceed block size")
		end
		--]]
		table[tableit] = blockvalue 
		tableit = tableit + 1
		x = x + 1
	end
end

local get_dist = function(a,b,geo,dims)
	if geo == "manhattan" then
		if dims == 3 then
			local x=abs(a.x-b.x)
			local y=abs(a.y-b.y)
			local z=abs(a.z-b.z)
			return x+y+z
		else
			local x=abs(a.x-b.x)
			local z=abs(a.z-b.z)
			return x+z
		end
	elseif geo == "chebyshev" then
		if dims == 3 then
			local x=abs(a.x-b.x)
			local y=abs(a.y-b.y)
			local z=abs(a.z-b.z)
			return greatest(x,y,z)
		else
			local x=abs(a.x-b.x)
			local z=abs(a.z-b.z)
			return greatest(x,0,z)
		end
	elseif geo =="euclidean" then
		if dims == 3 then
			local x=abs(a.x-b.x)
			local y=abs(a.y-b.y)
			local z=abs(a.z-b.z)
			return (x*x)+(y*y)+(z*z)
		else
			local x=abs(a.x-b.x)
			local z=abs(a.z-b.z)
			return (x*x)+(z*z)
		end
	elseif geo =="oddprod" then
		if dims == 2 then
			local x=abs(a.x-b.x)
			local z=abs(a.z-b.z)
			if x == 0 then
				x=1
			end
			if z == 0 then
				z=1
			end
			return abs(x*z)
		else
			local x=abs(a.x-b.x)
			local y=abs(a.y-b.y)
			local z=abs(a.z-b.z)
			if x == 0 then
				x=1
			end
			if y == 0 then
				y=1
			end
			if z == 0 then
				z=1
			end
			return abs(x*y*z)
		end

	end
end

local generate_points = function(sector,seed,layer)
	local hash = hash_pos(sector)
	local offset = layer.seed_offset
	local prand = PcgRandom(hash + (seed + offset) % 100000)
	local num = prand:next(1,20)
	local points = {}
	local dims = layer.dimensions
	local seen = {}
	if num < 20 then
		num = 1
	else
		num = 2
	end
	while num > 0 do
		local x = prand:next(0,layer.sector_lengths.x-1)
		local y
		if dims == 3 then
			y = prand:next(0,layer.sector_lengths.y-1)
		else
			y = 0
		end
		local z = prand:next(0,layer.sector_lengths.z-1)
		local pos = {x=x,y=y,z=z}
		local hashed = hash_pos(pos)
		if not seen[hashed] then
			pos = vector.add(pos,sector_to_pos(sector,layer))
			table.insert(points,pos)
			seen[hashed] = pos
		end
		num = num - 1
	end
	return points , prand
end

local generate_biomed_points = function(sector,seed,layer)
	local hash = hash_pos(sector)
	if layer.cache[hash] then
		return layer.cache[hash]
	end
	local points,prand = generate_points(sector,seed,layer)
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
	elseif biome_meth == "heatmap" then
		local mapdims = layer.biome_maps.dimensions
		for i,v in ipairs(points) do
			local heat,humidity 
			if mapdims == 3 then
				heat = layer.heat:get3d(v)
				humidity = layer.humidity:get3d(v)
			else
				heat = layer.heat:get2d({x=v.x,y=v.z})
				humidity = layer.humidity:get2d({x=v.x,y=v.z})
			end
			local dist = math.huge
			local biome = nil
			for j,k in ipairs(layer.biome_defs) do
				local hot = heat - k.heat
				local wet = humidity - k.humidity
				local d = abs(hot) + abs(wet)
				if d < dist then
					biome = k.name
					dist = d
				end
			end
			table.insert(ret,{
				pos = v,
				biome = biome,
			})
		end
	elseif biome_meth == "tolmap" then
		local mapdims = layer.mapdims
		local heattol = layer.tollerance.heat
		local wettol = layer.tollerance.humidity
		for i,v in ipairs(points) do
			local heat,humidity 
			if mapdims == 3 then
				heat = layer.heat:get3d(v)
				humidity = layer.humidity:get3d(v)
			else
				heat = layer.heat:get2d({x=v.x,y=v.z})
				humidity = layer.humidity:get2d({x=v.x,y=v.z})
			end
			local biomes = {}
			local biome = nil
			for j,k in ipairs(layer.biome_defs) do
				local hot = abs(heat - k.heat)
				local wet = abs(humidity - k.humidity)
				if hot < heattol and wet < wettol then
					table.insert(biomes,k)
				end
			end
			local bionum = table.getn(biomes)
			if bionum == 0 then
				local dist = math.huge
				local nbiome = nil
				for j,k in ipairs(layer.biome_defs) do
					local hot = heat - k.heat
					local wet = humidity - k.humidity
					local d = abs(hot) + abs(wet)
					if d < dist then
						nbiome = k.name
						dist = d
					end
				end
				table.insert(ret,{
					pos = v,
					biome = nbiome,
				})
			else
				biome = biomes[prand:next(1,bionum)].name
				table.insert(ret,{
					pos = v,
					biome = biome,
				})
			end
		end
	elseif biome_meth == "multimap" then
		local mapdims = layer.mapdims
		local tol = layer.tollerance
		for i,v in ipairs(points) do
			local maps = {}
			if mapdims == 3 then
				for j,k in ipairs(layer.biome_maps) do
					maps[j] = k:get3d(v)
				end
			else
				local pos = {x=v.x,y=v.z}
				for j,k in ipairs(layer.biome_maps) do
					maps[j] = k:get2d(pos)
				end
			end
			local dist = math.huge
			local nbiome = nil
			for j,k in ipairs(layer.biome_defs) do
				local d = 0
				for l,m in ipairs(maps) do
					d = d + abs(k[l] - m)
				end
				if d < dist then
					nbiome = k.name
					dist = d
				end
			end
			table.insert(ret,{
				pos = v,
				biome = nbiome,
			})
		end
	elseif biome_meth == "multitolmap" then
		local mapdims = layer.mapdims
		local tol = layer.tollerance
		for i,v in ipairs(points) do
			local maps = {}
			if mapdims == 3 then
				for j,k in ipairs(layer.biome_maps) do
					maps[j] = k:get3d(v,layer)
				end
			else
				local pos = {x=v.x,y=v.z}
				for j,k in ipairs(layer.biome_maps) do
					maps[j] = k:get2d(pos,layer)
				end
			end
			local biomes = {}
			local biome = nil
			for j,k in ipairs(layer.biome_defs) do
				local add = true
				for l,m in ipairs(maps) do
					local comp = abs(k[l] - m)
					if comp > tol[l] then
						add = false
						break
					end

				end
				if add then
					table.insert(biomes,k)
				end
			end
			local bionum = table.getn(biomes)
			if bionum == 0 then
				local dist = math.huge
				local nbiome = nil
				for j,k in ipairs(layer.biome_defs) do
					local d = 0
					for l,m in ipairs(maps) do
						d = d + abs(k[l] - m)
					end
					if d < dist then
						nbiome = k.name
						dist = d
					end
				end
				table.insert(ret,{
					pos = v,
					biome = nbiome,
				})
			else
				biome = biomes[prand:next(1,bionum)].name
				table.insert(ret,{
					pos = v,
					biome = biome,
				})
			end
		end
	end
	layer.cache[hash] = ret 
	return ret
end


local generate_block = function(blocksize,blockcentre,blockmin,layer,seed)
	local points = {true,true,true,true}
	local block = {true,true,true,true}
	local index = 1
	local dims = layer.dimensions
	local geo = layer.geometry
	local blockmax = {x=blockmin.x+(blocksize.x-1),y=blockmin.y+(blocksize.y -1)
		,z=blockmin.z+(blocksize.z-1)}
	local sector = pos_to_sector(blockcentre,layer)
	if dims == 3 then
		local x,y,z = -1,-1,-1
		for i=1,27 do
			x = x + 1
			if x > 1 then
				x = -1
				y = y + 1
			end
			if y > 1 then
				y = -1
				z = z + 1
			end
			local temp = generate_biomed_points(vector.add(sector,{x=x,y=y,z=z})
				,seed,layer)
			for i,v in ipairs(temp) do
				points[index] = v
				v.dist = get_dist(blockcentre,v.pos,layer.geometry,dims)
				index = index + 1
			end
		end
	else
		local x,z = -1,-1
		for i=1,9 do
			x = x + 1
			if x > 1 then
				x = -1
				z = z + 1
			end
			local temp = generate_biomed_points(vector.add(sector,{x=x,y=0,z=z})
				,seed,layer)
			for i,v in ipairs(temp) do
				points[index] = v
				v.dist = get_dist(blockcentre,v.pos,layer.geometry,dims)
				index = index + 1
			end
		end
	end
	table.sort(points,function(a,b) return a.dist < b.dist end) 
	local to_nil = false
	local max_dist = points[1].dist + get_dist(blockmin,blockcentre,geo,dims)
	for i=1,#points do
		if to_nil then
			points[i] = nil
		elseif points[i].dist > max_dist then
			to_nil = true
		end
	end
	if dims == 3 then
		local tablesize = blocksize.x*blocksize.y*blocksize.z
		local x,y,z = blockmin.x,blockmin.y,blockmin.z
		for i = 1,tablesize do
			if x > blockmax.x then
				x = blockmin.x
				y = y + 1
			end
			if y > blockmax.y then
				y = blockmin.y
				z = z + 1
			end
			--[[
			if z > blockmax.z then
				minetest.error("block count exceeding blocksize")
			end
			--]]
			block[i] = find_closest({x=x,y=y,z=z},geo
				,dims,points)
			--[[
			--DEBUG test
			local truth = vcnlib.get_node_biome({x=x,y=y,z=z},seed,layer)
			if block[i] ~= truth and y == 50 then
				minetest.debug("START" .. truth .. x .. "," .. y .."," .. z)
				for i,v in ipairs(points) do
					minetest.debug(v.pos.x .. "," .. v.pos.y .. "," .. v.pos.z)
					minetest.debug(get_dist({x=x,y=y,z=z},v.pos,geo,dims))
					minetest.debug(v.dist)
					minetest.debug(v.biome)
				end
				minetest.debug("END" .. truth)
			end
			--]]
			x = x + 1
		end
	else
		local tablesize = blocksize.x*blocksize.z
		local x,y = blockmin.x,blockmin.z
		for i = 1,tablesize do
			if x> blockmax.x then
				x = blockmin.x
				y = y + 1
			end
			block[i] = find_closest({x=x,y=y,z=z},geo
				,dims,points)
			x = x + 1
		end
	end
	return block
end

local get_biome_map_3d_experimental = function(minp,maxp,layer,seed)
	local blsize = layer.blocksize or {x=5,y=5,z=5}
	local halfsize = {x=blsize.x/2,y=blsize.y/2,z=blsize.z/2}
	local centre = {x=minp.x+halfsize.x,y=minp.y+halfsize.y,z=minp.z+halfsize.z}
	local blocksize = {x=blsize.x,y=blsize.y,z=blsize.z}
	local blockmin = {x=minp.x,y=minp.y,z=minp.z}
	local mapsize = {x=maxp.x-minp.x+1,y=maxp.y-minp.y+1,z=maxp.z-minp.z+1}
	local map = {}

	for z=minp.z,maxp.z,blsize.z do
		centre.z = z + halfsize.z
		blockmin.z = z
		if z + (blsize.z - 1) > maxp.z then
			blocksize.z = blsize.z - ((z + (blsize.z - 1)) - maxp.z)
			centre.z = z + blocksize.z/2
		end
		for y=minp.y,maxp.y,blsize.y do
			centre.y = y + halfsize.y
			blockmin.y = y
			if y + (blsize.y - 1) > maxp.y then
				blocksize.y = blsize.y - ((y + (blsize.y - 1)) - maxp.y)
				centre.y = y + blocksize.y/2
			end
			for x=minp.x,maxp.x,blsize.x do
				centre.x = x + halfsize.x
				blockmin.x = x
				if x + (blsize.x - 1) > maxp.x then
					blocksize.x = blsize.x - ((y + (blsize.x -1)) - maxp.x)
					centre.x = x + blocksize.x/2
				end
				local temp = generate_block(blocksize,centre,blockmin
					,layer,seed)
				local blockstart = blockmin.x - minp.x + 1
					+ (blockmin.y - minp.y)*mapsize.x 
					+ (blockmin.z - minp.z)*mapsize.x*mapsize.y 
				blockfiller(temp,blocksize,map,mapsize,blockstart)
			end
		end
	end

	return map
end

vcnlib.experimental = get_biome_map_3d_experimental

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


local get_node_biome = function(pos,seed,layer)
	local sector = pos_to_sector(pos,layer)
	local dims = layer.dimensions
	local points = {}
	local x,y,z = -1,-1,-1
	local index = 1
	if dims == 3 then
		for i=1,27 do
			if x > 1 then
				x = -1
				y = y + 1
			end
			if y > 1 then
				y = -1
				z = z + 1
			end
			local temp = generate_biomed_points(vector.add(sector,{x=x,y=y,z=z})
				,seed,layer)
			for i,v in ipairs(temp) do
				points[index] = v
				index = index + 1
			end
			x = x + 1
		end
	else
		for i=1,9 do
			if x > 1 then
				x = -1
				z = z + 1
			end
			local temp = generate_biomed_points(vector.add(sector,{x=x,y=0,z=z})
				,seed,layer)
			for i,v in ipairs(temp) do
				points[index] = v
				index = index + 1
			end
			x = x + 1
		end
	end
	--[[
	if dims ==  3 then
		for x=-1,1 do
			for y=-1,1 do
				for z=-1,1 do
					local temp = generate_biomed_points(vector.add(sector,{x=x,y=y,z=z}),seed,layer)
					for i,v in ipairs(temp) do
						table.insert(points,v)
					end
				end
			end
		end
	else
		for x=-1,1 do
			for z=-1,1 do
				local temp = generate_biomed_points(vector.add(sector,{x=x,y=0,z=z}),seed,layer)
				for i,v in ipairs(temp) do
					table.insert(points,v)
				end
			end
		end
	end
	--]]
	return find_closest(pos,layer.geometry,dims,points)
end

vcnlib.get_node_biome = get_node_biome


local get_biome_map_3d_flat = function(minp,maxp,layer,seed)
	local scale = layer.scale
	local minp,rmin = minp,minp
	local maxp,rmax = maxp,maxp
	if layer.scale then
		minp = {x=floor(minp.x/scale),y=floor(minp.y/scale)
			,z=floor(minp.z/scale)}
		maxp = {x=floor(maxp.x/scale),y=floor(maxp.y/scale)
			,z=floor(maxp.z/scale)}
	end
	local ret = {}

	local nixyz = 1
	--[
	local table_size = ((maxp.z - minp.z) + 1)*((maxp.y - minp.y) + 1)
		*((maxp.x - minp.x) + 1)
	local x,y,z = minp.x,minp.y,minp.z
	for nixyz=1,table_size do
		if x > maxp.x then
			x = minp.x
			y = y + 1
		end
		if y > maxp.y then
			y = minp.y
			z = z + 1
		end
		ret[nixyz] = get_node_biome({x=x,y=y,z=z},seed,layer)
		x = x + 1
	end
	--]]
	--[[
	for z=minp.z,maxp.z do
		for y=minp.y,maxp.y do
			for x=minp.x,maxp.x do
				ret[nixyz] = get_node_biome({x=x,y=y,z=z},seed,layer)
				nixyz = nixyz + 1
			end
		end
	end
	--]]
	if scale then
		local nixyz = 1
		local scalxyz = 1
		local scalsidx = abs(maxp.x - minp.x) + 1
		local scalsidy = abs(maxp.y - minp.y) + 1
		local sx,sy,sz,ix,iy = 0,0,0,1,1
		local table_size = ((rmax.z - rmin.z) + 1)*((rmax.y - rmin.y) + 1)
			*((rmax.x - rmin.x) + 1)
		local x,y,z = rmin.x,rmin.y,rmin.z
		local newret = {}
		--[[
		for nixyz=1,table_size do
			if x > rmax.x then
				x = rmin.x
				y = y + 1
				--x loop exit logic
				sy = sy + 1
				if sy ~= scale then
					scalxyz = ix
				else
					scalxyz = ix + scalsidx
					ix = scalxyz
					sy = 0
				end
			end
			if y > rmax.y then
				y = rmin.y
				z = z + 1
				--y exit loop logic
				sz = sz + 1
				if sz ~= scale then
					scalxyz = iy
					ix = iy
				else
					sz = 0
					scalxyz = iy + scalsidy*scalsidx
					iy = scalxyz
					ix = iy
				end
			end
			--x loop main logic
			newret[nixyz] = ret[scalxyz]
			--minetest.debug(scalxyz)
			nixyz = nixyz + 1
			sx = sx + 1
			if sx == scale then
				scalxyz = scalxyz + 1
				sx = 0
			end
			x = x + 1
		end
		--]]
		--[
		for z=rmin.z,rmax.z do
		sy = 0
			for y=rmin.y,rmax.y do
			sx = 0
				for x=rmin.x,rmax.x do
					newret[nixyz] = ret[scalxyz]
					--minetest.debug(scalxyz)
					nixyz = nixyz + 1
					sx = sx + 1
					if sx == scale then
						scalxyz = scalxyz + 1
						sx = 0
					end
				end
				sy = sy + 1
				if sy ~= scale then
					scalxyz = ix
				else
					scalxyz = ix + scalsidx
					ix = scalxyz
					sy = 0
				end
			end
			sz = sz + 1
			if sz ~= scale then
				scalxyz = iy
				ix = iy
			else
				sz = 0
				scalxyz = iy + scalsidy*scalsidx
				iy = scalxyz
				ix = iy
			end
		end
		--]]
		ret = newret
	end
	return ret
end

local get_biome_map_2d_flat = function(minp,maxp,layer,seed)
	local minp,rmin = minp,minp
	local maxp,rmax = maxp,maxp
	local scale = layer.scale
	if layer.scale then
		minp = {x=floor(minp.x/scale),y=0,z=floor(minp.z/scale)}
		maxp = {x=floor(maxp.x/scale),y=0,z=floor(maxp.z/scale)}
	end
	local ret = {}

	local nixz = 1
	for z=minp.z,maxp.z do
		for x=minp.x,maxp.x do
			ret[nixz] = get_node_biome({x=x,y=y,z=z},seed,layer)
			nixz = nixz + 1
		end
	end
	
	if layer.scale then
		local nixz = 1
		local scalxz = 1
		local scalsidx = abs(maxp.x - minp.x) + 1
		local sx,sz,ix = 0,0,1
		local newret = {}
		for z=rmin.z,rmax.z do
			sx = 0
			for x=rmin.x,rmax.x do
				newret[nixz] = ret[scalxz]
				nixz = nixz + 1
				sx = sx + 1
				if sx == scale then
					scalxz = scalxz + 1
					sx = 0
				end
			end
			sz = sz + 1
			if sz ~= scale then
				scalxz = ix
			else
				scalxz = ix + scalsidx
				ix = scalxz
				sz = 0
			end
		end
		ret = newret
	end
	return ret
end

vcnlib.get_biome_map_flat = function(minp,maxp,layer,seed)
	local dims = layer.dimensions
	if dims == 3 then
		return get_biome_map_3d_flat(minp,maxp,layer,seed)
	else
		return get_biome_map_2d_flat(minp,maxp,layer,seed)
	end
end

vcnlib.new_layer = function(def)
	local name = def.name
	if vcnlib.layers[name] then
		return
	end
	vcnlib.layers[name] = def
	local layer = vcnlib.layers[name]
	if not layer.seed_offset then
		layer.seed_offset = 0
	end
	layer.biomes = {}
	layer.biome_defs ={}
	layer.add_biome = function(self,biome_def)
		table.insert(self.biomes,biome_def.name)
		table.insert(self.biome_defs,biome_def)
	end
	layer.get_biome_list = function(self,to_get)
		return self.biomes
	end
	if layer.biome_types == "heatmap"
	or layer.biome_types == "tolmap" then
		layer.heat = PerlinNoise(layer.biome_maps.heat)
		layer.humidity = PerlinNoise(layer.biome_maps.humidity)
	end
	layer.cache = setmetatable({},vcnlib.meta_cache)
	return layer
end

--for mods which are using a pre-defined biome layer
vcnlib.get_layer = function(to_get)
	return vcnlib.layers[to_get]
end

vcnlib.meta_cache = {
	__mode = "v",
}

--This code is used to test for custom maps - any table without get3d is 
--assumed a def table for minetest.get_perlin
minetest.register_on_mapgen_init(function(map)
	for k,v in pairs(vcnlib.layers) do
		for j,l in ipairs(v.biome_maps) do
			if not l.get3d then
				v.biome_maps[j] = minetest.get_perlin(l)
			end
		end
	end
end)

--dofile(minetest.get_modpath("vcnlib").."/testtools.lua")
--dofile(minetest.get_modpath("vcnlib").."/test_layer.lua")
dofile(minetest.get_modpath("vcnlib").."/maps.lua")
--dofile(minetest.get_modpath("vcnlib").."/test_layer.lua")
