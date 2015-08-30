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
	--how distance from the centre of a biome is judged
	--changes he shape of generated biomes
	geometry = "manhattan",
	--debug biomes, do not add biomes in this way - use layer:addbiome{def}
	biomes = {
		"bland",
		"boring",
		"drab",
		"dull",
	},
}
