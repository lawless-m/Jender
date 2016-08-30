module Rays

using Vecs: Vec3

immutable Ray
	origin::Vec3
	direction::Vec3
	dot::Float64
	Ray(o, d) = new(o, d, dot(d, d))
end

function pointAt(r::Ray, t::Float64)
	Vec3(r.origin.x + t * r.direction.x, r.origin.y + t * r.direction.y, r.origin.z + t * r.direction.z)
end

end