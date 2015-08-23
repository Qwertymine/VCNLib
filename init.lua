local yaba = {}

yaba:generate_biomed_points = function(sector,seed,layer)
	local dims = layer.dimensions
	local hash = minetest.hash_node_position(sector)
	if layer.cache[hash] then
		return layer.cache[hash]
	end
	local points,prand = yaba:generate_points(sector,seed,layer)
	layer.cache[hash] = points

yaba:generate_points = function(sector,seed,layer)
	local hash = minetest.hash_node_position(sector)
	local prand = PcgRandom(hash + seed)
	local lim = 2
	local num = prand:next(1,20)
	local points = {}
	if num < 20 then
		num = 1
	else
		num = 2
	end
	while num > 0 do
		local x = prand:next(0,self[layer].sector_lengths.x-1)
		local y = prand:next(0,self[layer].sector_lengths.y-1)
		local z = prand:next(0,self[layer].sector_lengths.z-1)
		local pos = {x=x,y=y,z=z}
		pos = vector.add(pos,yaba:sector_to_pos_3d(sector,layer))
		table.insert(points,pos)
		num = num - 1
	end
	return points , prand
	end
end

yaba:sector_to_pos = function(sector,layer)
	local lengths = self[layer].sector_lengths
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
	return pos
end

yaba:pos_to_sector = function(pos,layer)
	local lengths = self[layer].sector_lengths
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
