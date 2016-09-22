
cd(ENV["USERPROFILE"] * "/Documents")
unshift!(LOAD_PATH, "GitHub/Jender/")

#=
TheNextWeek https://github.com/petershirley/raytracingthenextweek/
=#

using Vecs
using Entities
using Materials
using Rays
using Cameras
using Textures

function pixelProducer(i::Int, j::Int, w::Int, h::Int, numsamples::Int)
	c = RGB()
	for s in 1:numsamples
		c += rayColor(shootRay(WORLD.cameras[1], (i-1 + rand()) / w, (j-1 + rand()) / h), 0)
	end
	produce(c / numsamples)
end

function render(w::Int, h::Int, numsamples::Int)
	for j in h:-1:1, i in 1:w
		pixelProducer(i, j, w, h, numsamples)
	end
end

function walkPixels(w::Int, h::Int)
	for j in h:-1:1, i in 1:w
		rayColor(shootRay(WORLD.cameras[1], (i-1 + rand()) / w, (j-1 + rand()) / h), 0)
	end
end

function writepgm(pipeline, w, h, filename)
	pgm = open(filename * ".pgm", "w")
	@printf pgm "P3\n%d %d 255\n" w h
	for j in 1:h
		println("Row $(h-j)")
		for i in 1:w
			write(string(consume(pipeline)))
		end
		@printf pgm "\n"
	end
	close(pgm)
end

srand(0)
const SAMPLES = 10
const ASPECTW = 3
const ASPECTH = 2
		
function simple_light()
	println("Simple Light")
	pushEntity!(Sphere(0,-1000,0, 1000, Lambertian(Noise(4))))
	pushEntity!(Sphere(0,2,0, 2, Lambertian(Noise(4))))
	pushEntity!(Sphere(0,7,0, 2, Diffuse(Constant(4))))
	pushEntity!(XY_Rect(3,5,1,3, -2, Diffuse(Constant(4))))
end

function random_spheres()
	println("Random Spheres")
	pushEntity!(Sphere(0,-1000,0, 1000, Lambertian(0.5, 0.5, 0.5)))
	pushEntity!(Sphere(0,1,0, 1.0, Dielectric(1.5)))
	pushEntity!(Sphere(-4,1,0, 1.0, Lambertian(0.4, 0.2, 0.1)))
	pushEntity!(Sphere(4,1,0, 1.0, Metal(0.7, 0.6, 0.5, 0.0)))
	
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

function two_perlin_spheres()
	println("2 Perlin Spheres")
	pushEntity!(Sphere(0,-1000,0, 1000, Lambertian(Noise(4))))
	pushEntity!(Sphere(0,2,0, 2, Lambertian(Noise(4))))
end

function cornell_box()
	red = Lambertian(Constant(0.65, 0.05, 0.05))
	white = Lambertian(Constant(0.73))
	green = Lambertian(Constant(0.12, 0.45, 0.15))
	light = Diffuse(Constant(15))

	pushEntity!(FlippedNormal(YZ_Rect(0, 555, 0, 555, 555, green)))
	pushEntity!(YZ_Rect(0, 555, 0, 555, 555, red))
	pushEntity!(XZ_Rect(213, 343, 227, 332, 554, light))
	pushEntity!(FlippedNormal(XZ_Rect(0, 555, 0, 555, 555, white)))
	pushEntity!(XZ_Rect(0, 555, 0, 555, 555, white))
	pushEntity!(FlippedNormal(XY_Rect(0, 555, 0, 555, 555, white)))
	pushEntity!(Translated(yRotated(Box(Vec3(0), Vec3(165), white), -18.0), Vec3(130,0,65)))
	pushEntity!(Translated(yRotated(Box(Vec3(0), Vec3(165,330,165), white), 15.0), Vec3(265,0,295)))
end
	
pushCamera!(Camera(Vec3(13,2,3), Vec3(0,0,0), Vec3(0,1,0), 20.0, 3/2, 0.1, 10.0, 0.0, 1.0))

cornell_box()

function best()
	w, h = 400ASPECTW, 400ASPECTH # like this so the aspect ratio is obvious
	writepgm(Task(()->@time render(w, h, SAMPLES)), w, h, "Weekend1")
end

function profiled()
	w, h = 100ASPECTW, 100ASPECTH
	writepgm(Task(()->@profile render(w, h, 3)), w, h, "Profiled1")
	Profile.print()
end

function small()
	w, h = 50ASPECTW, 50ASPECTH
	writepgm(Task(()->@time render(w, h, 1)), w, h, "Small1")
end	

function walk()
	w, h = 50ASPECTW, 50ASPECTH
	walkPixels(w, h)
end	

small()



