
#template retrovm

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g
#include sidelib.g

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Mode 7", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy);

u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
int pitch = g.Graphics_ScreenLineSize;

int frameCount = 0;
bool StatusRunning = true;

asm data {racetrack_p dq 0}
g.[racetrack_p] = sidelib.LoadImage("playfield1024.png");
sidelib.FlipRedAndGreenInImage(g.[racetrack_p], 1024, 1024);
u32[1024, 1024] racetrack = g.[racetrack_p];
if (racetrack == null) {
	user32.MessageBox(null, "The do_not_use.png cannot be found!", "Message", g.MB_OK);
	return;
}

int nMapSize = 1024;
float fWorldX = 132.8;
float fWorldY = 551.5;
float fWorldAngle = 3.141592 / 2.0;  // pi/2
float fNear = nMapSize * 0.025;
float fFar = nMapSize * 0.60;
float fFoVHalf = 3.141592 / 4.0; //90 graden gedeeld door twee, omdat we twee keer een half doen.
float space_y = 100.0;
float scale_y = 200.0;
int horizon = 15;
float float_ScreenDIMx = 960.0;

while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	sdl2.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	for (int y = 0; y < g.Graphics_ScreenDIMy; y++) {
		float distance = space_y * scale_y / (y + horizon);
		float fStartX = fWorldX + (msvcrt.cos(fWorldAngle + fFoVHalf) * distance);
		float fStartY = fWorldY - (msvcrt.sin(fWorldAngle + fFoVHalf) * distance);
		float fEndX = fWorldX + (msvcrt.cos(fWorldAngle - fFoVHalf) * distance);
		float fEndY = fWorldY - (msvcrt.sin(fWorldAngle - fFoVHalf) * distance);

		for (int x = 0; x < g.Graphics_ScreenDIMx; x++) {
			float fSampleWidth = x / float_ScreenDIMx;
			float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleY = fStartY + ((fEndY - fStartY) * fSampleWidth);
			int iSampleX = fSampleX;
			int iSampleY = fSampleY;

			u32 pixelColor = 0;
			if ((iSampleX >= 0) and (iSampleX < 1024) and (iSampleY >= 0) and (iSampleY < 1024)) {
				pixelColor = racetrack[iSampleX, iSampleY];
			}
			pixels[x, y] = pixelColor;
		}
	}

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	frameCount++;
	fWorldY = fWorldY - 0.3;
	fWorldAngle = fWorldAngle - 0.001;

	if (frameCount > 1000) {
		fWorldAngle = 3.141592 / 2.0;
		fWorldY = 551.5;
		frameCount = 1;
	}
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

sidelib.FreeImage(g.[racetrack_p]);
