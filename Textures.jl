module Textures

using Vecs
using Noises

export Texture, Constant, Checker, Noise, Image, value

abstract Texture

immutable Constant <: Texture
	color::Vec3
	Constant(rgb) = new(Vec3(rgb, rgb, rgb))
	Constant(r, g, b) = new(Vec3(r, g, b))
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
	Noise(p, s) = new(p, s)
	Noise(s) = new(Perlin(), s)
end

function value(n::Noise, p::Vec3, u::Float64, v::Float64)
	Vec3(1) * 0.5(1 + sin(n.scale*p.x + 5turbulence(n.noise, n.scale*p)))
end

immutable Image <: Texture
	rgb::Matrix{Vec3}
end

function value(img::Image, p::Vec3, u::Float64, v::Float64)
	w, h = size(img)
	i = min(max(0, floor(Int, w*u)), w-1)
	j = min(max(0, floor(Int, h*(1-v) - 0.001)), h-1)
	img.rgb[i, j]
end

end