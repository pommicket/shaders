varying vec2 pos;
uniform float u_time;

void main() {
	float t = mod(u_time, 2.0*3.1415926536);
	gl_FragColor = vec4(pos.x, 0.5+0.5*sin(5.0*t), pos.y, 1.0);
}
