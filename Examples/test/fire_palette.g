//Fire palette creator

#template sdl3

#include msvcrt.g
#include sdl3.g
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

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Fire palette creator", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);

int frameCount = 0;
u32[960, 560] pixels = null;
byte[128] event = [];
u32* eventType = &event[0];
u32* eventScancode = &event[24];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
bool thread1Busy = false;

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
	thread1Busy = StatusRunning;
	if (thread1Busy) {
		for (int i = 0; i < 256; i++) {
			for (int y = 0; y < g.GC_Screen_DimY; y++) {
				pixels[i,y] = palette[i];
			}
		}
		thread1Busy = false;
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
