module Entities

using Vecs
using Materials
using Rays
using Cameras
using Aabbs

export WORLD, World, Entity, Sphere, XY_Rect, XZ_Rect, YZ_Rect, MovingSphere, hitWorld, hitEntity!, pushEntity!, push_random_entities!, pushCamera!

type Hit
	t::Float64
	u::Float64
	v::Float64
	p::Vec3
	normal::Vec3
	material::Material
	Hit(t_max) = new(t_max, 0, 0, Vec3(), Vec3(), Materials.Null())
end

abstract Entity

immutable World
	entities::Vector{Entity}
	cameras::Vector{Camera}
	World() = new(Entity[], Camera[])
	World(e) = new(e, Camera[])
	World(e, c) = new(e, c)
end

const WORLD = World()

function pushEntity!(en::Entity)
	push!(WORLD.entities, en)
end

function pushCamera!(c::Camera)
	push!(WORLD.cameras, c)
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
	radius_sq::Float64
	material::Material
	Sphere(x, y, z, r, m) = new(Vec3(x, y, z), r, r^2, m)
	Sphere(xyz, r, m) = new(xyz, r, r^2, m)
end

function hitEntity!(last_hit::Hit, s::Sphere, ray::Ray, t_min::Float64)
	oc = ray.origin - s.center
	b = dot(oc, ray.direction)
	c = dot(oc, oc) - s.radius_sq
	if b^2 <= ray.dot * c # discriminant <= 0
		return
	end
	sd = sqrt(b^2 - ray.dot * c) # sqrt discriminant
	tmx = last_hit.t * ray.dot + b
	tmn = t_min * ray.dot + b
	if -sd < tmx &&  -sd > tmn
		last_hit.t = (-b - sd) / ray.dot
		last_hit.p = pointRayAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / ray.dot
		last_hit.p = pointRayAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
	end
end

function bounding_box(s::Sphere, t0::Float64, t1::Float64)
    Aabb(s.center - Vec3(s.radius), s.center + Vec3(s.radius));
end

immutable MovingSphere <: Entity
	center0::Vec3
	center1::Vec3
	time0::Float64
	time1::Float64
	radius::Float64
	radius_sq::Float64
	material::Material
	MovingSphere(x0, y0, z0, x1, y1, z1, t0, t1, r, m) = new(Vec3(x0, y0, z0), Vec3(x1, y1, z1), t0, t1, r, r^2, m)
	MovingSphere(xyz0, xyz1, t0, t1, r, m) = new(xyz0, xyz1, t0, t1, r, r^2, m)
end

function hitEntity!(last_hit::Hit, s::MovingSphere, ray::Ray, t_min::Float64)
	senter = center(s, ray.time)
	oc = ray.origin - senter
	b = dot(oc, ray.direction)
	c = dot(oc, oc) - s.radius_sq
	if b^2 <= ray.dot * c # discriminant <= 0
		return
	end
	sd = sqrt(b^2 - ray.dot * c) # sqrt discriminant
	tmx = last_hit.t * ray.dot + b
	tmn = t_min * ray.dot + b
	if -sd < tmx &&  -sd > tmn
		last_hit.t = (-b - sd) / ray.dot
		last_hit.p = pointRayAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - senter) / s.radius
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / ray.dot
		last_hit.p = pointRayAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - senter) / s.radius
		last_hit.material = s.material
	end
end

function center(s::MovingSphere, time::Float64)
    s.center0 + ((time - s.time0) / (s.time1 - s.time0))*(s.center1 - s.center0);
end

function bounding_box(s::MovingSphere, t0::Float64, t1::Float64)
    surrounding_box(Aabb(s.center(t0) - Vec3(s.radius), s.center(t0) + Vec3(s.radius)), Aabb(s.center(t1) - Vec3(s.radius), s.center(t1) + Vec3(s.radius)));
end

immutable XY_Rect <: Entity
	x0::Float64
	y0::Float64
	x1::Float64
	y1::Float64
	k::Float64
	material::Material
	XY_Rect(x0, y0, x1, y1, k, m) = new(x0, y0, x1, y1, k, m)
end

function bounding_box(r::XY_Rect, t0::Float64, t1::Float64)
	Aabb(Vec3(r.x0, r.y0, r.k-0.0001), Vec3(r.x1, r.y1, k+0.0001))
end

function hitEntity!(last_hit::Hit, r::XY_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.z) / ray.direction.z
	if t < t_min || t > last_hit.t
		return
	end
	
	x = ray.origin.x + t * ray.direction.x
	if x < r.x0 || x > r.x1
		return
	end
	
	y = ray.origin.y + t * ray.direction.y
	if y < r.y0 || y > r.y1
		return
	end
	
	last_hit.u = (x - r.x0) / (r.x1 - r.x0)
	last_hit.v = (y - r.y0) / (r.y1 - r.y0)
	last_hit.t = t
	last_hit.material = r.material
	last_hit.p = pointRayAt(ray, t)
	last_hit.normal = Vec3(0,0,1)
end

immutable XZ_Rect <: Entity
	x0::Float64
	z0::Float64
	x1::Float64
	z1::Float64
	k::Float64
	material::Material
	XZ_Rect(x0, z0, x1, z1, k, m) = new(x0, z0, x1, z1, k, m)
end

function bounding_box(r::XZ_Rect, t0::Float64, t1::Float64)
	Aabb(Vec3(r.x0, r.k-0.000, r.z0), Vec3(r.x1, k+0.0001, r.z1))
end

function hitEntity!(last_hit::Hit, r::XZ_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.y) / ray.direction.y
	if t < t_min || t > last_hit.t
		return
	end
	
	x = ray.origin.x + t * ray.direction.x
	if x < r.x0 || x > r.x1
		return
	end
	
	z = ray.origin.z + t * ray.direction.z
	if z < r.z0 || z > r.z1
		return
	end
	
	last_hit.u = (x - r.x0) / (r.x1 - r.x0)
	last_hit.v = (z - r.z0) / (r.z1 - r.z0)
	last_hit.t = t
	last_hit.material = r.material
	last_hit.p = pointRayAt(ray, t)
	last_hit.normal = Vec3(0,1,0)
end


immutable YZ_Rect <: Entity
	y0::Float64
	z0::Float64
	y1::Float64
	z1::Float64
	k::Float64
	material::Material
	YZ_Rect(y0, z0, y1, z1, k, m) = new(y0, z0, y1, z1, k, m)
end

function bounding_box(r::YZ_Rect, t0::Float64, t1::Float64)
	Aabb(Vec3(r.k-0.000, r.y0, r.z0), Vec3(k+0.0001, r.y1, r.z1))
end

function hitEntity!(last_hit::Hit, r::YZ_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.x) / ray.direction.x
	if t < t_min || t > last_hit.t
		return
	end
	
	y = ray.origin.y + t * ray.direction.y
	if y < r.y0 || y > r.y1
		return
	end
	
	z = ray.origin.z + t * ray.direction.z
	if z < r.z0 || z > r.z1
		return
	end
	
	last_hit.u = (y - r.y0) / (r.y1 - r.y0)
	last_hit.v = (z - r.z0) / (r.z1 - r.z0)
	last_hit.t = t
	last_hit.material = r.material
	last_hit.p = pointRayAt(ray, t)
	last_hit.normal = Vec3(1,0,0)
end



end