//Mode7 example. See here the proof that depth is a division.
//This version is not optimized. The innerloop runs in 5ms on my PC.  See mode7_optimized.g to see how each statement in the innerloop can be replaced by x86-64.

#template sdl2

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g
#include sidelib.g

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Mode 7", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

int frameCount = 0;
u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int nMapSize = 1024;
float fWorldX = 132.8;
float fWorldY = 651.5;
float fWorldAngle = 3.141592 / 2.0;		// pi/2
float fNear = nMapSize * 0.025;
float fFar = nMapSize * 0.60;
float fFoVHalf = 3.141592 / 4.0;		// 180 degrees divided by four = 45 degrees. De FOV = 90, so start = -45 degrees, end = +45 degrees.
float space_y = 100.0;
float scale_y = 200.0;
int horizon = 15;
float float_ScreenDIMx = 960.0;
int pitch = g.GC_ScreenLineSize;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;

asm data {racetrack_p dq 0}
g.[racetrack_p] = sidelib.LoadImage("playfield1024.png");
if (g.[racetrack_p] == null) {
	user32.MessageBox(null, "The playfield1024.png cannot be found!", "Message", g.MB_OK);
	return;
}
sidelib.FlipRedAndGreenInImage(g.[racetrack_p], 1024, 1024);
u32[1024, 1024] racetrack = g.[racetrack_p];


function Innerloop() {
	for (y in 0 ..< g.GC_Screen_DimY) {
		float distance = space_y * scale_y / (y + horizon);
		float fStartX = fWorldX + (msvcrt.cos(fWorldAngle + fFoVHalf) * distance);
		float fStartY = fWorldY - (msvcrt.sin(fWorldAngle + fFoVHalf) * distance);
		float fEndX = fWorldX + (msvcrt.cos(fWorldAngle - fFoVHalf) * distance);
		float fEndY = fWorldY - (msvcrt.sin(fWorldAngle - fFoVHalf) * distance);

		for (x in 0 ..< g.GC_Screen_DimX) {
			float fSampleWidth = x / float_ScreenDIMx;
			float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleY = fStartY + ((fEndY - fStartY) * fSampleWidth);
			int iSampleX = fSampleX;
			int iSampleY = fSampleY;

			u32 pixelColor = 0;
			if ((iSampleX >= 0) and (iSampleX < 1024) and (iSampleY >= 0) and (iSampleY < 1024)) {
				pixelColor = racetrack[iSampleX, iSampleY];
			}
			pixels[x, y] = pixelColor;
		}
	}
}


while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	sdl2.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl2.SDL_GetTicks();

	Innerloop();

	int currentTicks = sdl2.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks) {
		debugBestTicks = currentTicks;
	}

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	frameCount++;
	fWorldY = fWorldY - 0.3;
	fWorldAngle = fWorldAngle - 0.001;

	if (frameCount > 1000) {
		fWorldAngle = 3.141592 / 2.0;
		fWorldY = 551.5;
		frameCount = 1;
	}
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

sidelib.FreeImage(g.[racetrack_p]);

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

string showStr = "Best innerloop time: " + debugBestTicks + "ms";
user32.MessageBox(null, showStr, "Message", g.MB_OK);
