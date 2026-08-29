
// The positions of the grid:
//  0,  1,  2,  3,  4,  5,  6
//    7,  8,  9, 10, 11, 12
// 14, 15, 16, 17, 18, 19, 20 
//   21, 22, 23, 24, 25, 26
// 28, 29, 30, 31, 32, 33, 34
//   35, 36, 37, 38, 39, 40
// 42, 43, 44, 45, 46, 47, 48

byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
u8* eventRepeat = &event[SDL3_KEYBOARDEVENT_REPEAT_U8];
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int screenpitch = SCREEN_LINESIZE;

function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_SetRenderScale(renderer, 3.02, 3.02);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x80, 0xff, 0x80, 0xff);
	sdl3.SDL_SetRenderScale(renderer, 3.0, 3.0);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function ScreenPointerForXY(int x, int y) {	
	pointer result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}
