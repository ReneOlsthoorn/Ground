
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
int pitch = SCREEN_LINESIZE;

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

// Loading sounds...
ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr jumpSfxr = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(jumpSfxr, "sound/sfxr/jump.sfs");
if (sfxrLoaded != 0) return;
ptr fallSfxr = soloud.Sfxr_create();
sfxrLoaded = soloud.Sfxr_loadParams(fallSfxr, "sound/sfxr/fall.sfs");
if (sfxrLoaded != 0) return;
ptr hurtSfxr = soloud.Sfxr_create();
sfxrLoaded = soloud.Sfxr_loadParams(hurtSfxr, "sound/sfxr/hurt.sfs");
if (sfxrLoaded != 0) return;

function playJump() { soloud.Soloud_play(soloudObject, jumpSfxr); }
function playFall() { soloud.Soloud_play(soloudObject, fallSfxr); }
function playHurt() { soloud.Soloud_play(soloudObject, hurtSfxr); }

function deleteSoundObjects() {
	soloud.Sfxr_destroy(jumpSfxr);
	soloud.Sfxr_destroy(fallSfxr);
	soloud.Sfxr_destroy(hurtSfxr);
	soloud.Soloud_deinit(soloudObject);
	soloud.Soloud_destroy(soloudObject);
}
