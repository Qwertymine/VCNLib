--This file contains a list of simple custom maps
--These are to replace the old custom map model, and for optimisation
vcnlib.maps = {}
local maps = vcnlib.maps

local get_height = function(pos)
	return pos.y
end

local scale = function(value,scale)
	return value/scale
end

local centre_height = function(value,centre)
	return value-centre
end

local zero = function()
	return 0
end

maps.height_map = {
	get3d = function(self,pos)
		return get_height(pos)
	end,
	get2d = zero,
	construct = function()
		return
	end,
}
maps.scaled_height_map = {
	get3d = function(self,pos)
		return scale(pos.y,self.scale)
	end,
	get2d = zero,
	construct = function(self,def)
		self.scale = def.scale
		return
	end
}
maps.centred_height_map = {
	get3d = function(self,pos)
		return centre_height(pos.y,self.centre)
	end,
	get2d = zero,
	construct = function(self,def)
		self.centre = def.centre
		return
	end,
}
maps.scaled_centred_height_map = {
	get3d = function(self,pos)
		return scale(centre_height(pos.y,self.centre),self.scale)
	end,
	get2d = zero,
	contruct = function(self,def)
		self.centre = def.centre
		self.scale = def.scale
		return
	end,
}

local get_map_object = function(map_def)
	local object = {}
	--Get the map type, and fail if none exists
	local noise_map = maps[map_def.map_type]
	--Choose function to load based on dimensions given
	if map_def.dimensions == 3 then
		object.get_noise = noise_map.get3d
	else
		object.get_noise = noise_map.get2d
	end
	--Use the map constructor to initialise
	noise_map.construct(object,map_def)
	return object
end

vcnlib.get_map_object = get_map_object
