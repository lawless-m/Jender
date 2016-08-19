module Entities

using Vecs: Vec3
using Materials: Material, Null
using Rays: Ray, pointAt

type Hit
	t::Float64
	p::Vec3
	normal::Vec3
	material::Material
end

abstract Entity

function hitWorld(world::Vector{Entity}, ray::Ray, t_min::Float64, t_max::Float64)
	last_hit = Hit(t_max, Vec3(), Vec3(), Null())
	for entity in world
		hitEntity!(last_hit, entity, ray, t_min)
	end
	if last_hit.t < t_max
		return last_hit
	end
end

immutable Sphere <: Entity
	center::Vec3
	radius::Float64
	radius2::Float64
	material::Material
	Sphere(x, y, z, r, m) = new(Vec3(x, y, z), r, r^2, m)
	Sphere(xyz, r, m) = new(xyz, r, r^2, m)
end

function hitEntity!(last_hit::Hit, s::Sphere, ray::Ray, t_min::Float64)
	oc = Vec3(ray.origin.x - s.center.x, ray.origin.y - s.center.y, ray.origin.z - s.center.z) #oc = ray.origin - s.center
	b = dot(oc, ray.direction)
	c = dot(oc, oc) - s.radius2
	discriminant = b^2 - ray.dot * c

	if discriminant <= 0
		return
	end

	# potential optimisation:  "if t >= tmax return nothing"
	
	t = (-b - sqrt(discriminant)) / ray.dot
	if t < last_hit.t && t > t_min
		last_hit.t = t
		last_hit.p = pointAt(ray, t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
		return
	end
	
	t = (-b + sqrt(discriminant)) / ray.dot
	if t < last_hit.t && t > t_min
		last_hit.t = t
		last_hit.p = pointAt(ray, t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
		return
	end
end

end

