module Entities

using Vecs: Vec3
using Materials: Material, Null
using Rays: Ray, pointAt
using Cameras: Camera

type Hit
	t::Float64
	p::Vec3
	normal::Vec3
	material::Material
	Hit(t_max) = new(t_max, Vec3(), Vec3(), Null())
end

abstract Entity

immutable World
	entities::Vector{Entity}
	cameras::Vector{Camera}
end

function hitWorld(world::World, ray::Ray, t_min::Float64, t_max::Float64)
	last_hit = Hit(t_max)
	for entity in world.entities
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
	
#=	discriminant = b^2 - ray.dot * c
	if discriminant <= 0
		return
	end
	sd = sqrt(discriminant)
	
	# marginally better to to away with the assignments
=#	
	if b^2 <= ray.dot * c 
		return
	end

	sd = sqrt(b^2 - ray.dot * c) # sqrt discriminant
	
	tmx = last_hit.t * ray.dot + b
	tmn = t_min * ray.dot + b
	
	if -sd < tmx &&  -sd > tmn
		last_hit.t = (-b - sd) / ray.dot
		last_hit.p = pointAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / ray.dot
		last_hit.p = pointAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
		return
	end
end

end

