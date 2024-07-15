//Fire palette creator

#template sdl2

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g


class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return 0xff000000 + (65536 * this.red) + (256 * this.green) + this.blue;
    }
}

u32[256] palette = [];
int offset = 0;

function CreateGradient(int nrSteps, ColorRGB startColor, ColorRGB endColor) {
	ColorRGB color;
	float fSteps = nrSteps;

    for (int i = 0; i < nrSteps; i++) {
        color.red = startColor.red + (i * ((endColor.red - startColor.red) / fSteps));
        color.green = startColor.green + (i * ((endColor.green - startColor.green) / fSteps));
        color.blue = startColor.blue + (i * ((endColor.blue - startColor.blue) / fSteps));
        palette[offset] = color.ToInteger();
		offset++;
    }
}

CreateGradient(64, ColorRGB(0,0,0), ColorRGB(0x8b,0,0));
CreateGradient(64, ColorRGB(0x8b,0,0), ColorRGB(0xff,0,0));
CreateGradient(64, ColorRGB(0xff,0,0), ColorRGB(0xff,0xff,0));
CreateGradient(64, ColorRGB(0xff,0xff,0), ColorRGB(0xff,0xff,0xff));

int resultFile = msvcrt.fopen("fire_palette.bin", "wb");
msvcrt.fwrite(palette, 4, 256, resultFile);
msvcrt.fclose(resultFile);

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Fire palette creator", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

int frameCount = 0;
u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
bool thread1Busy = false;

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
	if (thread1Busy) {
		for (int i = 0; i < 256; i++) {
			for (int y = 0; y < g.GC_Screen_DimY; y++) {
				pixels[i,y] = palette[i];
			}
		}
		thread1Busy = false;
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
