attribute vec2 v_render_pos;
attribute vec2 v_pos;

varying vec2 pos;

void main() {
	gl_Position = vec4(v_render_pos, 0.0, 1.0);
	pos = v_pos;
}
