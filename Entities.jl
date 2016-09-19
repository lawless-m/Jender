module Entities

using Vecs
using Materials
using Rays
using Cameras
using Aabbs

export WORLD, World, Entity, Sphere, MovingSphere, hitWorld, hitEntity!, pushEntity!, push_random_entities!, pushCamera!

type Hit
	t::Float64
	p::Vec3
	normal::Vec3
	material::Materials.Material
	Hit(t_max) = new(t_max, Vec3(), Vec3(), Materials.Null())
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

function push_random_entities!()
	for a in -11:10
		for b in -11:10
			choose_mat = rand()
			center = Vec3(a + 0.9rand(), 0.2, b + 0.9rand())
			if length(center - Vec3(4.0, 0.2, 0.0)) > 0.9
				if choose_mat < 0.8
					pushEntity!(Sphere(center, 0.2, Materials.Lambertian(rand()*rand(), rand()*rand(), rand()*rand())))
				elseif choose_mat < 0.95
					pushEntity!(Sphere(center, 0.2, Materials.Metal(0.5(1+rand()), 0.5(1+rand()), 0.5(1+rand()), 0.5rand())))
				else
					pushEntity!(Sphere(center, 0.2, Materials.Dielectric(1.5)))
				end
			end
		end
	end
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
	material::Materials.Material
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
		last_hit.p = pointAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - s.center) / s.radius
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / ray.dot
		last_hit.p = pointAt(ray, last_hit.t)
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
	material::Materials.Material
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
		last_hit.p = pointAt(ray, last_hit.t)
		last_hit.normal = (last_hit.p - senter) / s.radius
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / ray.dot
		last_hit.p = pointAt(ray, last_hit.t)
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

end

