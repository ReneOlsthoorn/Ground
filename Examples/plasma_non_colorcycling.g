// Plasma without colorcycling.

#template sdl3

#define palettesize 512
#define sinustablesize 16384

#include graphics_defines960x560.g
#library sdl3 sdl3.dll SDL3
#library sdl3_image sdl3_image.dll SDL3_image

#linux   #include clib.g
#linux   #dllalias cruntime clib
#windows #include msvcrt.g
#windows #dllalias cruntime msvcrt


class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() : int {
        return 0xff000000 + (this.red << 16) + (this.green << 8) + this.blue;
    }
}

function validRadian(float radian) : float {
	float valid = radian;
	while (valid >= MATH_2PI)
		valid = valid - MATH_2PI;
	return valid;
}

u32[palettesize] palette = [];
for (int i = 0; i < palettesize; i++) {
	ColorRGB color;
    color.red = 128.0 + (127.0 * sdl3.SDL_sin(validRadian(MATH_2PI * (i / 128.0))));
    color.green = 128.0 + (127.0 * sdl3.SDL_sin(validRadian(MATH_2PI * (i / 256.0))));
    color.blue = 128.0 + (127.0 * sdl3.SDL_sin(validRadian(MATH_2PI * (i / 512.0))));
    palette[i] = color.ToInteger();
}

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Plasma without colorcycling", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, null);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

int frameCount = 0;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = SCREEN_LINESIZE;
bool thread1Busy = false;
bool thread2Busy = false;

int[] sinusTable = cruntime.malloc(sinustablesize * 8);  // values from 0 to 65536. Zero value = 32768
for (i in 0 ..< sinustablesize)
	sinusTable[i] = 32768.0 + (32768.0 * sdl3.SDL_sin((i / 16384.0) * MATH_2PI));

function Plasma_loop(int y) {
	for (int x = 0; x < SCREEN_WIDTH; x++) {
		int x2 = x + ((sinusTable[(y*80) % sinustablesize]) >> 8);
		int fx1 = (x2*19) + ((frameCount*13) % sinustablesize);
		int fx2 = (x2*8) + ((frameCount*48) % sinustablesize);
		int fy1 = (y*31) + ((frameCount*13) % sinustablesize);
		int fy2 = (y*16) + ((frameCount*48) % sinustablesize);
		int fx = sinusTable[fx1 % sinustablesize] + sinusTable[fx2 % sinustablesize];
		int fy = sinusTable[fy1 % sinustablesize] + sinusTable[fy2 % sinustablesize];

		fx = fx >> 9;  // 32768 down to palettesize
		fy = fy >> 9;

		pixels[x, y] = palette[ (fx + fy) % palettesize ];
	}
}

function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
			for (int y = 0; y < SCREEN_HEIGHT >> 1; y++)
				Plasma_loop(y);

			thread2Busy = false;
		}
	}
}

#windows GC_CreateThread(Thread2);
#linux   GC_Clone(Thread2);

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
	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;
	loopStartTicks = sdl3.SDL_GetTicks();

	if (thread1Busy) {
		for (int y = SCREEN_HEIGHT >> 1; y < SCREEN_HEIGHT; y++)
			Plasma_loop(y);

		thread1Busy = false;
	}
	while (thread2Busy) { }

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

cruntime.free(sinusTable);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
