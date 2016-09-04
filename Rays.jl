module Rays

using Vecs: Vec3, unitVector
using Materials
using Entities

immutable Ray
	origin::Vec3
	direction::Vec3
	dot::Float64
	Ray(o, d) = new(o, d, dot(d, d))
end

function pointAt(r::Ray, t::Float64)
	Vec3(r.origin.x + t * r.direction.x, r.origin.y + t * r.direction.y, r.origin.z + t * r.direction.z)
end


function color(r::Ray, depth::Int)
	h = Entities.hitWorld(r, 0.001, Inf)
	if h.t == Inf
		unit_direction = unitVector(r.direction)
		t = 0.5(unit_direction.y + 1)
		return Float64[(1-t) + 0.5t, (1-t)+0.7t, (1-t)+t]
	end
	
	if depth < 50
		s = Materials.scatter(h.material, r, h)
		if s.action
			return s.attenuation .* color(s.ray, depth+1)
		end
	end
	
	return Float64[0.0, 0.0, 0.0]
end



end