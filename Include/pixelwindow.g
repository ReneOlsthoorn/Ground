
#template sdl3

#include graphics_defines1280x720.g
#library sdl3 sdl3.dll SDL3
#library sdl3_image sdl3_image.dll SDL3_image

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
int frameCount = 0;
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
bool thread1Busy = false;
bool thread2Busy = false;
bool thread3Busy = false;
bool thread4Busy = false;

function WaitForThread2() { while (thread2Busy) { } }
function WaitForThread3() { while (thread3Busy) { } }
function WaitForThread4() { while (thread4Busy) { } }

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow(pixelWindowTitle, SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, null);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

function Update();
function Init();
function DeInit();
function Thread2();
function Thread3();
function Thread4();

sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
g.[pixels_p] = pixels;
Init();
sdl3.SDL_UnlockTexture(texture);

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}
	loopStartTicks = sdl3.SDL_GetTicks();

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	Update();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

DeInit();
sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
