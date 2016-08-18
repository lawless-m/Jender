module Vecs


immutable Vec3
	x::Float64
	y::Float64
	z::Float64
	Vec3() = new(0.0, 0.0, 0.0)
	Vec3(x, y, z) = new(x, y, z)
	Vec3(v::Vector{Float64}) = new(v[1], v[2], v[3])
	Vec3(v::Vec3) = new(v.x, v.y, v.z)
end

function Vec3rand()
	Vec3(rand(), rand(), rand())
end

function Base.(:(length))(v::Vec3)
	sqrt(squaredLength(v))
end

function tripleProduct(a::Vec3, b::Vec3, c::Vec3)
	dot(cross(a, b), c)
end

function Base.(:(-))(v::Vec3)
	Vec3(-v.x, -v.y, -v.z)
end

function Base.(:(sqrt))(v::Vec3)
	Vec3(sqrt(v.x), sqrt(v.y), sqrt(v.z))
end

function Base.(:(/))(v::Vec3, f::Real)
	Vec3(v.x/f, v.y/f, v.z/f)
end

function Base.(:(*))(v::Vec3, f::Real)
	Vec3(v.x*f, v.y*f, v.z*f)
end

function Base.(:(*))(f::Real, v::Vec3)
	Vec3(v.x*f, v.y*f, v.z*f)
end

function Base.(:(*))(a::Vec3, b::Vec3)
	Vec3(a.x*b.x, a.y*b.y, a.z*b.z)
end

function Base.(:(+))(a::Vec3, b::Vec3)
	Vec3(a.x+b.x, a.y+b.y, a.z+b.z)
end

function Base.(:(-))(a::Vec3, b::Vec3)
	Vec3(a.x-b.x, a.y-b.y, a.z-b.z)
end

function Base.(:(dot))(a::Vec3, b::Vec3)
	a.x*b.x + a.y*b.y + a.z*b.z
end

function Base.(:(cross))(a::Vec3, b::Vec3)
	Vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
end

function Base.(:(==))(a::Vec3, b::Vec3)
	a.x==b.x && a.y==b.y && a.z==b.z
end

function squaredLength(v::Vec3)
	v.x^2 + v.y^2 + v.z^2
end

function unitVector(v::Vec3)
	v / length(v)
end

function Base.(:(min))(v::Vec3)
	min(v.x, v.y, v.z)
end

function minAbs(v::Vec3)
	min(abs(v.x), abs(v.y), abs(v.z))
end

function Base.(:(max))(v::Vec3)
	max(v.x, v.y, v.z)
end

function maxAbs(v::Vec3)
	max(abs(v.x), abs(v.y), abs(v.z))
end

function maxVec(a::Vec3, b::Vec3)
	Vec3(max(a.x, b.x), max(a.y, b.y), max(a.z, b.z))
end

function minVec(a::Vec3, b::Vec3)
	Vec3(min(a.x, b.x), min(a.y, b.y), min(a.z, b.z))
end

function whichIs(v::Vec3, f)
	m = f(v)
	if v.e[1] == m
		'x'
	elseif v.e[2] == m
		'y'
	elseif v.e[3] == m
		'z'
	end
end

end