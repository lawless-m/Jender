using Vecs: Vec3

abstract Noises

immutable Perlin <: Noises
	random::Vec3
	perm_x::Int
	perm_y::Int
	perm_z::Int
end

function noise(n::Perlin, p::Vec3)
	i = floor(Int, p.x)
	j = floor(Int, p.y)
	k = floor(Int, p.z)
	u = p.x - i
	v = p.y - j
	w = p.z - k
	c = Array{Vec3}(2,2,2)
	for di in 1:2
		for dj in 1:2
			for dk in 1:2
				c[di, dj, dk] = 
https://github.com/petershirley/raytracingthenextweek/blob/master/perlin.h:36

