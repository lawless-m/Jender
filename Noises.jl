module Noises

using Vecs

export Noises, Perlin, turbulence

abstract Noise

immutable Perlin <: Noise
	random::Vector{Vec3}
	perm_x::Vector{Int}
	perm_y::Vector{Int}
	perm_z::Vector{Int}
	
	Perlin(r, x, y, z) = new(r, x, y, z)
	function Perlin()		
		v = Vector{Vec3}(256)
		for i in 1:256
			v[i] = unitVector(-1 + 2rand(), -1 + 2rand(), -1 + 2rand())
		end
		new(v, shuffle!([0:255]), shuffle!([0:255]), shuffle!([0:255]))
	end
end

function interpolate(c::Array{Vec3}, u::Float64, v::Float64, w::Float64)
	uu = u^2 * (3-2u)
	vv = v^2 * (3-2v)
	ww = w^2 * (3-2w)
	accum = 0.0
	for i in 0:1, j in 0:1, k in 0:1
		accum += (iuu + (1-i)*(1-uu)) * (j*vv + (1-j)*(1-vv)) * (k*ww + (1-k)*(1-ww)) * dot(c[i+1][k+1][k+1], Vec3(u-i, v-j, w-k))
	end 
	accum
end

function turbulence(n::Perlin, p::Vec3, depth::Int=7)
	accum = 0.0
	temp_p = Vec3(p)
	weight = 1.0
	for i in 0:depth-1
		accum += weight * noise(n, temp_p)
		weight = 0.5weight
		temp_p = 2temp_p
	end
	return abs(accum)
end

function noise(n::Perlin, p::Vec3)
	i = floor(Int, p.x)
	j = floor(Int, p.y)
	k = floor(Int, p.z)
	u = p.x - i
	v = p.y - j
	w = p.z - k
	c = Array{Vec3}(2,2,2)
	for di in 0:1, dj in 0:1, dk in 0:1
		c[di, dj, dk] = n.ranvec[n.perm_x[((i+di)&255)+1] $ n.perm_y[((j+dj)&255)+1] $ n.perm_z[((k+dk)&255)+1]]
	end
	interpolate(c, u, v, w)
end

end