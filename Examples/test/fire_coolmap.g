//Fire coolingmap creator

#template sdl3

#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g

int coolmapWidth = g.GC_Screen_DimX;
int coolmapHeight = g.GC_Screen_DimY;
int frameCount = 0;
u32[960, 560] pixels = null;
int seed = 123123;

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

function msys_rand(int* seed) : u32
{
	seed[0] = (seed[0] * 0x343FD) + 0x269EC3;
	u32 res = (seed[0] >> 16) and 32767;
	return res;
}

function SetWhites() {
	int aantalWhites = (coolmapHeight * coolmapWidth) / 50;
	int width = coolmapWidth - 6;
	int height = coolmapHeight - 6;
	for (int w = 0; w < aantalWhites; w++) {
		int newX = msys_frand(&seed) * width;
		int newY = msys_frand(&seed) * height;
		newX = newX + 3;
		newY = newY + 3;
		pixels[newX,newY] = 0xffffffff;

		pixels[newX,(newY-1)] = 0xffffffff;
		pixels[(newX-1),newY] = 0xffffffff;
		pixels[(newX-1),(newY-1)] = 0xffffffff;

		pixels[newX,(newY+1)] = 0xffffffff;
		pixels[(newX+1),newY] = 0xffffffff;
		pixels[(newX+1),(newY+1)] = 0xffffffff;
	}
}

function AverageTheField() {
	int width = coolmapWidth - 2;
	int height = coolmapHeight - 2;
    for (int n = 0; n < 20; n++)
    {
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
				int theX = x + 1;
				int theY = y + 1;

                u32 coolValue = pixels[theX,theY] and 0xff;
                u32 coolBoven = pixels[theX,(theY-1)] and 0xff;
                u32 coolOnder = pixels[theX,(theY+1)] and 0xff;
                u32 coolLinks = pixels[(theX-1),theY] and 0xff;
                u32 coolRechts = pixels[(theX+1),theY] and 0xff;

				int average = coolValue + coolBoven + coolOnder + coolLinks + coolRechts;
				average = average / 5;
				average = (average << 16) + (average << 8) + average;

				pixels[theX,theY] = 0xff000000 + average;
            }
        }
    }
}

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return 0xff000000 + (this.red << 16) + (this.green << 8) + this.blue;
    }
}

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Fire coolmap creator", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);

byte[128] event = [];
u32* eventType = &event[0];
u32* eventScancode = &event[24];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
bool drawTheScene = true;

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT) {
			StatusRunning = false;
		}
		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE) {
				StatusRunning = false;
			}
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	if (drawTheScene) {
		drawTheScene = false;
		SetWhites();
		AverageTheField();

		int coolmapFile = msvcrt.fopen("fire_coolmap.bin", "wb");
		int arraySize = 960*560;
		byte[] coolmapPointer = msvcrt.calloc(1, arraySize);

		u32[] colorPixels = pixels;
		for (int j = 0; j < 960*560; j++) {
			u32 aPixel = colorPixels[j];
			coolmapPointer[j] = aPixel and 0xff;
		}

		msvcrt.fwrite(coolmapPointer, arraySize, 1, coolmapFile);
		msvcrt.fclose(coolmapFile);
		msvcrt.free(coolmapPointer);
	}

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
