
// De posities van het grid:
//  0,  1,  2,  3,  4,  5,  6
//    7,  8,  9, 10, 11, 12
// 14, 15, 16, 17, 18, 19, 20 
//   21, 22, 23, 24, 25, 26
// 28, 29, 30, 31, 32, 33, 34
//   35, 36, 37, 38, 39, 40
// 42, 43, 44, 45, 46, 47, 48
// i32* destp = ScreenPointerForXY(startX, startY); for (k in 0..20) { *destp = 0xffffffff; destp = destp + 4; }

int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = g.GC_ScreenLineSize;
u32 seedRandom = 12313;


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	f32 scale = 3.02;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	f32 theX = x;
	f32 theY = y;
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x80, 0xff, 0x80, 0xff);
	scale = 3.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
}


function msys_frand(u32* seed) : int
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 16) & 32767;
	return a;
}


function ScreenPointerForXY(int x, int y) {	
	pointer result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}

