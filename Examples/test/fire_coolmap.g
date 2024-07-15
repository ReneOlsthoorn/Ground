//Fire coolingmap creator

#template sdl2

#include msvcrt.g
#include sdl2.g
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

				pixels[theX,theY] = average;
            }
        }
    }
}

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return (this.red << 16) + (this.green << 8) + this.blue;
    }
}

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Fire coolmap creator", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
bool drawTheScene = true;

while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	sdl2.SDL_LockTexture(texture, null, &pixels, &pitch);
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

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();
