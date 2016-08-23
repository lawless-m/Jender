
using Vecs: Vec3
using Rays: Ray

immutable Aabb
	min::Vec3
	max::Vec3
end

function mn_mx(mn, mx, r) = 
	min((mn - r) / r, (mx - r)/r), max((mn - r) / r, (mx - r)/r)
end

function hit(aabb::Aabb, ray::Ray, tmin::Float64, tmax::Float64)
	mn, mx = mn_mx(aabb.mn.x, ray.origin.x)
	if max(mx, tmax) <= min(mn, tmin) 
		return false
	end
	mn, mx = mn_mx(aabb.mn.y, ray.origin.y)
	if max(mx, tmax) <= min(mn, tmin) 
		return false
	end
	mn, mx = mn_mx(aabb.mn.z, ray.origin.z)
	if max(mx, tmax) <= min(mn, tmin) 
		return false
	end
	return true
end

function surrounding_box(b0::Aabb, b1::Aabb)
	Aabb(Vec3(min(b0.min.x, b1.min.x), min(b0.min.y, b1.min.y), min(b0.min.z, b1.min.z)), Vec3(max(b0.max.x, b1.max.x), max(b0.max.y, b1.max.y), max(b0.max.z, b1.max.z))
end
