module Entities

using Vecs
using Materials
using Rays
using Cameras
using Aabbs

export WORLD, World, Entity, Hit, Sphere, XY_Rect, XZ_Rect, YZ_Rect, FlippedNormal, yRotated, Translated, MovingSphere, Box, hitWorld, hitEntity!, pushEntity!, push_random_entities!, pushCamera!

type Hit
	t::Float64
	u::Float64
	v::Float64
	p::Vec3
	normal::Vec3
	material::Material
	Hit(t_max) = new(t_max, 0, 0, Vec3(), Vec3(), Materials.Null())
	Hit() = Hit(Inf)
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

function hitEntity!(hit::Hit, entities::Vector{Entity}, ray::Ray, t_min::Float64)
	for entity in entities
		hitEntity!(hit, entity, ray, t_min)
	end
end

immutable Sphere <: Entity
	center::Vec3
	radius::Float64
	radius_sq::Float64
	material::Material
	bbox::Aabb
	Sphere(c, r, m) = new(c, r, r^2, m, Aabb(s.center - Vec3(s.radius), s.center + Vec3(s.radius));)
	Sphere(x, y, z, r, m) = new(Vec3(x, y, z), r, m)
	Sphere(xyz, r, m) = new(xyz, r, r^2, m)
end

function hitEntity!(hit::Hit, s::Sphere, ray::Ray, t_min::Float64)
	oc = ray.origin - s.center
	b = dot(oc, ray.direction)
	c = dot(oc, oc) - s.radius_sq
	if b^2 <= ray.dot * c # discriminant <= 0
		return
	end
	sd = sqrt(b^2 - ray.dot * c) # sqrt discriminant
	tmx = hit.t * ray.dot + b
	tmn = t_min * ray.dot + b
	if -sd < tmx &&  -sd > tmn
		hit.t = (-b - sd) / ray.dot
		hit.p = pointRayAt(ray, hit.t)
		hit.normal = (hit.p - s.center) / s.radius
		hit.material = s.material
	elseif sd < tmx && sd > tmn
		hit.t = (-b + sd) / ray.dot
		hit.p = pointRayAt(ray, hit.t)
		hit.normal = (hit.p - s.center) / s.radius
		hit.material = s.material
	end
end

function bounding_box(s::Sphere, t0::Float64, t1::Float64)
    s.bbox
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

function hitEntity!(hit::Hit, s::MovingSphere, ray::Ray, t_min::Float64)
	senter = center(s, ray.time)
	oc = ray.origin - senter
	b = dot(oc, ray.direction)
	c = dot(oc, oc) - s.radius_sq
	if b^2 <= ray.dot * c # discriminant <= 0
		return
	end
	sd = sqrt(b^2 - ray.dot * c) # sqrt discriminant
	tmx = hit.t * ray.dot + b
	tmn = t_min * ray.dot + b
	if -sd < tmx &&  -sd > tmn
		hit.t = (-b - sd) / ray.dot
		hit.p = pointRayAt(ray, hit.t)
		hit.normal = (hit.p - senter) / s.radius
		hit.material = s.material
	elseif sd < tmx && sd > tmn
		hit.t = (-b + sd) / ray.dot
		hit.p = pointRayAt(ray, hit.t)
		hit.normal = (hit.p - senter) / s.radius
		hit.material = s.material
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
	bbox::Aabb
	XY_Rect(x0, y0, x1, y1, k, m) = new(x0, y0, x1, y1, k, m, Aabb(Vec3(r.x0, r.y0, r.k-0.0001), Vec3(r.x1, r.y1, k+0.0001)))
end

function bounding_box(r::XY_Rect, t0::Float64, t1::Float64)
	r.bbox
end

function hitEntity!(hit::Hit, r::XY_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.z) / ray.direction.z
	if t < t_min || t > hit.t
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
	
	hit.u = (x - r.x0) / (r.x1 - r.x0)
	hit.v = (y - r.y0) / (r.y1 - r.y0)
	hit.t = t
	hit.material = r.material
	hit.p = pointRayAt(ray, t)
	hit.normal = Vec3(0,0,1)
end

immutable XZ_Rect <: Entity
	x0::Float64
	z0::Float64
	x1::Float64
	z1::Float64
	k::Float64
	material::Material
	bbox::Aabb
	XZ_Rect(x0, z0, x1, z1, k, m) = new(x0, z0, x1, z1, k, m, Aabb(Vec3(r.x0, r.k-0.000, r.z0), Vec3(r.x1, k+0.0001, r.z1)))
end

function bounding_box(r::XZ_Rect, t0::Float64, t1::Float64)
	r.bbox
end

function hitEntity!(hit::Hit, r::XZ_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.y) / ray.direction.y
	if t < t_min || t > hit.t
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
	
	hit.u = (x - r.x0) / (r.x1 - r.x0)
	hit.v = (z - r.z0) / (r.z1 - r.z0)
	hit.t = t
	hit.material = r.material
	hit.p = pointRayAt(ray, t)
	hit.normal = Vec3(0,1,0)
end


immutable YZ_Rect <: Entity
	y0::Float64
	z0::Float64
	y1::Float64
	z1::Float64
	k::Float64
	material::Material
	bbox::Aabb
	YZ_Rect(y0, z0, y1, z1, k, m) = new(y0, z0, y1, z1, k, m, Aabb(Vec3(r.k-0.000, r.y0, r.z0), Vec3(k+0.0001, r.y1, r.z1)))
end

function bounding_box(r::YZ_Rect, t0::Float64, t1::Float64)
	r.bbox
end

function hitEntity!(hit::Hit, r::YZ_Rect, ray::Ray, t_min::Float64)
	t = (r.k - ray.origin.x) / ray.direction.x
	if t < t_min || t > hit.t
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
	
	hit.u = (y - r.y0) / (r.y1 - r.y0)
	hit.v = (z - r.z0) / (r.z1 - r.z0)
	hit.t = t
	hit.material = r.material
	hit.p = pointRayAt(ray, t)
	hit.normal = Vec3(1,0,0)
end

immutable FlippedNormal <: Entity
	entity::Entity
	FlippedNormal(e) = new(e)
end

function hitEntity!(hit::Hit, e::FlippedNormal, ray::Ray, t_min::Float64)
	t = hit.t
	hitEntity!(hit, e.entity, ray, t_min)
	if hit.t < t
		hit.normal = -hit.normal
	end
end

function bounding_box(e::FlippedNormal, t0::Float64, t1::Float64)
	bounding_box(e.entity, t0, t1)
end

immutable Translated <: Entity
	entity::Entity
	offset::Vec3
	Translated(e, o) = new(e, o)
end

function hitEntity!(hit::Hit, e::Translated, ray::Ray, t_min::Float64)
	t = hit.t
	hitEntity!(hit, e.entity, ray, t_min)
	if hit.t < t
		hit.p += e.offset
	end
end

function bounding_box(e::Translated, t0::Float64, t1::Float64)
	bbox = bounding_box(e.entity, t0, t1)
	Aabb(box.min + e.offset, box.max + e.offset)
end

immutable yRotated <: Entity
	entity::Entity
	sin_theta::Float64
	cos_theta::Float64
	hasbox::Bool
	bbox::Aabb
	function yRotated(e::Entity, angle::Float64)
		rads = angle * pi / 180
		sin_theta = sin(rads)
		cos_theta = cos(rads)
		bbox = bounding_box(e, 0.0, 1.0)
		mn = [Inf, Inf, Inf]
		mx = [-Inf, -Inf, -Inf]
		for i in 0:1, j in 0:1, k in 0:1
			x = i * bbox.max.x + (1-i) * bbox.min.x
			y = j * bbox.max.y + (1-j) * bbox.min.y
			z = k * bbox.max.z + (1-k) * bbox.min.z
			newx = cos_theta * x + sin_theta * z
			newz = -sin_theta * x + cos_theta * z
			test = [newx, y, newz]
			for c in 1:3
				mx[c] = max(mx[c], test[c])
				mn[c] = min(mn[c], test[c])
			end
		end
		new(e, sin_theta, cos_theta, true, Aabb(mn, mx))
	end
end

function hitEntity!(hit::Hit, e::yRotated, ray::Ray, t_min::Float64)
	rotated = Ray(Vec3(e.cos_theta * ray.origin.x - e.sin_theta * ray.origin.z, ray.origin.y, e.sin_theta * ray.origin.x + e.cos_theta * ray.origin.z), Vec3(e.cos_theta * ray.direction.x - e.sin_theta * ray.direction.z, ray.direction.y, e.sin_theta * ray.direction.x + e.cos_theta * ray.direction.z), ray.time)
	t = hit.t
	hitEntity!(hit, e.entity, rotated, t_min)
	if hit.t < t
		hit.p = Vec3(e.cos_theta * hit.p.x + e.sin_theta * hit.p.z, hit.p.y, -e.sin_theta * hit.p.x + e.sin_theta * hit.p.z)
		hit.normal = Vec3(e.cos_theta * hit.normal.x + e.sin_theta * hit.normal.z, hit.normal.y, -e.sin_theta * hit.normal.x + e.sin_theta * hit.normal.z)
	end
end

immutable Box <: Entity
	pmin::Vec3
	pmax::Vec3
	entities::Vector{Entity}
	function Box(p0::Vec3, p1::Vec3, m::Material)
		e = Vector{Entity}()
		push!(e, XY_Rect(p0.x, p1.x, p0.y, p1.y, p1.z, m))
		push!(e, FlippedNormal(XY_Rect(p0.x, p1.x, p0.y, p1.y, p0.z, m)))
		push!(e, XZ_Rect(p0.x, p1.x, p0.z, p1.z, p1.y, m))
		push!(e, FlippedNormal(XZ_Rect(p0.x, p1.x, p0.z, p1.z, p0.y, m)))
		push!(e, YZ_Rect(p0.y, p1.y, p0.z, p1.z, p1.x, m))
		push!(e, FlippedNormal(YZ_Rect(p0.y, p1.y, p0.z, p1.z, p0.x, m)))
		new(p0, p1, e)
	end
end

function hitEntity!(hit::Hit, b::Box, ray::Ray, t_min::Float64)
	hitEntity!(hit, b.entities, ray, t_min)
end

function bounding_box(b::Box, t0::Float64, t1::Float64)
	Aabb(b.pmin, b.pmax)
end



















end
