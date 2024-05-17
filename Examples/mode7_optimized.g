//Mode7 example. See here the proof that depth is a division and that some statements in the innerloop code can be replaced by x86-64.
//This version is optimized. The innerloop runs in 3ms on my PC.

#template sdl2

#include msvcrt.g
#include sdl2.g
#include user32.g
#include sidelib.g

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Mode 7", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

u32[960, 560] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
int pitch = g.GC_ScreenLineSize;

int frameCount = 0;
bool StatusRunning = true;

asm data {racetrack_p dq 0}
g.[racetrack_p] = sidelib.LoadImage("playfield1024.png");
if (g.[racetrack_p] == null) {
	user32.MessageBox(null, "The playfield1024.png cannot be found!", "Message", g.MB_OK);
	return;
}
sidelib.FlipRedAndGreenInImage(g.[racetrack_p], 1024, 1024);
u32[1024, 1024] racetrack = g.[racetrack_p];

int nMapSize = 1024;
float fWorldX = 132.8;
float fWorldY = 651.5;
float fWorldAngle = 3.141592 / 2.0;  // pi/2
float fNear = nMapSize * 0.025;
float fFar = nMapSize * 0.60;
float fFoVHalf = 3.141592 / 4.0;  //180 degrees divided by four = 45 degrees. De FOV = 90, so start = -45 degrees, end = +45 degrees.
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

	asm data {loopStartTicks dq 0}
	g.[loopStartTicks] = sdl2.SDL_GetTicks();

	for (int y = 0; y < g.GC_Screen_DimY; y++) {
		float distance = space_y * scale_y / (y + horizon);
		float fStartX = fWorldX + (msvcrt.cos(fWorldAngle + fFoVHalf) * distance);
		float fStartY = fWorldY - (msvcrt.sin(fWorldAngle + fFoVHalf) * distance);
		float fEndX = fWorldX + (msvcrt.cos(fWorldAngle - fFoVHalf) * distance);
		float fEndY = fWorldY - (msvcrt.sin(fWorldAngle - fFoVHalf) * distance);

		for (int x = 0; x < g.GC_Screen_DimX; x++) {

			//float fSampleWidth = x / float_ScreenDIMx;
			float fSampleWidth;
			asm {
				mov	rax, [x@main]
				cvtsi2sd xmm0, rax
				movq  xmm1, qword [float_960]
				divsd xmm0, xmm1
				movq [fSampleWidth@main], xmm0
			}

			//float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleX;
			asm {
				movq xmm2, [fStartX@main]
				movq xmm1, [fEndX@main]
				subsd xmm1, xmm2
				movq xmm0, [fSampleWidth@main]
				mulsd xmm0, xmm1
				addsd xmm0, xmm2
				movq [fSampleX@main], xmm0
			}

			//float fSampleY = fStartY + ((fEndY - fStartY) * fSampleWidth);
			float fSampleY;
			asm {
				movq xmm2, [fStartY@main]
				movq xmm1, [fEndY@main]
				subsd xmm1, xmm2
				movq xmm0, [fSampleWidth@main]
				mulsd xmm0, xmm1
				addsd xmm0, xmm2
				movq [fSampleY@main], xmm0
			}

			int iSampleX = fSampleX;
			int iSampleY = fSampleY;
			u32 pixelColor = 0;

			//if ((iSampleX >= 0) and (iSampleX < 1024) and (iSampleY >= 0) and (iSampleY < 1024)) {
			//	pixelColor = racetrack[iSampleX, iSampleY];
			//}
			asm {
				mov	edx, [pixelColor@main]
				mov	rax, [iSampleX@main]
				cmp	rax, 0
				jl	.pixelColorExit
				cmp	rax, 1024
				jge	.pixelColorExit
				mov	rax, [iSampleY@main]
				cmp	rax, 0
				jl	.pixelColorExit
				cmp	rax, 1024
				jge	.pixelColorExit

				mov	rcx, [racetrack_p]
				mov	rax, [iSampleY@main]
				shl	rax, 10
				add rax, [iSampleX@main]
				mov	edx, [rcx+rax*4]
.pixelColorExit:
				mov	[pixelColor@main], edx
			}

			pixels[x, y] = pixelColor;
		}
	}

	int currentTicks = sdl2.SDL_GetTicks() - g.[loopStartTicks];
	if (currentTicks < g.[debugBestTicks]) {
		g.[debugBestTicks] = currentTicks;
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
