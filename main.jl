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

function renderPixel(i::Int, j::Int, w::Int, h::Int, numsamples::Int)
	c = Float64[0,0,0] 
	for s in 1:numsamples
		c += Rays.color(shoot(WORLD.cameras[1], (i-1 + rand()) / w, (j-1 + rand()) / h), 0)
	end
	c
end

function render(w::Int, h::Int, numsamples::Int)
	refs = Vector{RemoteRef}(numsamples)
	samples = Vector{Vector{Float64}}(numsamples)
	
	for j in h:-1:1
		println("Row $j")
		row = Vector{Vec3}(w)
		for i in 1:w
			pixel = renderPixel(i, j, w, h, numsamples)
			row[i] =  Vec3(pixel[1] / numsamples, pixel[2] / numsamples, pixel[3] / numsamples)
		end
		produce(row)
	end
end

function writepgm(pipeline, w, h, filename)
	f(v::Float64) = floor(Int,255.99*sqrt(v))
	pgm = open("$filename.pgm", "w")
	write(pgm, "P3\n$w $h 255\n")
	for j in 1:h
		row = consume(pipeline)
		for i in 1:w
			write(pgm, "$(f(row[i].x)) $(f(row[i].y)) $(f(row[i].z)) ")
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
	w, h = 3*400, 2*400
	writepgm(Task(()->@time render(w, h, SAMPLES)), w, h, "Weekend1")
end

function profiled()
	w, h = 3*100, 2*100
	writepgm(Task(()->@profile render(w, h, 3)), w, h, "Profiled1")
	Profile.print()
end

function small()
	w, h = 3*50, 2*50
	writepgm(Task(()->@time render(w, h, 1)), w, h, "Small1")
end	

noprofile()

