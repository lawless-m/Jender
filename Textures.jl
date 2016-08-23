using Vecs: Vec3
using Noises: Perlin, turbulence

abstract Texture

immutable Constant <: Texture
	color::Vec3
end

function value(c::Constant, u::Float64, v::Float64)
	c.color
end

immutable Checker <: Texture
	odd::Texture
	even::Texture
end

function value(c::Checker, p::Vec3, u::Float64, v::Float64)
	if sin(10p.x) * sin(10p.y) * sin(10p.z) < 0
		value(c.odd, u, v, p)
	else
		value(c.even, u, v, p)
	end
end

immutable Noise <: Texture
	noise::Perlin
	scale::Float64
end

function value(n::Noise, p::Vec3, u::Float64, v::Float64)
	Vec3(1) * 0.5(1 + sin(n.scale*p.x + 5turbulence(n.noise, n.scale*p)))
end

