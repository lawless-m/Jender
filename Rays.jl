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
	Ray(o, d) = new(o, d, 0.0)
	Ray() = new(Vec3(), Vec3(), 0, 0)
end

function pointRayAt(r::Ray, t::Float64)
	r.origin + t * r.direction
end

function rayColor(r::Ray, depth::Int)
	h = hitWorld(WORLD, r, 0.001, Inf)
	if h == nothing
		return RGB(0.0)
	end
	emission = emit(h.material, h.u, h.v, h.p)
	if depth < 50
		onscreen, scattered, attenuation = scatter(h.material, r, h)
		if onscreen
			return emission + attenuation * rayColor(scattered, depth+1)
		end
	end
	return emission
end

end