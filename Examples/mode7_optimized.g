//Mode7 example. See here the proof that depth is a division and that some statements in the innerloop code can be replaced by x86-64.
//This version is optimized. The innerloop runs in 2ms on my PC.

#template sdl3

#include graphics_defines960x560.g
#library sdl3 sdl3.dll SDL3
#library sdl3_image sdl3_image.dll SDL3_image

#linux   #include clib.g
#linux   #dllalias cruntime clib
#windows #include msvcrt.g
#windows #dllalias cruntime msvcrt

#define MAP_SIZE 1024

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Mode 7 optimized", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, null);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

int frameCount = 0;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_KEYBOARDEVENT_TYPE_U32];
u32* eventScancode = &event[SDL3_KEYBOARDEVENT_SCANCODE_U32];
bool StatusRunning = true;
bool thread1Busy = false;
bool thread2Busy = false;
int nMapSize = 1024;
float fWorldX = 132.8;
float fWorldY = 651.5;
float fWorldAngle = 3.141592 / 2.0;		// pi/2
float fNear = nMapSize * 0.025;
float fFar = nMapSize * 0.60;
float fFoVHalf = 3.141592 / 4.0;		// 180 degrees divided by four = 45 degrees. De FOV = 90, so start = -45 degrees, end = +45 degrees.
float space_y = 100.0;
float scale_y = 200.0;
int horizon = 15;
float float_ScreenDIMx = 960.0;
int pitch = SCREEN_LINESIZE;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
asm data {racetrack_p dq 0}


ptr surface = sdl3_image.IMG_Load("image/playfield1024.png");
if (surface == null) { sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_ERROR, "Error", "The file cannot be found!", null); return; }
SDL_Surface* convertedSurface = sdl3.SDL_ConvertSurface(surface, g.SDL_PIXELFORMAT_ARGB8888);
ptr surfacePixels = *convertedSurface.pixels;
g.[racetrack_p] = surfacePixels;
u32[MAP_SIZE, MAP_SIZE] racetrack = g.[racetrack_p];


function Innerloop(int pStartY, int pEndY, ptr myPixel_p) {
	for (int y = pStartY; y < pEndY; y++) {
		float distance = space_y * scale_y / (y + horizon);
		float fStartX = fWorldX + (cruntime.cos(fWorldAngle + fFoVHalf) * distance);
		float fStartY = fWorldY - (cruntime.sin(fWorldAngle + fFoVHalf) * distance);
		float fEndX = fWorldX + (cruntime.cos(fWorldAngle - fFoVHalf) * distance);
		float fEndY = fWorldY - (cruntime.sin(fWorldAngle - fFoVHalf) * distance);

		for (int x = 0; x < SCREEN_WIDTH; x++) {

			//float fSampleWidth = x / SCREEN_WIDTH_F;
			float fSampleWidth;
			asm {
				mov	rax, [x@Innerloop]
				cvtsi2sd xmm0, rax
				movq  xmm1, qword [f64_960]
				divsd xmm0, xmm1
				movq [fSampleWidth@Innerloop], xmm0
			}

			//float fSampleX = fStartX + ((fEndX - fStartX) * fSampleWidth);
			float fSampleX;
			asm {
				movq xmm2, [fStartX@Innerloop]
				movq xmm1, [fEndX@Innerloop]
				subsd xmm1, xmm2
				movq xmm0, [fSampleWidth@Innerloop]
				mulsd xmm0, xmm1
				addsd xmm0, xmm2
				movq [fSampleX@Innerloop], xmm0
			}

			//float fSampleY = fStartY + ((fEndY - fStartY) * fSampleWidth);
			float fSampleY;
			asm {
				movq xmm2, [fStartY@Innerloop]
				movq xmm1, [fEndY@Innerloop]
				subsd xmm1, xmm2
				movq xmm0, [fSampleWidth@Innerloop]
				mulsd xmm0, xmm1
				addsd xmm0, xmm2
				movq [fSampleY@Innerloop], xmm0
			}

			int iSampleX = fSampleX;
			int iSampleY = fSampleY;
			u32 pixelColor = 0xff000000;

			//if ((iSampleX >= 0) and (iSampleX < 1024) and (iSampleY >= 0) and (iSampleY < 1024)) {
			//	pixelColor = racetrack[iSampleX, iSampleY];
			//}
			asm {
				mov	edx, [pixelColor@Innerloop]
				mov	rax, [iSampleX@Innerloop]
				cmp	rax, 0
				jl	.pixelColorExit
				cmp	rax, 1024
				jge	.pixelColorExit
				mov	rax, [iSampleY@Innerloop]
				cmp	rax, 0
				jl	.pixelColorExit
				cmp	rax, 1024
				jge	.pixelColorExit

				mov	rcx, [racetrack_p]
				mov	rax, [iSampleY@Innerloop]
				shl	rax, 10
				add rax, [iSampleX@Innerloop]
				mov	edx, [rcx+rax*4]
.pixelColorExit:
				mov	[pixelColor@Innerloop], edx
			}

			//pixels[x, y] = pixelColor;
			asm {
				mov	edx, [pixelColor@Innerloop]
				mov rax, [myPixel_p@Innerloop]
				mov [rax], edx
				add	rax, 4
				mov	[myPixel_p@Innerloop], rax
			}
		}
	}
}

function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
			int halfHeight = SCREEN_HEIGHT / 2;
			ptr threadPixel_p = g.[pixels_p]+(SCREEN_WIDTH * halfHeight * SCREEN_PIXELSIZE);
            Innerloop(halfHeight, SCREEN_HEIGHT, threadPixel_p);
			thread2Busy = false;
		}
	}
}


#windows  GC_CreateThread(Thread2);
#linux    GC_Clone(Thread2);

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
	thread2Busy = StatusRunning;

	if (thread1Busy) {
		loopStartTicks = sdl3.SDL_GetTicks();
		ptr threadPixel_p = g.[pixels_p];
		int halfHeight = SCREEN_HEIGHT / 2;
		Innerloop(0, halfHeight, threadPixel_p);
		thread1Busy = false;
	}
	while (thread2Busy) { }

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks) {
		debugBestTicks = currentTicks;
	}

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
	fWorldY = fWorldY - 0.3;
	fWorldAngle = fWorldAngle - 0.001;

	if (frameCount > 1000) {
		fWorldAngle = 3.141592 / 2.0;
		fWorldY = 551.5;
		frameCount = 1;
	}
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

sdl3.SDL_DestroySurface(convertedSurface);
sdl3.SDL_DestroySurface(surface);


//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_INFORMATION, "Info", showStr, null);
