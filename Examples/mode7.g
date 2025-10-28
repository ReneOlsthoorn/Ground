//Mode7 example. See here the proof that depth is a division.
//This version is not optimized. The innerloop runs in 5ms on my PC.  See mode7_optimized.g to see how each statement in the innerloop can be replaced by x86-64.

#template sdl3

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g

#define MAP_SIZE 1024

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Mode 7", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

int frameCount = 0;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
float fWorldX = 132.8;
float fWorldY = 651.5;
float fWorldAngle = MATH_PI / 2.0;
float fNear = MAP_SIZE * 0.025;
float fFar = MAP_SIZE * 0.60;
float fFoVHalf = MATH_PI / 4.0;		// 180 degrees divided by four = 45 degrees. De FOV = 90, so start = -45 degrees, end = +45 degrees.
float space_y = 100.0;
float scale_y = 200.0;
int horizon = 15;
int pitch = SCREEN_LINESIZE;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
asm data {racetrack_p dq 0}
g.[racetrack_p] = sidelib.LoadImage("image/playfield1024.png");
if (g.[racetrack_p] == null) { user32.MessageBox(null, "The playfield1024.png cannot be found!", "Message", g.MB_OK); return; }
sidelib.FlipRedAndGreenInImage(g.[racetrack_p], MAP_SIZE, MAP_SIZE);
u32[MAP_SIZE, MAP_SIZE] racetrack = g.[racetrack_p];


function Innerloop() {
	for (y in 0 ..< SCREEN_HEIGHT) {
		float distance = space_y * scale_y / (y + horizon);
		float fStartX = fWorldX + (msvcrt.cos(fWorldAngle + fFoVHalf) * distance);
		float fStartY = fWorldY - (msvcrt.sin(fWorldAngle + fFoVHalf) * distance);
		float fEndX = fWorldX + (msvcrt.cos(fWorldAngle - fFoVHalf) * distance);
		float fEndY = fWorldY - (msvcrt.sin(fWorldAngle - fFoVHalf) * distance);

		for (x in 0 ..< SCREEN_WIDTH) {
			float fSampleWidth = x / SCREEN_WIDTH_F;
			float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleY = fStartY + ((fEndY - fStartY) * fSampleWidth);
			int iSampleX = fSampleX;
			int iSampleY = fSampleY;

			u32 pixelColor = 0xff000000;
			if ((iSampleX >= 0) and (iSampleX < MAP_SIZE) and (iSampleY >= 0) and (iSampleY < MAP_SIZE)) {
				pixelColor = racetrack[iSampleX, iSampleY];
			}
			pixels[x, y] = pixelColor;
		}
	}
}


while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	Innerloop();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks and currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
	fWorldY = fWorldY - 0.3;
	fWorldAngle = fWorldAngle - 0.001;

	if (frameCount > 1000) {
		fWorldAngle = MATH_PI / 2.0;
		fWorldY = 551.5;
		frameCount = 1;
	}
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

sidelib.FreeImage(g.[racetrack_p]);

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

// string showStr = "Best innerloop time: " + debugBestTicks + "ms";
// user32.MessageBox(null, showStr, "Message", g.MB_OK);
