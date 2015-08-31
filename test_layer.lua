yaba.new_layer{
	--name of the layer, used to get a copy of it later
	name = "test",
	--number of dimensions the noise changes over
	dimensions = 2,
	--scale to multiply the noise by(for performace)
	scale = nil,
	--side lengths for sectors (approx size for one biome)
	sector_lengths = {
	x=10,y=0,z=10,},
	--how biomes are chosen
	biome_types = "random",
	--biome distribution options (if any)
	random = nil,
	--perlin parameters for the heatmap and humidity map
	biome_maps = {
		heat = nil,
		humidity = nil,
	},
	--tollerance levels for each biome map within which biomes are
	--chosen at random
	tollerance = {
		heat = nil,
		humidity = nil,
	},
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "ekdohibs",
}

local test = yaba.get_layer("test")

test:add_biome{
	--name of biome
	name = "bland",
	--heat it is found at
	heat = 40,
	--humidity level it is found at
	humidity = 15,
	--any extra variables for defining the biome
	--e.g. grass,filler,decorations
}
test:add_biome{
	name = "boring",
	heat = 50,
	humidity = 40,
}
test:add_biome{
	name = "drab",
	heat = 50,
	humidity = 40,
}
test:add_biome{
	name = "dull",
	heat = 60,
	humidity = 60,
}
