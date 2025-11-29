//Plasma example.
//https://lodev.org/cgtutor/plasma.html

#template sdl3

#define palettesize 256

#include graphics_defines1280x720.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#library user32 user32.dll
#library sidelib GroundSideLibrary.dll


u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int screenpitch = SCREEN_LINESIZE;
u32[SCREEN_WIDTH,SCREEN_HEIGHT] plasma = [];
bool recalcPlasma = true;
u32[palettesize] palette = [];



ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Colorcycling plasma", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);


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

for (int i = 0; i < palettesize; i++) {
	ColorRGB color;

	/*
    color.red = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 64.0))));
    color.green = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 512.0))));
    color.blue = 0;
	*/

    color.red = 128.0 + (127.0 * msvcrt.sin(validRadian(MATH_2PI * (i / 64.0))));
    color.green = 128.0 + (127.0 * msvcrt.sin(validRadian(MATH_2PI * (i / 128.0))));
    color.blue = 128.0 + (127.0 * msvcrt.sin(validRadian(MATH_2PI * (i / 256.0))));
    palette[i] = color.ToInteger();
}

function Innerloop() {
	for (int y = 0; y < SCREEN_HEIGHT; y++) {
		for (int x = 0; x < SCREEN_WIDTH; x++) {
			u32 pixelColor = plasma[x, y];

			if (recalcPlasma == true) {
				//pixelColor = 128.0 + (127.0 * msvcrt.sin(x / 32.0));
				//pixelColor = 128.0 + (127.0 * msvcrt.sin((x+y) / 64.0));
				//pixelColor = 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt((x - SCREEN_WIDTH / 2.0) * (x - SCREEN_WIDTH / 2.0) + (y - SCREEN_HEIGHT / 2.0) * (y - SCREEN_HEIGHT / 2.0)) / 64.0));
				//pixelColor = (128.0 + (127.0 * msvcrt.sin(x / 64.0)) + 128.0 + (127.0 * msvcrt.sin(y / 64.0))) / 2;
				/*
				pixelColor = (128.0 + (127.0 * msvcrt.sin(x / 128.0)) +
						 128.0 + (127.0 * msvcrt.sin(y / 64.0)) + 
						 128.0 + (127.0 * msvcrt.sin((x + y) / 128.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt(x * x + y * y) / 64.0))
						 ) / 4;
				*/

				pixelColor = (128.0 + (127.0 * msvcrt.sin(x / 64.0)) +
						 128.0 + (127.0 * msvcrt.sin(y / 128.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt((x - SCREEN_WIDTH / 2.0) * (x - SCREEN_WIDTH / 2.0) + (y - SCREEN_HEIGHT / 2.0) * (y - SCREEN_HEIGHT / 2.0)) / 32.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt(x * x + y * y) / 128.0))
						 ) / 4;

				plasma[x,y] = pixelColor;
			}

			pixels[x, y] = palette[ (pixelColor + frameCount) % palettesize ];
		}
	}
	recalcPlasma = false;
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

	sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	Innerloop();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
