
#template sdl3

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll

u32[120, 100] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
int frameCount = 0;
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;

ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, KERNEL32_HIGH_PRIORITY_CLASS);
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Hexacubes", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); //null);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, 120, 100);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

#define NR_VERTICES 18
SDL_Vertex[NR_VERTICES] verts = [ ];

function SetVertexRGBA() {
	for (i in 0 ..< NR_VERTICES) {
		verts[i].red = 1.0;
		verts[i].green = 1.0;
		verts[i].blue = 1.0;
		verts[i].alpha = 1.0;
	}
}
SetVertexRGBA();

function SetVertexTex() {
	float start = 0.00;
	for (i in 0 ..< (NR_VERTICES / 3)) {
		int index = i*3;
		verts[index].texX = 0.0;
		verts[index].texY = start;
		start = start + 0.01;
		verts[index+1].texX = 0.0;
		verts[index+1].texY = start;
		verts[index+2].texX = 1.0;
		verts[index+2].texY = start;
	}
}
SetVertexTex();

function SetVertexPosition(int startX, int startY) {
	verts[0].posX = startX;
	verts[0].posY = startY + 100;
	verts[1].posX = startX;
	verts[1].posY = startY + 300;
	verts[2].posX = startX + 200;
	verts[2].posY = startY + 200;

	verts[3].posX = startX + 200;
	verts[3].posY = startY;
	verts[4].posX = startX;
	verts[4].posY = startY + 100;
	verts[5].posX = startX + 200;
	verts[5].posY = startY + 200;

	verts[6].posX = startX + 400;
	verts[6].posY = startY + 100;
	verts[7].posX = startX + 200;
	verts[7].posY = startY;
	verts[8].posX = startX + 200;
	verts[8].posY = startY + 200;

	verts[9].posX = startX + 400;
	verts[9].posY = startY + 300;
	verts[10].posX = startX + 400;
	verts[10].posY = startY + 100;
	verts[11].posX = startX + 200;
	verts[11].posY = startY + 200;

	verts[12].posX = startX + 200;
	verts[12].posY = startY + 400;
	verts[13].posX = startX + 400;
	verts[13].posY = startY + 300;
	verts[14].posX = startX + 200;
	verts[14].posY = startY + 200;

	verts[15].posX = startX;
	verts[15].posY = startY + 300;
	verts[16].posX = startX + 200;
	verts[16].posY = startY + 400;
	verts[17].posX = startX + 200;
	verts[17].posY = startY + 200;
}
SetVertexPosition(0, 0);

float textureOffset = 0.0;

function UpdateVertexTex() {
	verts[0].texX = 0.0 + textureOffset;
	verts[1].texX = 0.0 + textureOffset;
	verts[2].texX = 1.0 + textureOffset;

	verts[3].texX = 0.0 + textureOffset;
	verts[4].texX = 0.0 + textureOffset;
	verts[5].texX = 1.0 + textureOffset;

	verts[6].texX = 0.0 + textureOffset;
	verts[7].texX = 0.0 + textureOffset;
	verts[8].texX = 1.0 + textureOffset;

	verts[9].texX = 0.0 + textureOffset;
	verts[10].texX = 0.0 + textureOffset;
	verts[11].texX = 1.0 + textureOffset;

	verts[12].texX = 0.0 + textureOffset;
	verts[13].texX = 0.0 + textureOffset;
	verts[14].texX = 1.0 + textureOffset;

	verts[15].texX = 0.0 + textureOffset;
	verts[16].texX = 0.0 + textureOffset;
	verts[17].texX = 1.0 + textureOffset;
}

if (sizeof(SDL_Vertex) != 32)
	return;

function Init() {
	int part;
	for (x in 0..< 120) {
		part = x % 40;
		if (part >= 20) {
			pixels[x, 0] = 0xff989898;
			pixels[x, 1] = 0xffffffff;
			pixels[x, 2] = 0xffffffff;
			pixels[x, 3] = 0xff000000;
			pixels[x, 4] = 0xff000000;
			pixels[x, 5] = 0xff989898;
		}
		else {
			pixels[x, 0] = 0xff000000;
			pixels[x, 1] = 0xff000000;
			pixels[x, 2] = 0xff989898;
			pixels[x, 3] = 0xff989898;
			pixels[x, 4] = 0xffffffff;
			pixels[x, 5] = 0xffffffff;
		}
	}
}

sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
g.[pixels_p] = pixels;
Init();
sdl3.SDL_UnlockTexture(texture);

function RenderObjectLine(int startX, int startY) {
	SetVertexPosition(startX, startY);
    sdl3.SDL_RenderGeometry(renderer, texture, &verts, NR_VERTICES, null, 0);

	SetVertexPosition(startX+400, startY);
	sdl3.SDL_RenderGeometry(renderer, texture, &verts, NR_VERTICES, null, 0);

	SetVertexPosition(startX+800, startY);
	sdl3.SDL_RenderGeometry(renderer, texture, &verts, NR_VERTICES, null, 0);

	SetVertexPosition(startX+1200, startY);
	sdl3.SDL_RenderGeometry(renderer, texture, &verts, NR_VERTICES, null, 0);
}

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}
	loopStartTicks = sdl3.SDL_GetTicks();

    //sdl3.SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
    //sdl3.SDL_RenderClear(renderer);

	textureOffset = textureOffset + 0.002;
	if (textureOffset > 1.0)
		textureOffset = textureOffset - 1.0;
	UpdateVertexTex();

	RenderObjectLine(-200, -150);
	RenderObjectLine(0, 150);
	RenderObjectLine(-200, 450);

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
