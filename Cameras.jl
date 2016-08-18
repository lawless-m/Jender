module Cameras


using Vecs: Vec3, unitVector
using Rays: Ray

function rand_in_unit_disk()
	p = 2Vec3(rand(), rand(), 0) - Vec3(1, 1, 0)
	
	while (dot(p, p) >= 1.0)
		p = 2Vec3(rand(), rand(), 0) - Vec3(1, 1, 0)
	end
	p
end

type Camera
	origin::Vec3
	lower_left::Vec3
	horizontal::Vec3
	vertical::Vec3
	u::Vec3
	v::Vec3
	w::Vec3
	lens_radius::Float64
	
	
	function Camera(lookfrom::Vec3, lookat::Vec3, vup::Vec3, vfov::Float64, aspect::Float64, aperture::Float64, focus_dist::Float64)
		theta = vfov * pi / 180
		half_h = tan(theta/2)
		half_w = aspect * half_h
		w = unitVector(lookfrom - lookat)
		u = unitVector(cross(vup, w))
		v = cross(w, u)
		new(  lookfrom
			, lookfrom - half_w * focus_dist * u - half_h * focus_dist * v - focus_dist *w
			, 2half_w * focus_dist * u
			, 2half_h * focus_dist * v 
			, u, v, w
			, aperture/2
			)
	end
end

function shoot(c::Camera, s::Float64, t::Float64)
		rd = c.lens_radius * rand_in_unit_disk()
		offset = c.u * rd.x + c.v * rd.y
		Ray(c.origin + offset, c.lower_left + s * c.horizontal + t * c.vertical - c.origin - offset)
end


	
end
