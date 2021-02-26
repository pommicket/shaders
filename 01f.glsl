varying vec2 pos;
uniform float u_aspect_ratio;

vec2 rand(vec2 co) {
    float random = 2920.0 * sin(co.x * 21942.0 + co.y * 171324.0 + 8912.0) * cos(co.x * 23157.0 * co.y * 217832.0 + 9758.0);
    return vec2(cos(random), sin(random));
}

float dot_grid_gradient(vec2 floor_p, vec2 p) {
	vec2 gradient = rand(floor_p);
	vec2 dist = p - floor_p;
	return dot(dist, gradient);
}

void main() {
	vec2 p = pos * 10.0;
	p.x *= u_aspect_ratio;
	vec2 p0 = floor(p);
	vec2 p1 = p0 + vec2(1.0, 1.0);
	vec2 weight = p - p0;
	weight = smoothstep(0.0, 1.0, weight);
	
	float n0 = dot_grid_gradient(vec2(p0.x, p0.y), p);
	float n1 = dot_grid_gradient(vec2(p1.x, p0.y), p);
	float ix0 = mix(n0, n1, weight.x);
		
	n0 = dot_grid_gradient(vec2(p0.x, p1.y), p);
	n1 = dot_grid_gradient(vec2(p1.x, p1.y), p);
	float ix1 = mix(n0, n1, weight.x);
	
	float v = mix(ix0, ix1, weight.y);
	v += 1.0;
	v *= 0.5;
	vec3 color = mix(vec3(0.4, 0.2, 1.0), vec3(1.0, 0.6, 0.6), v);
	gl_FragColor = vec4(color, 1.0);
}
