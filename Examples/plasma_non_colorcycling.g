// Plasma without colorcycling.

#template sdl2

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g
#include sidelib.g

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return (65536 * this.red) + (256 * this.green) + this.blue;
    }
}

function validRadian(float radian) : float {
	float valid = radian;
	while (valid > 6.283185307) {
		valid = valid - 6.283185307;
	}
	return valid;
}

u32[512] palette = [];
for (int i = 0; i < 512; i++) {
	ColorRGB color;
    //color.red = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 64.0))));
    //color.green = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 512.0))));
    //color.blue = 0;

    color.red = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 128.0))));
    color.green = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 256.0))));
    color.blue = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 512.0))));

    palette[i] = color.ToInteger();
}

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Plasma without colorcycling", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

int frameCount = 0;
u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = g.GC_ScreenLineSize;
bool thread1Busy = false;
bool thread2Busy = false;

int[16384] sinusTable = [];  // values from 0 to 65536. Zero value = 32768
for (i = 0; i < 16384; i++) {
	sinusTable[i] = 32768.0 + (32768.0 * msvcrt.sin((i / 16384.0) * 6.283184));
}

function Plasma_loop(int y) {
	for (int x = 0; x < g.GC_Screen_DimX; x++) {
		int x2 = x + ((sinusTable[(y*80) % 16384]) >> 8);
		int fx1 = (x2*19) + ((frameCount*13) % 16384);
		int fx2 = (x2*8) + ((frameCount*48) % 16384);
		int fy1 = (y*31) + ((frameCount*13) % 16384);
		int fy2 = (y*16) + ((frameCount*48) % 16384);
		int fx = sinusTable[fx1 % 16384] + sinusTable[fx2 % 16384];
		int fy = sinusTable[fy1 % 16384] + sinusTable[fy2 % 16384];

		fx = fx >> 9;  // 32768 down to 512
		fy = fy >> 9;

		pixels[x, y] = palette[ (fx + fy) % 512 ];
	}
}

function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
			for (int y = 0; y < (g.GC_Screen_DimY >> 1); y++) {
				Plasma_loop(y);
			}
			thread2Busy = false;
		}
	}
}
ptr thread2Handle = GC_CreateThread(Thread2);
kernel32.SetThreadPriority(thread2Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.


while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	sdl2.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;
	loopStartTicks = sdl2.SDL_GetTicks();

	if (thread1Busy) {
		for (int y = (g.GC_Screen_DimY >> 1); y < g.GC_Screen_DimY; y++) {
			Plasma_loop(y);
		}
		thread1Busy = false;
	}
	while (thread2Busy) { }

	int currentTicks = sdl2.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0) {
		debugBestTicks = currentTicks;
	}

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

// string showStr = "Best innerloop time: " + debugBestTicks + "ms";
// user32.MessageBox(null, showStr, "Message", g.MB_OK);
