vcnlib.geometry = {}

--Short-hand used throughout this file
local geo = vcnlib.geometry

--Commanly used functions are assigned local values - to reduce access times
local abs = math.abs
local floor = math.floor
local hash_pos = minetest.hash_node_position

--[[
	Manhattan distance to a point is the sum of the horizontal
	and vertical distance to the point (2d)

	4|3|2|3|4
	3|2|1|2|3	This distance metric produces diamond shapes
	2|1|0|1|2	when used on a single point
	3|2|1|2|3
	4|3|2|3|4
	
	This is the distance metric that light sources use to spread in
	minetest and minecraft
--]]
geo.manhattan = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return x+z
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return x+y+z
	end,
}

--Helper function for chebyshev geometery
local function greatest(x,y,z)
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

--[[
	The Chebyshev distance to a point is the longest distance out
	of the horizontal and vertical distance (2d)

	2|2|2|2|2
	2|1|1|1|2	This distance metric produces squares when used
	2|1|0|1|2	on a single point
	2|1|1|1|2
	2|2|2|2|2
--]]
geo.chebyshev = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return greatest(x,0,z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return greatest(x,y,z)
	end,
}

--[[
	The euclidean distance metric is the "real" distance to a point
	This is the method of measuring distance taught in schools

	This distance metric produces circles when used on a single point

	The fast functions are used where only a comparison of distances
	is needed - this allows for the expensive square root function to
	be skipped
--]]
geo.euclidean = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return math.sqrt((x*x)+(z*z))
	end,
	_2d_fast = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		return (x*x)+(z*z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return math.sqrt((x*x)+(y*y)+(z*z))
	end,
	_3d_fast = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		return (x*x)+(y*y)+(z*z)
	end,
}

--[[
	The oddprod distance metric is not a recognised distance metric which
	was created for the interesting noise patterns it creates

	It is defined entirely by the code below - but in short:

		The distance to a point is the product of the horizontal 
		and vertical distance to the point.(2d)
		
		Any axies which are less than 1 are set to one - this is to 
		avoid infinitely long formations if a point is aligned to a
		node (i.e the distance is zero regardless of the real distance)

	9|6|3|3|3|6|9
	6|4|2|2|2|4|6
	3|2|1|1|1|2|3	This distance metric produces a cross when used on
	3|2|1|1|1|2|3	a single point
	3|2|1|1|1|2|3
	6|4|2|2|2|4|6
	9|6|3|3|3|6|9
--]]
geo.oddprod = {
	_2d = function(a,b)
		local x=abs(a.x-b.x)
		local z=abs(a.z-b.z)
		if x <= 1 then
			x=1
		end
		if z <= 1 then
			z=1
		end
		return abs(x*z)
	end,
	_3d = function(a,b)
		local x=abs(a.x-b.x)
		local y=abs(a.y-b.y)
		local z=abs(a.z-b.z)
		if x <= 1 then
			x=1
		end
		if y <= 1 then
			y=1
		end
		if z <= 1 then
			z=1
		end
		return abs(x*y*z)
	end,
}

--[[
	Helper function which returns the correct, full function for
	calculating distance in that metric

	This does not return the fast distance metric for comparison
	is one exists (euclidean)
--]]
local get_distance_function = function (geometry, dimensions)
	if geo[geometry] then
		if dimensions == 3 then
			return geo[geometry]._3d
		else
			return geo[geometry]._2d
		end
	else
		return nil
	end
end

vcnlib.get_distance_function = get_distance_function

--[[
	Helper function which returns a function which produces
	numbers which have correct comparisons for that distance
	metric

	e.g. Euclidean distance has to be calculated with a square root
	     at the end.
	     Taking the square root of two numbers doesn't change the
	     comparison of those two numbers - so this can be skipped
	     if you don't need the real value.

	     4 < 9 < 16  ->   2 < 3 < 4
--]]
local get_fast_distance_function = function (geometry, dimensions)
	if geo[geometry] then
		if dimensions == 3 then
			--The fast distance metric is optional - so check it
			--exists
			if geo[geometry]._3d_fast then
				return geo[geometry]._3d_fast
			end
		else
			if geo[geometry]._2d then
				return geo[geometry]._2d
			end
		end
		--If no fast function exists, return the normal one
		return get_distance_function(geometry, dimensions)
	else
		return nil
	end
end

vcnlib.get_fast_distance_function = get_fast_distance_function
