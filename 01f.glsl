varying vec2 pos;
uniform float u_aspect_ratio;
uniform float u_time;

vec3 rand(vec3 co) {
    float x = 2920.0 * sin(co.x * 21942.0 + co.y * 171324.0 + co.z * 2443.0 + 8912.0) * cos(co.x * 23157.0 * co.y * 217832.0 * co.z + 9758.0);
    float alpha = acos(mod(x, 2.0) - 1.0);
    float beta  = 2132.0 * sin(co.x * 10233.0 + co.y * 103222.0 + co.z * 3243.0 + 2222.0) * cos(co.x * 38322.0 * co.y * 271828.0 * co.z + 1111.0);
    return vec3(sin(alpha) * cos(beta), sin(alpha) * sin(beta), cos(alpha));
}

float dot_grid_gradient(vec3 floor_p, vec3 p) {
	vec3 gradient = rand(floor_p);
	vec3 dist = p - floor_p;
	return dot(dist, gradient);
}

void main() {
	vec3 p = vec3(pos * 5.0, sin(u_time) * 0.6 + u_time * 2.0);
	p.x *= u_aspect_ratio;
	
	vec3 p0 = floor(p);
	vec3 p1 = p0 + vec3(1.0, 1.0, 1.0);
	vec3 weight = p - p0;
	weight = smoothstep(0.0, 1.0, weight);
	
	float n0, n1, ix0, ix1, iy0, iy1;
	
	n0 = dot_grid_gradient(vec3(p0.x, p0.y, p0.z), p);
	n1 = dot_grid_gradient(vec3(p1.x, p0.y, p0.z), p);
	ix0 = mix(n0, n1, weight.x);
		
	n0 = dot_grid_gradient(vec3(p0.x, p1.y, p0.z), p);
	n1 = dot_grid_gradient(vec3(p1.x, p1.y, p0.z), p);
	ix1 = mix(n0, n1, weight.x);
	
	iy0 = mix(ix0, ix1, weight.y);
	
	n0 = dot_grid_gradient(vec3(p0.x, p0.y, p1.z), p);
	n1 = dot_grid_gradient(vec3(p1.x, p0.y, p1.z), p);
	ix0 = mix(n0, n1, weight.x);
	
	n0 = dot_grid_gradient(vec3(p0.x, p1.y, p1.z), p);
	n1 = dot_grid_gradient(vec3(p1.x, p1.y, p1.z), p);
	ix1 = mix(n0, n1, weight.x);
	
	iy1 = mix(ix0, ix1, weight.y);
	
	
	float v = mix(iy0, iy1, weight.z);
	v += 1.0;
	v *= 0.5;
	vec3 color = mix(vec3(0.4, 0.2, 1.0), vec3(1.0, 0.4, 0.4), v);
	gl_FragColor = vec4(color, 1.0);
}
