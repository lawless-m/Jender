module Entities

using Vecs: Vec3
using Materials: Material, Null
using Rays: Ray, pointAt

immutable Hit
	t::Real
	p::Vec3
	normal::Vec3
	material::Material
end

abstract Entity

function hitEntity(world, ray::Ray, t_min::Real, t_max::Real)
	last_hit = Hit(Inf, Vec3(), Vec3(), Null())
	
	for e in world
		h = hitEntity(e, ray, t_min, t_max)
		if h != nothing
			last_hit = h
			t_max = h.t
		end
	end
	if last_hit.t < Inf
		last_hit
	end
	nothing
end

immutable Sphere <: Entity
	center::Vec3
	radius::Real
	material::Material
	Sphere(x, y, z, r, m) = new(Vec3(x, y, z), r, m)
	Sphere(xyz, r, m) = new(xyz, r, m)
end

function hitEntity(s::Sphere, r::Ray, t_min::Real, t_max::Real)
	oc = r.origin - s.center
	b = dot(oc, r.direction)
	c = dot(oc, oc) - s.radius^2
	discriminant = b^2 - r.dot * c
	if discriminant <= 0
		return nothing
	end

	# potential optimisation:  "if t >= tmax return nothing"
	t = (-b - sqrt(discriminant)) / r.dot
	if t < t_max && t > t_min
		p = pointAt(r, t)
		return Hit(t, p, (p - s.center) / s.radius, s.material)
	end
	
	t = (-b + sqrt(discriminant)) / r.dot
	if t < t_max && t > t_min
		p = pointAt(r, t)
		return Hit(t, p, (p - s.center) / s.radius, s.material)
	end
	
end

end

