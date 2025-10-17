
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = SCREEN_LINESIZE;
int currentTime = 0;
msvcrt.time64(&currentTime);
msvcrt.srand(currentTime);

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

function ScreenPointerForXY(int x, int y) : ptr {	
	ptr result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}
