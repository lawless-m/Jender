module Entities

using Vecs: Vec3
using Materials
using Rays: Ray, pointAt
using Cameras: Camera

macro dot(a, b)
	:($a.x*$b.x + $a.y*$b.y + $a.z*$b.z)
end

macro pointAt(r, t)
	:(Vec3($r.origin.x + $t * $r.direction.x, $r.origin.y + $t * $r.direction.y, $r.origin.z + $t * $r.direction.z))
end

macro diff(r, s)
	:(Vec3($r.x - $s.x, $r.y - $s.y, $r.z - $s.z))
end

macro diffdiv(r, s, f)
	:(Vec3(($r.x - $s.x)/$f, ($r.y - $s.y)/$f, ($r.z - $s.z)/$f))
end

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

function pushCamera!(c::Camera)
	push!(WORLD.cameras, c)
end

function pushEntity!(en::Entity)
	push!(WORLD.entities, en)
end

function hitWorld(ray::Ray, t_min::Float64, t_max::Float64)
	last_hit = Hit(t_max)
	for entity in WORLD.entities
		hitEntity!(last_hit, entity, ray, t_min)
	end
	return last_hit
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

immutable Sphere <: Entity
	center::Vec3
	radius::Float64
	radius2::Float64
	material::Materials.Material
	Sphere(x, y, z, r, m) = new(Vec3(x, y, z), r, r^2, m)
	Sphere(xyz, r, m) = new(xyz, r, r^2, m)
end

function hitEntity!(last_hit::Hit, s::Sphere, ray::Ray, t_min::Float64)
	oc = @diff(ray.origin, s.center)
	b = @dot(oc, ray.direction)
	c = (@dot oc oc) - s.radius2
	
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

	rdot = ray.dot
	sd = sqrt(b^2 - rdot * c) # sqrt discriminant
	
	tmx = last_hit.t * rdot + b
	tmn = t_min * rdot + b
	
	if -sd < tmx &&  -sd > tmn
		last_hit.t = (-b - sd) / rdot
		last_hit.p = @pointAt(ray, last_hit.t)
		last_hit.normal = @diffdiv(last_hit.p, s.center, s.radius)
		last_hit.material = s.material
	elseif sd < tmx && sd > tmn
		last_hit.t = (-b + sd) / rdot
		last_hit.p = @pointAt(ray, last_hit.t)
		last_hit.normal = @diffdiv(last_hit.p, s.center, s.radius)
		last_hit.material = s.material
	end
	return
end

end

