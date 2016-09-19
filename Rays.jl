module Rays

using Vecs
using Entities
using Materials

export Ray, pointRayAt, rayColor

immutable Ray
	origin::Vec3
	direction::Vec3
	time::Float64
	dot::Float64
	Ray(o, d, t) = new(o, d, t, dot(d, d))
end

function pointRayAt(r::Ray, t::Float64)
	r.origin + t * r.direction
end

function rayColor(r::Ray, depth::Int)
	h = hitWorld(WORLD, r, 0.001, Inf)
	if h == nothing
		unit_direction = unitVector(r.direction)
		t = 0.5(unit_direction.y + 1)
		return [(1-t) + 0.5t, (1-t)+0.7t, (1-t)+t]
	end
	
	if depth < 50
		onscreen, scattered, attenuation = scatter(h.material, r, h)
		if onscreen
			return attenuation .* rayColor(scattered, depth+1)
		end
	end
	
	return [0.0, 0.0, 0.0]
end

end