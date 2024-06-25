// Starfield

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
ptr window = sdl2.SDL_CreateWindow("Travelling Through Stars", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

int frameCount = 0;
u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;


int numberOfStars = 700;
int SeedStarfield = 123123;
float[700] star_x = []; //van -500 tot 500
float[700] star_y = []; //van -500 tot 500
float[700] star_z = []; //van 100 tot 1000
float[700] star_zv = []; //speed: from .5 to 5

int[700] star_screenx = [];
int[700] star_screeny = [];


function msys_frand(u32* seed) : float
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 9) or 0x3f800000;

	float floatedA;
	asm {
		movss    xmm0, dword [a@msys_frand]
		cvtss2sd xmm1, xmm0
		movq     qword [floatedA@msys_frand], xmm1
	}
	float res = floatedA - 1.0;
	return res;
}


function InitStarField()
{
	for (int i = 0; i < numberOfStars; i++)
	{
		float rand = msys_frand(&SeedStarfield);
		float starX = (rand - 0.5) * 100.0;
		rand = msys_frand(&SeedStarfield);
		float starY = (rand - 0.5) * 100.0;
		rand = msys_frand(&SeedStarfield);
		float starZ = (rand * 900.0) + 100.0;
		rand = msys_frand(&SeedStarfield);
		float starZV = (rand * 4.5) + 0.5;
		star_x[i] = starX;
		star_y[i] = starY;
		star_z[i] = starZ;
		star_zv[i] = starZV;
	}
}

function SetPixel(int x, int y, u32 color)
{
	if ((x > 955) or (x < 5) or (y > 555) or (y < 5))
		return;

	pixels[x,y] = color;
	pixels[x+1,y] = color;
	pixels[x,y+1] = color;
	pixels[x+1,y+1] = color;
}


function StarField()
{
	for (int i = 0; i < numberOfStars; i++)
	{
		SetPixel(star_screenx[i], star_screeny[i], 0);
		star_z[i] = star_z[i] - star_zv[i];
		star_screenx[i] = ((star_x[i] / star_z[i]) * 6000.0) + 480.0;
		star_screeny[i] = ((star_y[i] / star_z[i]) * 4000.0) + 280.0;

		int x = star_screenx[i];
		int y = star_screeny[i];

		int brightness = 255 - (star_z[i] * 0.255);
		u32 pixelColor = brightness or brightness << 8 or brightness << 16;
		SetPixel(x, y, pixelColor);

		if ((x > 955) or (x < 5) or (y > 555) or (y < 5) or (star_z[i] < 0.0))
		{
			float rand = msys_frand(&SeedStarfield);
			float starX = (rand - 0.5) * 100.0;
			rand = msys_frand(&SeedStarfield);
			float starY = (rand - 0.5) * 100.0;
			rand = msys_frand(&SeedStarfield);
			float starZ = (rand + 0.1) * 900.0;
			star_x[i] = starX;
			star_y[i] = starY;
			star_z[i] = starZ;
		}
	}
}

InitStarField();

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

	StarField();

	int currentTicks = sdl2.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks) {
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

string showStr = "Best innerloop time: " + debugBestTicks + "ms";
user32.MessageBox(null, showStr, "Message", g.MB_OK);
