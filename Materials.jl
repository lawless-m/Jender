module Materials

using Vecs: Vec3, unitVector, Vec3rand, squaredLength

using Rays: Ray

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

immutable Lambertian <: Material
	albedo::Vec3
	Lambertian(r, g, b) = new(Vec3(r, g, b))
end


function scatter(m::Lambertian, ray::Ray, hit)
	target = hit.p + hit.normal + random_in_unit_sphere()
	true, Ray(hit.p, target - hit.p), m.albedo
end

immutable Metal <: Material
	albedo::Vec3
	fuzz::Float64
	Metal(r, g, b, f) = new(Vec3(r, g, b), f)
end

function scatter(m::Metal, ray::Ray, hit)
	reflection = reflect(unitVector(ray.direction), hit.normal)
	scatter = Ray(hit.p, reflection + m.fuzz * random_in_unit_sphere())
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
	true, Ray(hit.p, rand() < reflect_prob ? reflection : refraction), Vec3(1.0, 1.0, 1.0)
end

end

