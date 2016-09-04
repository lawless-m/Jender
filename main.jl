#=
C++ version hosted at http://goo.gl/9yItEO http://goo.gl/sBih70

=#

addprocs(4)
unshift!(LOAD_PATH, ".")
using Vecs: zero, Vec3, unitVector
using Entities: WORLD, World, pushEntity!, pushCamera!, Entity, Sphere, hitWorld, hitEntity!
using Materials: Material, Lambertian, Metal, Dielectric
using Rays: Ray, pointAt
using Cameras: Camera, shoot

function renderPixel(i, j, w, h, numsamples)
	c = Float64[0,0,0] 
	for s in 1:numsamples
		c += Rays.color(shoot(WORLD.cameras[1], (i-1 + rand()) / w, (j-1 + rand()) / h), 0)
	end
	c
end

function render(cols::Matrix{Vec3}, numsamples::Int)
	refs = Vector{RemoteRef}(numsamples)
	samples = Vector{Vector{Float64}}(numsamples)
	
	for i in 1:size(cols)[2]
		println("Column $(size(cols)[2]-i)")
			
		for j in 1:size(cols)[1] 
			pixel = renderPixel(i, j, size(cols)[2], size(cols)[1], numsamples)
			cols[j,i] =  Vec3(pixel[1] / numsamples, pixel[2] / numsamples, pixel[3] / numsamples)
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
		
pushEntity!(Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5)))
pushEntity!(Sphere(0, 1, 0, 1.0, Dielectric(1.5)))
pushEntity!(Sphere(-4, 1, 0, 1.0, Lambertian(0.4, 0.2, 0.1)))
pushEntity!(Sphere(4, 1, 0, 1.0, Metal(0.7, 0.6, 0.5, 0.0)))
pushCamera!(Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20.0, 3/2, 0.1, 10.0))

println("Build world")
Entities.push_random_entities!()

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
	@time Rays.color(shoot(WORLD.cameras[1], 50.5/size(cols)[2], 60.5/size(cols)[1]), 0)
	#println(c) #   Vecs.RGB(0.1087251386964388,0.0434686890557862,0.18448252480043215)
	#quit()
	@time render(cols, 3)
	#@time render(cols, 3)
	# 42.015203 seconds (1.88 G allocations: 70.071 GB, 8.08% gc time)
	writepgm(cols, "Profiled")
end	

timed()
