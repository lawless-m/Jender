module Materials

using Vecs
using Rays
using Textures

export scatter, reflect, refract, emit, Material, Diffuse, Lambertian, Metal, Dielectric, Isotropic, Diffuse

function schlick(cosine::Float64, ref_idx::Float64)
	r0 = ((1 - ref_idx) / (1 + ref_idx))^2
	r0 + (1-r0) * (1-cosine)^5
end

function refract(v::Vec3, n::Vec3, ni_over_nt::Float64)
	uv = unitVector(v)
	dt = dot(uv, n)
	discriminant = 1.0 - ni_over_nt^2 * (1-dt^2)
	if discriminant > 0
		ni_over_nt * (uv - n * dt) - n * sqrt(discriminant)
	end
end

function reflect(v::Vec3, n::Vec3)
	v - 2dot(v,n)*n
end

function random_in_unit_sphere()
	p = 2*Vec3rand() - Vec3(1,1,1)
	while squaredLength(p) >= 1.0
		p = 2*Vec3rand() - Vec3(1,1,1)
	end
	p
end

abstract Material

immutable Null <: Material
end

function emit(m::Material, u::Float64, v::Float64, p::Vec3)
	return RGB(0)
end

function scatter(m::Material, ray::Ray, hit)
	false, Ray(), []
end

immutable Lambertian <: Material
	albedo::Texture
	Lambertian(a) = new(a)
	Lambertian(r,g,b) = new(Constant(r,g,b))
end

function scatter(m::Lambertian, ray::Ray, hit)
	target = hit.p + hit.normal + random_in_unit_sphere()
	true, Ray(hit.p, target - hit.p, ray.time), value(m.albedo, hit.p, hit.u, hit.v)
end

immutable Metal <: Material
	albedo::RGB
	fuzz::Float64
	Metal(rgb, f) = new(rgb, f<1 ? f : 1)
	Metal(r, g, b, f) = new(RGB(r, g, b), f)
end

function scatter(m::Metal, ray::Ray, hit)
	reflection = reflect(unitVector(ray.direction), hit.normal)
	scatter = Ray(hit.p, reflection + m.fuzz * random_in_unit_sphere(), ray.time)
	dot(scatter.direction, hit.normal) > 0, scatter, m.albedo
end

immutable Dielectric <: Material
	ref_idx::Float64
end

function scatter(m::Dielectric, ray::Ray, hit)
	outward_normal = Vec3()
	ni_over_nt = 0.0
	cosine = 0.0
	reflection = reflect(ray.direction, hit.normal)
	
	if dot(ray.direction, hit.normal) > 0
		outward_normal = -hit.normal
		ni_over_nt = m.ref_idx
		# the abs wasn't in the original code. I suspect a hidden bug
		cosine = sqrt(abs((1 - m.ref_idx^2 * (1 - (dot(ray.direction, hit.normal) / length(ray.direction))^2))))	
		
	else
		outward_normal = hit.normal
		ni_over_nt = 1.0 / m.ref_idx
		cosine = -dot(ray.direction, hit.normal) / length(ray.direction)
	end
	
	refraction = refract(ray.direction, outward_normal, ni_over_nt)
	reflect_prob = refraction == nothing ? 1.0 : schlick(cosine, m.ref_idx)
	true, Ray(hit.p, rand() < reflect_prob ? reflection : refraction, ray.time), RGB(1)
end

immutable Diffuse <: Material
	texture::Texture
	Diffuse(t) = new(t)
end

function emit(d::Diffuse, u::Float64, v::Float64, p::Vec3)
	value(d.texture, p, u, v)
end

immutable Isotropic <: Material
	albedo::Texture
	Isotropic(a) = new(a)
end

function scatter(i::Isotropic, ray::Ray, hit)
	true, Ray(hit.p, random_in_unit_sphere()), value(i.albedo, hit.u, hit.v, hit.p)
end

end
