#=
C++ version hosted at http://goo.gl/9yItEO http://goo.gl/sBih70

=#

unshift!(LOAD_PATH, ".")

using Vecs: zero, Vec3, unitVector
using Entities: World, Entity, Sphere, hitWorld, hitEntity!
using Materials: Material, Lambertian, Metal, Dielectric
using Rays: Ray, pointAt
using Cameras: Camera, shoot

function color(r::Ray, depth::Int)
	h = hitWorld(WORLD, r, 0.001, Inf)
	if h.t == Inf
		unit_direction = unitVector(r.direction)
		t = 0.5(unit_direction.y + 1)
		return Float64[(1-t) + 0.5t, (1-t)+0.7t, (1-t)+t]
	end
	
	if depth < 50
		s = Materials.scatter(h.material, r, h)
		if s.action
			return s.attenuation .* color(s.ray, depth+1)
		end
	end
	
	return Float64[0.0, 0.0, 0.0]
end

function push_random_entities!()
	for a in -11:10
		for b in -11:10
			choose_mat = rand()
			center = Vec3(a + 0.9rand(), 0.2, b + 0.9rand())
			if length(center - Vec3(4.0, 0.2, 0.0)) > 0.9
				if choose_mat < 0.8
					push!(WORLD.entities, Sphere(center, 0.2, Lambertian(rand()*rand(), rand()*rand(), rand()*rand())))
				elseif choose_mat < 0.95
					push!(WORLD.entities, Sphere(center, 0.2, Metal(0.5(1+rand()), 0.5(1+rand()), 0.5(1+rand()), 0.5rand())))
				else
					push!(WORLD.entities, Sphere(center, 0.2, Dielectric(1.5)))
				end
			end
		end
	end
end

function render(cols::Matrix{Vec3}, numsamples::Int)
	samples = Matrix{Float64}(numsamples, 3)
	
	for i in 1:size(cols)[2]
		println("Column $(size(cols)[2]-i)")
			#@parallel 
		for j in 1:size(cols)[1] 
			for s in 1:numsamples
				samples[s,1:3] = color(shoot(WORLD.cameras[1], (i-1 + rand()) / size(cols)[2], (j-1 + rand()) / size(cols)[1]), 0)
			end
			cols[j,i] =  Vec3(sum(samples[1:numsamples]) / numsamples, sum(samples[(1+numsamples):2numsamples]) / numsamples, sum(samples[1+2numsamples:3numsamples]) / numsamples)
		end
	end
end

function writepgm(cols::Matrix, filename)
	f(v::Float64) = floor(Int,255.99*sqrt(v))
	pgm = open("$filename.pgm", "w")
	write(pgm, "P3\n$(size(cols)[2]) $(size(cols)[1]) 255\n")
	for j in size(cols)[1]:-1:1
		for i in 1:size(cols)[2]
			write(pgm, "$(f(cols[j,i].x)) $(f(cols[j,i].y)) $(f(cols[j,i].z)) ")
		end
		write(pgm, "\n")
	end
	close(pgm)
end

srand(0)
const SAMPLES = 10
const WORLD = World(Entity[
			Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5))
			, Sphere(0, 1, 0, 1.0, Dielectric(1.5))
			, Sphere(-4, 1, 0, 1.0, Lambertian(0.4, 0.2, 0.1))
			, Sphere(4, 1, 0, 1.0, Metal(0.7, 0.6, 0.5, 0.0))
		])
push!(WORLD.cameras, Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20.0, 3/2, 0.1, 10.0))

println("Build world")
push_random_entities!()

function noprofile()
	cols = Matrix{Vec3}(2*400, 3*400) # height, width
	@time render(cols, SAMPLES)
	writepgm(cols, "Weekend1")
end

function profiled()
	cols = Matrix{Vec3}(2*100, 3*100) # height, width		#addcolor!(shoot(WORLD.cameras[1], 50.5/size(cols)[2], 60.5/size(cols)[1]), 0)
	render(cols, 3)
	#Profile.clear_malloc_data() # julia --track-allocation=user main.jl
	@profile render(cols, 3)
	Profile.print()
	writepgm(cols, "Profiled")
end

function timed()
	cols = Matrix{Vec3}(2*200, 3*200) # height, width
	@time color(shoot(WORLD.cameras[1], 50.5/size(cols)[2], 60.5/size(cols)[1]), 0)
	#println(c) #   Vecs.RGB(0.1087251386964388,0.0434686890557862,0.18448252480043215)
	#quit()
	@time render(cols, 3)
	@time render(cols, 3)
	# 42.015203 seconds (1.88 G allocations: 70.071 GB, 8.08% gc time)
	writepgm(cols, "Profiled")
end	

timed()
