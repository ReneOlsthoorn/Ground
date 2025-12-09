
#template sdl3

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll
#library glm libcglm-0.dll


u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int screenpitch = SCREEN_LINESIZE;
f32[4] ballSrcRectVoetbal = [0,0,32,32];
f32[4] ballSrcRectTennisbal = [0,32,32,32];
f32[4] ballSrcRectKogel = [0,64,32,32];
f32[4] ballDestRect = [0,0,32,32];
//ptr ballSrc = &ballSrcRectVoetbal;
ptr ballSrc = &ballSrcRectKogel;


ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, 0x80); //HIGH_PRIORITY_CLASS
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("3D", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_SetRenderVSync(renderer, 1);


ptr ballSurface = sdl3_image.IMG_Load("image/3balls_32.png");
if (ballSurface == null) return;
ptr ballTexture = sdl3.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) return;
sdl3.SDL_SetTextureScaleMode(ballTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(ballSurface);



function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 2.0, 2.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

// Following 2 functions are also in utils.g
function DegreeToRadians(float angle_deg) : float {
	return angle_deg * MATH_PI / 180.0;
}
function ValidRadian_f32(f32 radian) : f32 {
	f32 valid = radian;
	while (valid >= MATH_2PI)
		valid = valid - MATH_2PI;
	f32 floorValue = 0.0;
	while (valid < floorValue)
		valid = valid + MATH_2PI;
	return valid;
}

#define CUBE_SIZE 24

f32[] cube = [ -0.5,-0.5,-0.5,1.0,  0.5,-0.5,-0.5,1.0,
			    0.5, 0.5,-0.5,1.0,  -0.5,0.5,-0.5,1.0,
               -0.5,-0.5, 0.5,1.0,  0.5,-0.5, 0.5,1.0,
                0.5, 0.5, 0.5,1.0, -0.5, 0.5, 0.5,1.0,

			   -0.4,-0.4,-0.4,1.0,  0.4,-0.4,-0.4,1.0,
			    0.4, 0.4,-0.4,1.0, -0.4, 0.4,-0.4,1.0,
               -0.4,-0.4, 0.4,1.0,  0.4,-0.4, 0.4,1.0,
                0.4, 0.4, 0.4,1.0, -0.4, 0.4, 0.4,1.0,

			   -0.2,-0.2,-0.2,1.0,  0.2,-0.2,-0.2,1.0,
			    0.2, 0.2,-0.2,1.0, -0.2, 0.2,-0.2,1.0,
               -0.2,-0.2, 0.2,1.0,  0.2,-0.2, 0.2,1.0,
                0.2, 0.2, 0.2,1.0, -0.2, 0.2, 0.2,1.0 ] asm; 


f32[CUBE_SIZE*VEC3] ndcCube = [ ] asm;


f32[16] model = [ ] asm;
f32[16] view = [ ] asm;
f32[16] proj = [ ] asm;
f32[16] mvp = [ ] asm;
ptr[3] matrixArray = [ proj, view, model ];


// Model
//glm.glmc_mat4_identity(model);
//f32[3] vec3_1 = [ 1.0, 0.0, 0.0 ] asm;
//f32[3] vec3_2 = [ 0.0, 1.0, 0.0 ] asm;
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_1);
//glm.glmc_rotate(model, DegreeToRadians(3.0), vec3_2);
//glm_translate(model, (vec3){0.0f, 0.0f, -3.0f});


// View
f32[3] vec3_eye = [ 0.0, 0.0, 5.0 ] asm;
f32[3] vec3_center = [ 0.0, 0.0, 0.0 ] asm;
f32[3] vec3_up = [ 0.0, 1.0, 0.0 ] asm;
glm.glmc_mat4_identity(view);
glm.glmc_lookat(vec3_eye, vec3_center, vec3_up, view);


// Projection
glm.glmc_mat4_identity(proj);
glm.glmc_perspective(DegreeToRadians(60.0), 1280.0 / 720.0, 0.1, 100.0, proj);


glm.glmc_mat4_mulN(matrixArray, 3, mvp);


asm procedures {
compare_thearray:
  xor	eax, eax
  mov	eax, dword [rcx+8]
  sub	rsp, 8
  mov	[rsp], eax
  movss	xmm0, dword [rsp]
  mov	eax, dword [rdx+8]
  mov	[rsp], eax
  movss	xmm1, dword [rsp]
  add	rsp, 8

  ucomiss xmm0, xmm1
  jb    .exitLess
  ja    .exitGreater
  jmp   .exitEqual

.exitLess:
  mov	eax, -1
  ret
.exitGreater:
  mov	eax, 1
  ret
.exitEqual:
  xor	eax, eax        ; eax = 0
  ret
}


f32[VEC4] tmpVec4 = [] asm;
f32 cube_XRotation = 0.0;
f32 cube_YRotation = 0.0;

function RenderCube() {
	
	cube_XRotation = cube_XRotation + 0.01;
	cube_XRotation = ValidRadian_f32(cube_XRotation);
	cube_YRotation = cube_YRotation + 0.02;
	cube_YRotation = ValidRadian_f32(cube_YRotation);

	glm.glmc_mat4_identity(model);
	glm.glmc_rotate_x(model, cube_XRotation, model);
	glm.glmc_rotate_y(model, cube_YRotation, model);

	glm.glmc_mat4_mulN(matrixArray, 3, mvp);

	for (i in 0 ..< CUBE_SIZE) {
		glm.glmc_mat4_mulv(mvp, &cube[i*VEC4], tmpVec4);

		float ndc_x = tmpVec4[0] / tmpVec4[3];
		float ndc_y = tmpVec4[1] / tmpVec4[3];
		float ndc_z = tmpVec4[2] / tmpVec4[3];   // depth

		ndcCube[i*VEC3] = ndc_x;
		ndcCube[i*VEC3+1] = ndc_y;
		ndcCube[i*VEC3+2] = ndc_z;
	}

	sdl3.SDL_qsort(ndcCube, CUBE_SIZE, 3*sizeof(f32), g.compare_thearray);

	for (i in (CUBE_SIZE-1)..0) {
		float screen_x = (ndcCube[i*VEC3] + 0.5) * 1280.0;
		float screen_y = (1.0 - (ndcCube[i*VEC3+1] + 0.5)) * 720.0; // flip Y for screen space

		float ballSize = (0.99 - ndcCube[i*VEC3+2]) * 1500.0;

		ballDestRect[0] = screen_x;
		ballDestRect[1] = screen_y;
		ballDestRect[2] = ballSize;
		ballDestRect[3] = ballSize;

		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		sdl3.SDL_RenderTextureRotated(renderer, ballTexture, ballSrc, &ballDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}
}


sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
g.[pixels_p] = pixels;
SDL3_ClearScreenPixels(0xff808080);
sdl3.SDL_UnlockTexture(texture);
sdl3.SDL_RenderTexture(renderer, texture, null, null);

#include soundtracker.g
SoundtrackerInit("sound/mod/watchman-25.12.mod", 127);

while (StatusRunning)
{
	SoundtrackerUpdate();

	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (keyState[g.SDL_SCANCODE_UP]) { }
	if (keyState[g.SDL_SCANCODE_LEFT]) { }
	if (keyState[g.SDL_SCANCODE_RIGHT]) { }
	if (keyState[g.SDL_SCANCODE_DOWN]) { }

	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	RenderCube();

	//sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	//sdl3.SDL_RenderLine(renderer, 20.0, 20.0, 40.0, 40.0);
	//writeText(renderer, 60.0, 60.0, "SDL3 debug...");

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


sdl3.SDL_DestroyTexture(ballTexture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);
