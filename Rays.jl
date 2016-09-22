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
	hit = Hit()
	hitEntity!(hit, WORLD.entities, r, 0.001)
	if hit.t == Inf
		return RGB(0.0)
	end
	emission = emit(hit.material, hit.u, hit.v, hit.p)
	if depth < 50
		onscreen, scattered, attenuation = scatter(hit.material, r, hit)
		if onscreen
			return emission + attenuation * rayColor(scattered, depth+1)
		end
	end
	return emission
end

end