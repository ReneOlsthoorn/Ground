

int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = g.GC_ScreenLineSize;
u32 seedRandom = 5;

class SDL_AudioSpec {
	u32 format;
	i32 channels;
	i32 freq;
}
SDL_AudioSpec spec;
ptr stream = null;
u8* wavData = null;
u32 wavDataLen = 0;


function writeText(ptr renderer, float x, float y, string text) {
	f32 scale = 3.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	f32 theX = x;
	f32 theY = y;
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX+2.0, theY, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
}


function msys_frand(u32* seed) : int
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 16) & 32767;
	return a;
}


function ScreenPointerForXY(int x, int y) : ptr {	
	ptr result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}

