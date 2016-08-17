#=
C++ version hosted at http://goo.gl/9yItEO http://goo.gl/sBih70

=#


push!(LOAD_PATH, ".")
rand() = 0.25
using Vecs: Vec3, unitVector
using Entities: Entity, Sphere, hitEntity
using Materials: Lambertian, Metal, Dielectric
using Rays: Ray, pointAt
using Cameras: Camera, shoot

function color(r::Ray, world, depth::Int)
	h = hitEntity(world, r, 0.001, Inf)
	if h == nothing
		unit_direction = unitVector(r.direction)
		t = 0.5(unit_direction.y + 1)
		return (1-t) * Vec3(1.0, 1.0, 1.0) + t * Vec3(0.5, 0.7, 1.0)
	end
	
	if depth < 50
		onscreen, scattered, attenuation = Materials.scatter(h.material, r, h)
		if onscreen
			return attenuation * color(scattered, world, depth+1)
		end
	end
	
	return Vec3(0, 0, 0)
end

function push_random_world!(world)
	for a in -11:10
		for b in -11:10
			choose_mat = rand()
			center = Vec3(a + 0.9rand(), 0.2, b + 0.9rand())
			if length(center - Vec3(4, 0.2, 0)) > 0.9
				if choose_mat < 0.8
					push!(world, Sphere(center, 0.2, Lambertian(rand() * rand(), rand() * rand(), rand() * rand())))
				elseif choose_mat < 0.95
					push!(world, Sphere(center, 0.2, Metal(0.5(1+rand()), 0.5(1+rand()), 0.5(1+rand()), 0.5rand())))
				else
					push!(world, Sphere(center, 0.2, Dielectric(1.5)))
				end
			end
		end
	end
end


nx = 1200
ny = 800
ns = 10

pgm = open("r_0.25.pgm", "w")
write(pgm, "P3\n$(nx) $(ny) 255\n")
world = [
			Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5)))
			, Sphere(0, 1, 0, 1.0, Dielectric(1.5)))
			, Sphere(-4, 1, 0, 1.0, Lambertian(0.4, 0.2, 0.1)))
			, Sphere(4, 1, 0, 1.0, Metal(0.7, 0.6, 0.5, 0.0)))
		]

println("Build world")
push_random_world!(world)

camera = Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20, nx/ny, 0.1, 10)

for j in (ny-1):-1:0
	for i in 0:(nx-1)
		col = Vec3(0,0,0)
		for s in 0:ns-1 
			u = (i + rand()) / nx 
			v = (j + rand()) / ny
			r = shoot(camera, u, v)
			p = pointAt(r, 2.0)
			col += color(r, world, 0)
		end
		col /= ns
		col = sqrt(col)
			
		write(pgm, "$(floor(Int,255.99col.x)) $(floor(Int,255.99col.y)) $(floor(Int,255.99col.z))\n")
	end
end
close(pgm)

