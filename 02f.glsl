varying vec2 pos;
uniform float u_aspect_ratio;
uniform float u_time;

#define PI 3.14159265

vec3 rand(vec4 co) {
    float x = 2920.0 * sin(co.x * 21942.0 + co.y * 171324.0 + co.z * 2443.0 + co.w * 34891.0 + 8912.0) * cos(co.x * 23157.0 * co.y * 217832.0 * co.z * co.w + 9758.0);
    float alpha = acos(mod(x, 2.0) - 1.0);
    float beta  = 2132.0 * sin(co.x * 10233.0 + co.y * 103222.0 + co.z * 3243.0 + co.w * 15932.0 + 2222.0) * cos(co.x * 38322.0 * co.y * 271828.0 * co.z * co.w + 1111.0);
    return vec3(sin(alpha) * cos(beta), sin(alpha) * sin(beta), cos(alpha));
}

float dot_grid_gradient(vec3 floor_p, vec3 p, float i) {
	vec3 gradient = rand(vec4(floor_p, i));
	vec3 dist = p - floor_p;
	return dot(dist, gradient);
}

vec3 smooth(vec3 x) {
	vec3 v = 0.5 + 0.5 * sin(PI * (x - 0.5));
	return v;
	//return smoothstep(0.0, 1.0, x);
}

float perlin_noise(vec3 p, float i) {
	vec3 p0 = floor(p);
	vec3 p1 = p0 + vec3(1.0, 1.0, 1.0);
	vec3 weight = p - p0;
	weight = smooth(weight);
	
	float n0, n1, ix0, ix1, iy0, iy1;
	
	n0 = dot_grid_gradient(vec3(p0.x, p0.y, p0.z), p, i);
	n1 = dot_grid_gradient(vec3(p1.x, p0.y, p0.z), p, i);
	ix0 = mix(n0, n1, weight.x);
		
	n0 = dot_grid_gradient(vec3(p0.x, p1.y, p0.z), p, i);
	n1 = dot_grid_gradient(vec3(p1.x, p1.y, p0.z), p, i);
	ix1 = mix(n0, n1, weight.x);
	
	iy0 = mix(ix0, ix1, weight.y);
	
	n0 = dot_grid_gradient(vec3(p0.x, p0.y, p1.z), p, i);
	n1 = dot_grid_gradient(vec3(p1.x, p0.y, p1.z), p, i);
	ix0 = mix(n0, n1, weight.x);
	
	n0 = dot_grid_gradient(vec3(p0.x, p1.y, p1.z), p, i);
	n1 = dot_grid_gradient(vec3(p1.x, p1.y, p1.z), p, i);
	ix1 = mix(n0, n1, weight.x);
	
	iy1 = mix(ix0, ix1, weight.y);
	
	
	float v = mix(iy0, iy1, weight.z);
	v += 1.0;
	v *= 0.5;
	return v;
}

float channel(float v, float i, float space) {
	float thickness = 0.02;
	float edge1 = 0.2 + space * i;
	float edge2 = edge1 + thickness;
	float mid = 0.5 * (edge1 + edge2);
	if (v >= edge1 && v <= mid)
		return smoothstep(edge1, mid, v);
	else if (v >= mid && v <= edge2)
		return smoothstep(edge2, mid, v);
	else
		return 0.0;
}

void main() {
	vec3 p = vec3(pos * 5.0, u_time * 0.5);
	p.x *= u_aspect_ratio;
	float v = perlin_noise(p, 0.0);
	v *= v;
	float space = cos(0.7 * u_time);
	space *= space * space * 0.05;
	float c1 = channel(v, 0.0, space);
	float c2 = channel(v, 1.0, space);
	float c3 = channel(v, 2.0, space);
	float c4 = channel(v, 3.0, space);
	float t = 0.5 + 0.5 * sin(1.21 * u_time);
	vec3 color = clamp(
	             c1 * vec3(t, 0.0, 0.5)
	           + c2 * vec3(0.0, t, 0.5)
	           + c3 * vec3(0.3, 0.0, t)
	           + c4 * vec3(t, 0.5, 0.0), 0.0, 1.0);
	gl_FragColor = vec4(color, 1.0);
}
