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


yaba.new_layer{
	--name of the layer, used to get a copy of it later
	name = "test",
	--a number added to the world seed to amke different noises
	seed_offset = 5,
	--number of dimensions the noise changes over
	dimensions = 2,
	--scale to multiply the noise by(for performace)
	--if not a factor of 80, there may be some artifacting at the edge
	--of voxel manip blocks
	scale = 5,
	--side lengths for sectors (approx size for one biome)
	sector_lengths = {
	x=5,y=5,z=5,},
	--how biomes are chosen
	biome_types = "multimap",
	--biome distribution options (if any)
	random = nil,
	--perlin parameters for the heatmap and humidity map
	biome_maps = {
		dimensions = 2,
		heat = heatmap,
		humidity = wetmap,
		PerlinNoise(heatmap),
		PerlinNoise(wetmap),
	},
	--tollerance levels for each biome map within which biomes are
	--chosen at random
	tollerance = {
		heat = 10,
		humidity = 10,
		--multimap tollerances
		10,10,
	},
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "manhattan",
}

local test = yaba.get_layer("test")

test:add_biome{
	--name of biome
	name = "bland",
	--heat it is found at
	heat = 40,
	--humidity level it is found at
	humidity = 40,
	--any other noisemaps used in the layer
	--heat for multi
	40,
	--humidity for multi
	40,
}
test:add_biome{
	name = "boring",
	heat = 50,
	humidity = 40,
	50,40,
}
test:add_biome{
	name = "drab",
	heat = 50,
	humidity = 40,
	50,40,
}
test:add_biome{
	name = "dull",
	heat = 60,
	humidity = 60,
	60,60,
}
