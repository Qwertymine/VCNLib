local heatmap = {
	flags = nil,
	lacunarity = 2,
	octaves = 3,
	--average temp
	offset = 50,
	persistence = 0.5,
	--plus or mius value
	scale = 10,
	seeddiff = 5349,
	spread = {x=10,y=10,z=10},
}

local wetmap = {
	flags = nil,
	lacunarity = 2,
	octaves = 3,
	offset = 50,
	persistence = 0.5,
	scale = 10,
	seeddiff = 842,
	spread = {x=10,y=10,z=10},
}


vcnlib.new_layer{
	--name of the layer, used to get a copy of it later
	name = "test",
	--a number added to the world seed to amke different noises
	seed_offset = 5,
	--number of dimensions the noise changes over
	dimensions = 3,
	--scale to multiply the noise by(for performace)
	--if not a factor of 80, there may be some artifacting at the edge
	--of voxel manip blocks
	scale = 5,
	--This activates a more efficient algorithm which generates the map in
	--blocks
	--This sets the size of the blocks that it generates, performance
	--improves with size only for smaller sizes: 1^3 < small > 80^3
	blocksize = {x=5,y=5,z=5},
	--This is the distribution of how many points are generated in each
	--sector
	--The index is the number of points - these MUST be continuous
	--The number value is the minimum random number required for that value
	--to be chosen
	point_distribution = {
		random_max = 20,
		random_min = 1,
		[1] = 1,
		--This is an example of how to 'skip' a value - 2 is skipped 
		[2] = 20,
		[3] = 20,
	},
	--side lengths for sectors (approx size for one biome)
	sector_lengths = {
	x=5,y=5,z=5,},
	--how biomes are chosen
	biome_types = {
		first = "random",
		second = "fail",
		fail = "fail"
	},
	--biome distribution options (if any)
	random = nil,
	--perlin parameters for the heatmap and humidity map
	biome_maps = {
		dimensions = 2,
		--multimap maps
		[1] = heatmap,
		[2] = wetmap,
	},
	--tollerance levels for each biome map within which biomes are
	--chosen at random
	tollerance = {
		--multimap tollerances
		[1] = 10,
		[2] = 10,
	},
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "manhattan",
}

local test = vcnlib.get_layer("test")

test:add_biome{
	--name of biome
	name = "bland",
	--heat it is found at
	heat = 40,
	--humidity level it is found at
	humidity = 40,
	--any other noisemaps used in the layer
	--heat for multi
	[1] = 40,
	--humidity for multi
	[2] = 40,
}
test:add_biome{
	name = "boring",
	heat = 50,
	humidity = 40,
	[1] = 50,
	[2] = 40,
}
test:add_biome{
	name = "drab",
	heat = 50,
	humidity = 40,
	[1] = 50,
	[2] = 40,
}
test:add_biome{
	name = "dull",
	heat = 60,
	humidity = 60,
	[1] = 60,
	[2] = 60,
}
