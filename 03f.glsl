varying vec2 pos;
uniform float u_aspect_ratio;
uniform float u_time;


#define PI 3.14159265
#define TAU 6.28318530718

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898,78.233))) * 43758.5453);
}

// see https://en.wikipedia.org/wiki/HSL_and_HSV#HSV_to_RGB_alternative
float hsvf(float n, vec3 hsv) {
	float k = mod(n + hsv.x * 6.0, 6.0);
	return hsv.z - hsv.z * hsv.y * clamp(min(k, 4.0 - k), 0.0, 1.0);
}

vec3 hsv_to_rgb(vec3 hsv) {
	return vec3(hsvf(5.0, hsv), hsvf(3.0, hsv), hsvf(1.0, hsv));
}


// see https://en.wikipedia.org/wiki/Error_function#Inverse_functions
float inv_erf(float z) {
	return 0.5 * sqrt(PI) * z *
		(1.0 + z * z *
		(0.2617993878 + z * z *
		(0.1439317308 + z * z *
		(0.0976636195 + z * z *
		(0.0732990794 + z * z *
		(0.0583725009))))));
}

float distance2(vec2 a, vec2 b) {
	return dot(a-b, a-b);
}

// inverse of the normal cumulative density function
// see https://en.wikipedia.org/wiki/Normal_distribution#Quantile_function
float inv_norm(float p, float mu, float sigma) {
	return mu + sigma * sqrt(2.0) * inv_erf(2.0 * p - 1.0);
}

void main() {
	vec3 p = vec3(pos, u_time);
	p.x *= u_aspect_ratio;
	float z = p.z;
	
	float t = 0.0;
	for (float i = 0.0; i < 10.0; i += 1.0) {
		float r = rand(vec2(i + 1.0, i + 1.0));
		vec2 loc = vec2(
			sin(1.0 * z * r),
			tan(1.0 * z * r)
		);
		loc *= 0.5;
		loc += 0.5;
		loc.x *= u_aspect_ratio;
	
		float term = 1.0 - distance(p.xy, loc);
		term = clamp(term, 0.0, 1.0);
		t = max(t, term);
	}
	
	
	float n = 2.0 + 2.0 * (0.5 + 0.5 * sin(z));
	t = fract(t*n);
	t *= pow(sin(t * 40.0), 6.0 * pow(0.5 + 0.5 * sin(z), 3.0));
	
	float v = t < 0.5 ? 0.0 : 1.0;
	
	
	float h = max(t - 0.5, 0.0) * 2.0;
	
	
	h *= 0.2;
	h += 0.7;
	
	float s = 1.0;
	vec3 hsv = vec3(h, s, v);
	gl_FragColor = vec4(hsv_to_rgb(hsv), 1.0);
	
}
