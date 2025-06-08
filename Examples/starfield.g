// Starfield

#template sdl3

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Travelling Through Stars", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();


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
		SetPixel(star_screenx[i], star_screeny[i], 0xff000000);
		star_z[i] = star_z[i] - star_zv[i];
		star_screenx[i] = ((star_x[i] / star_z[i]) * 6000.0) + 480.0;
		star_screeny[i] = ((star_y[i] / star_z[i]) * 4000.0) + 280.0;

		int x = star_screenx[i];
		int y = star_screeny[i];

		int brightness = 255 - (star_z[i] * 0.255);
		u32 pixelColor = 0xff000000 or brightness or brightness << 8 or brightness << 16;
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

	StarField();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0) {
		debugBestTicks = currentTicks;
	}

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
