#if _WIN32
#include <SDL.h>
#else
#include <SDL2/SDL.h>
#endif
#include "base.h"
#include "math.c"
#include "arr.c"
#include "gl.c"
#include "time.c"
#include "util.c"
#if _WIN32
#include "filesystem-win.c"
#else
#include "filesystem-posix.c"
#endif

typedef struct {
	GLuint program;
	GLuint vbo, vao;
	struct timespec last_modified;
	char vfilename[64], ffilename[64];
} Shader;

// pass NULL for filenames to reload the shader.
static void shader_load(Shader *shader, char const *vfilename, char const *ffilename) {
	if (vfilename)
		strbuf_cpy(shader->vfilename, vfilename);
	if (ffilename)
		strbuf_cpy(shader->ffilename, ffilename);
			
	shader->last_modified = timespec_max(time_last_modified(shader->vfilename), time_last_modified(shader->ffilename));
	FILE *vfp = fopen(shader->vfilename, "rb");
	FILE *ffp = fopen(shader->ffilename, "rb");
	
	if (vfp) {
		if (ffp) {
			fseek(vfp, 0, SEEK_END);
			size_t vsize = (size_t)ftell(vfp);
			fseek(vfp, 0, SEEK_SET);
			
			fseek(ffp, 0, SEEK_END);
			size_t fsize = (size_t)ftell(ffp);
			fseek(ffp, 0, SEEK_SET);
			
			char *vcode = calloc(vsize + 1, 1);
			char *fcode = calloc(fsize + 1, 1);
			if (vcode && fcode) {
				fread(vcode, 1, vsize, vfp);
				fread(fcode, 1, fsize, ffp);
				
				
				GLuint program = gl_compile_and_link_shaders(vcode, fcode);
				if (program) {
					shader->program = program;
					if (shader->vbo) glDeleteBuffers(1, &shader->vbo);
					if (shader->vao) glDeleteVertexArrays(1, &shader->vao);
					GLuint vbo = 0;
					glGenBuffers(1, &vbo);
					GLuint vao = 0;
					if (gl_version_major >= 3)
						glGenVertexArrays(1, &vao);
					
					shader->vbo = vbo;
					shader->vao = vao;
				}
			} else print("Out of memory.\n");
			free(vcode); free(fcode);
		} else {
			print("Error loading shader: fragment shader file %s does not exist.\n", ffilename);
		}
	} else {
		print("Error loading shader: vertex shader file %s does not exist.\n", vfilename);
	}
	
	if (vfp) fclose(vfp);
	if (ffp) fclose(ffp);	
}

static void shader_check_for_changes(Shader *shader) {
	if (!timespec_eq(shader->last_modified, 
		timespec_max(time_last_modified(shader->vfilename), time_last_modified(shader->ffilename)))) {
		GLuint prev_program = shader->program;
		shader_load(shader, NULL, NULL);
		if (shader->program != prev_program)
			glDeleteProgram(prev_program);
	}
}

static double start_time;
static float window_width, window_height;

static void shader_draw(Shader *shader, Rect where) {
	shader_check_for_changes(shader);
	if (!shader->program) return;
	float x1, y1, x2, y2;
	rect_coords(where, &x1, &y1, &x2, &y2);
	
	if (shader->vao)
		glBindVertexArray(shader->vao);
	glBindBuffer(GL_ARRAY_BUFFER, shader->vbo);
	v2 buffer_data[] = {
		// gl coordinates (v_render_pos)
		{x1, y1},
		{x2, y1},
		{x1, y2},
		
		{x2, y1},
		{x2, y2},
		{x1, y2},
		
		// normalized coordinates (v_pos)
		{0, 0},
		{1, 0},
		{0, 1},
		
		{1, 0},
		{1, 1},
		{0, 1},
	};
	
	glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)sizeof buffer_data, buffer_data, GL_STATIC_DRAW);
	GLuint v_render_pos = gl_attrib_loc(shader->program, "v_render_pos");
	GLuint v_pos = gl_attrib_loc(shader->program, "v_pos");
	if (v_render_pos != (GLuint)-1) {
		glVertexAttribPointer(v_render_pos,	2, GL_FLOAT, 0, sizeof(v2), NULL);
		glEnableVertexAttribArray(v_render_pos);
	}
	if (v_pos != (GLuint)-1) {
		glVertexAttribPointer(v_pos, 2, GL_FLOAT, 0, sizeof(v2), (void *)(6 * sizeof(v2)));
		glEnableVertexAttribArray(v_pos);
	}
	glUseProgram(shader->program);
	GLint u_time = gl_uniform_loc(shader->program, "u_time");
	if (u_time >= 0)
		glUniform1f(u_time, (float)fmod(time_get_seconds() - start_time, 10000));
	GLint u_aspect_ratio = gl_uniform_loc(shader->program, "u_aspect_ratio");
	if (u_aspect_ratio >= 0)
		glUniform1f(u_aspect_ratio, window_width / window_height);
	glDrawArrays(GL_TRIANGLES, 0, 6);	
}

static void die(char const *fmt, ...) {
	char buf[256] = {0};
	
	va_list args;
	va_start(args, fmt);
	vsnprintf(buf, sizeof buf - 1, fmt, args);
	va_end(args);

	// show a message box, and if that fails, print it
	if (SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "Error", buf, NULL) < 0) {
		print("%s\n", buf);
	}

	exit(EXIT_FAILURE);
}

#if DEBUG
static void APIENTRY gl_message_callback(GLenum source, GLenum type, unsigned int id, GLenum severity, 
	GLsizei length, const char *message, const void *userParam) {
	(void)source; (void)type; (void)id; (void)length; (void)userParam;
	if (severity == GL_DEBUG_SEVERITY_NOTIFICATION) return;
	debug_println("Message from OpenGL: %s.", message);
}
#endif

int main(void) {
	if (SDL_Init(SDL_INIT_VIDEO) < 0)
		die("%s", SDL_GetError());
	
	SDL_Window *window = SDL_CreateWindow("shaders", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
		1280, 720, SDL_WINDOW_SHOWN|SDL_WINDOW_OPENGL|SDL_WINDOW_RESIZABLE);
	if (!window)
		die("%s", SDL_GetError());
	
	gl_version_major = 4;
	gl_version_minor = 3;
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, gl_version_major);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, gl_version_minor);
#if DEBUG
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_DEBUG_FLAG);
#endif
	SDL_GLContext *glctx = SDL_GL_CreateContext(window);
	if (!glctx) {
		debug_println("Couldn't get GL 4.3 context. Falling back to 2.0.");
		gl_version_major = 2;
		gl_version_minor = 0;
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, gl_version_major);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, gl_version_minor);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
		glctx = SDL_GL_CreateContext(window);
		if (!glctx)
			die("%s", SDL_GetError());
	}
	gl_get_procs();

#if DEBUG
	if (gl_version_major * 100 + gl_version_minor >= 403) {
		GLint flags = 0;
		glGetIntegerv(GL_CONTEXT_FLAGS, &flags);
		glEnable(GL_DEBUG_OUTPUT);
		glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
		if (flags & GL_CONTEXT_FLAG_DEBUG_BIT) {
			// set up debug message callback
			glDebugMessageCallback(gl_message_callback, NULL);
			glDebugMessageControl(GL_DONT_CARE, GL_DONT_CARE, GL_DONT_CARE, 0, NULL, GL_TRUE);
		}
	}
#endif
	
	gl_geometry_init();
	
	SDL_GL_SetSwapInterval(1); // vsync
	
	Shader *shaders = NULL;
	
	char **files = fs_list_directory(".");
	size_t nfiles; for (nfiles = 0; files[nfiles]; ++nfiles);
	qsort(files, nfiles, sizeof *files, str_qsort_case_insensitive_cmp);
	
	u16 nshaders = 0;
	for (size_t i = 0; i < nfiles; ++i) {
		nshaders += str_is_suffix(files[i], "v.glsl");
	}
	
	u16 shader_idx = 0;
	for (size_t i = 0; i < nfiles; ++i) {
		if (str_is_suffix(files[i], "v.glsl")) {
			char const *vfilename = files[i];
			char ffilename[64];
			strbuf_cpy(ffilename, vfilename);
			ffilename[strlen(ffilename) - 6] = 'f';
			Shader shader = {0};
			shader_load(&shader, vfilename, ffilename);
			arr_add(shaders, shader);
			++shader_idx;
		}
		free(files[i]);
	}
	
	i32 viewing_shader = -1;
	
	free(files);
	
	bool quit = false, fullscreen = false;
	start_time = time_get_seconds();
	while (!quit) {
	int iwindow_width, iwindow_height;
		SDL_GetWindowSize(window, &iwindow_width, &iwindow_height);
		window_width = (float)iwindow_width;
		window_height = (float)iwindow_height;
		
		SDL_Event event = {0};
		v2 *mouse_clicks = NULL;
		while (SDL_PollEvent(&event)) {
			switch (event.type) {
			case SDL_QUIT:
				quit = true;
				break;
			case SDL_MOUSEBUTTONDOWN: {
				float x = -1 + 2 * (float)event.button.x / window_width;
				float y = +1 - 2 * (float)event.button.y / window_height;
				arr_add(mouse_clicks, V2(x, y));
			} break;
			case SDL_KEYDOWN:
				switch (event.key.keysym.sym) {
				case SDLK_ESCAPE:
					if (viewing_shader == -1)
						quit = true;
					else
						viewing_shader = -1;
					break;
				case SDLK_F11:
					fullscreen = !fullscreen;
					SDL_SetWindowFullscreen(window, fullscreen ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
					break;
				}
				break;
			}
		}
		
		
		// set up GL
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glViewport(0, 0, (GLsizei)window_width, (GLsizei)window_height);
		glClearColor(0, 0, 0, 1);
		glClear(GL_COLOR_BUFFER_BIT);
		
		if (viewing_shader >= 0) {
			// one shader
			Shader *shader = &shaders[viewing_shader];
			shader_draw(shader, rect4(-1, -1, +1, +1));
		} else {
			// shader gallery
			u16 idx = 0;
			float w = 2 * 1.0f / 6;
			float h = 2 * 1.0f / ((nshaders + 5) / 6);
			h = minf(h, 1.0f / 3);
			arr_foreach_ptr(shaders, Shader, shader) {
				float x1 = -1 + (idx % 6) * w;
				float y1 = 1 - h - (idx / 6) * h;
				Rect r = rect(V2(x1, y1), V2(w, h));
				r = rect_shrink(r, 0.02f);
				arr_foreach_ptr(mouse_clicks, v2, click) {
					if (rect_contains_point(r, *click))
						viewing_shader = idx;
				}
				shader_draw(shader, r);
				++idx;
			}
		}
		
		
		arr_clear(mouse_clicks);
		SDL_GL_SwapWindow(window);
	}
	
	
	return 0;
}
