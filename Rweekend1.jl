#=
C++ version hosted at http://goo.gl/9yItEO http://goo.gl/sBih70

=#

unshift!(LOAD_PATH, ".")

using Vecs: Vec3, unitVector
using Entities: Entity, Sphere, hitWorld, hitEntity!
using Materials: Lambertian, Metal, Dielectric
using Rays: Ray, pointAt
using Cameras: Camera, shoot

function color(r::Ray, world::Vector{Entity}, depth::Int)
	h = hitWorld(world, r, 0.001, Inf)
	if h == nothing
		unit_direction = unitVector(r.direction)
		t = 0.5(unit_direction.y + 1)
		return [(1-t) + 0.5t, (1-t)+0.7t, (1-t)+t]
	end
	
	if depth < 50
		onscreen, scattered, attenuation = Materials.scatter(h.material, r, h)
		if onscreen
			return attenuation .* color(scattered, world, depth+1)
		end
	end
	
	return [0.0, 0.0, 0.0]
end

function push_random_world!(world::Vector{Entity})
	for a in -11:10
		for b in -11:10
			choose_mat = rand()
			center = Vec3(a + 0.9rand(), 0.2, b + 0.9rand())
			if length(center - Vec3(4.0, 0.2, 0.0)) > 0.9
				if choose_mat < 0.8
					push!(world, Sphere(center, 0.2, Lambertian(rand()*rand(), rand()*rand(), rand()*rand())))
				elseif choose_mat < 0.95
					push!(world, Sphere(center, 0.2, Metal(0.5(1+rand()), 0.5(1+rand()), 0.5(1+rand()), 0.5rand())))
				else
					push!(world, Sphere(center, 0.2, Dielectric(1.5)))
				end
			end
		end
	end
end


world = Entity[
			Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5))
			, Sphere(0, 1, 0, 1.0, Dielectric(1.5))
			, Sphere(-4, 1, 0, 1.0, Lambertian(0.4, 0.2, 0.1))
			, Sphere(4, 1, 0, 1.0, Metal(0.7, 0.6, 0.5, 0.0))
		]

println("Build world")
push_random_world!(world)

const WIDTH = 1200
const HEIGHT = 800
const SAMPLES = 10
const CAMERA = Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20.0, WIDTH/HEIGHT, 0.1, 10.0)

function pixel(world, x::Int, y::Int)
	r = shoot(CAMERA, (x + rand()) / WIDTH, (y + rand()) / HEIGHT)
	p = pointAt(r, 2.0)
	color(r, world, 0)
end

function render(cols::Matrix)
	for j in HEIGHT:-1:1 # makes the next line be a countdown rather than up
		println("Row $j")
		for i in 1:WIDTH
			samples = Matrix{Float64}(SAMPLES, 3)
			#@parallel 
			for s in 1:SAMPLES	
				samples[s,1:3] = pixel(world, i-1, j-1)
			end
			cols[j,i] =  Vec3(sum(samples[1:SAMPLES]), sum(samples[(1+SAMPLES):2SAMPLES]), sum(samples[1+2SAMPLES:3SAMPLES]))
		end
	end
end

function writepgm(cols::Matrix, filename)
	pgm = open("$filename.pgm", "w")
	write(pgm, "P3\n$WIDTH $HEIGHT 255\n")
	for j in HEIGHT:-1:1
		for i in 1:WIDTH
			@printf pgm "%d %d %d\n" [floor(Int,255.99sqrt(v/SAMPLES)) for v in [cols[j,i].x cols[j,i].y cols[j,i].z]]...
		end
	end
	close(pgm)
end

function profiled(cols)
	pixel(world, 50, 50)
	@profile render(cols)
	Profile.print()
end

cols = Matrix{Vec3}(HEIGHT, WIDTH)
render(cols)
writepgm(cols, "Weekend1")


