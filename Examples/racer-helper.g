

byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = g.GC_ScreenLineSize;


ptr pl1Surface = sdl3_image.IMG_Load("racer_p1_38x75.png");
if (pl1Surface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr pl1Texture = sdl3.SDL_CreateTextureFromSurface(renderer, pl1Surface);
if (pl1Texture == null) { user32.MessageBox(null, "Texture not available!", "Message", g.MB_OK); return; }
sdl3.SDL_DestroySurface(pl1Surface);

ptr pl2Surface = sdl3_image.IMG_Load("racer_p2_37x76.png");
ptr pl2Texture = sdl3.SDL_CreateTextureFromSurface(renderer, pl2Surface);
sdl3.SDL_DestroySurface(pl2Surface);

ptr pl3Surface = sdl3_image.IMG_Load("racer_p3_54x75.png");
ptr pl3Texture = sdl3.SDL_CreateTextureFromSurface(renderer, pl3Surface);
sdl3.SDL_DestroySurface(pl3Surface);

ptr pl7Surface = sdl3_image.IMG_Load("racer_p7_37x76.png");
ptr pl7Texture = sdl3.SDL_CreateTextureFromSurface(renderer, pl7Surface);
sdl3.SDL_DestroySurface(pl7Surface);

ptr pl8Surface = sdl3_image.IMG_Load("racer_p8_54x75.png");
ptr pl8Texture = sdl3.SDL_CreateTextureFromSurface(renderer, pl8Surface);
sdl3.SDL_DestroySurface(pl8Surface);

ptr backgroundSurface = sdl3_image.IMG_Load("racer_background.png");
ptr backgroundTexture = sdl3.SDL_CreateTextureFromSurface(renderer, backgroundSurface);
sdl3.SDL_DestroySurface(backgroundSurface);

f32[4] destRect = [];


function writeText(ptr renderer, float x, float y, string text) {
	f32 scale = 1.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	f32 theX = x;
	f32 theY = y;
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX+2.0, theY, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xe0, 0xe0, 0xe0, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
}
