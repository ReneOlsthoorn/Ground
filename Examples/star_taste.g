// Come Taste The Stars

#template sdl3

#include graphics_defines1280x720.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#library user32 user32.dll
#library sidelib GroundSideLibrary.dll

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

asm data {texture_p dq 0}
g.[texture_p] = sidelib.LoadImage("image/come_taste_the_stars.png");
if (g.[texture_p] == null) { user32.MessageBox(null, "Image not found!", "Message", g.MB_OK); return; }
sidelib.FlipRedAndGreenInImage(g.[texture_p], 1024, 1024);
u32[1024,1024] ThePicture = g.[texture_p];

int arraySize = SCREEN_WIDTH * SCREEN_HEIGHT * 8 * 2;
int[] precalcValues = msvcrt.calloc(1, arraySize);


class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return (65536 * this.red) + (256 * this.green) + this.blue;
    }
}

class Vector2d {
	float x;
	float y;
	function Subtract(int x2, int y2) {
		this.x = x2 - this.x;
		this.y = y2 - this.y;
	}
	function Length() : float {
		float mult = (this.x * this.x)+(this.y * this.y);
		float result = msvcrt.sqrt(mult);
		return result;
	}
}

function validRadian(float radian) : float {
	float valid = radian;
	while (valid > 6.283185307) {
		valid = valid - 6.283185307;
	}
	while (valid < 0.0) {
		valid = valid + 6.283185307;
	}
	return valid;
}

u32[512] palette = [];
for (int i = 0; i < 512; i++) {
	ColorRGB color;
    color.red = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 128.0))));
    color.green = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 256.0))));
    color.blue = 128.0 + (127.0 * msvcrt.sin(validRadian(6.283185307 * (i / 512.0))));
    palette[i] = color.ToInteger();
}

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Come Taste The Stars", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

int frameCount = 0;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[128] event = [];
u32* eventType = &event[0];
u32* eventScancode = &event[24];
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int pitch = SCREEN_LINESIZE;
bool thread1Busy = false;
bool thread2Busy = false;
int offsetCounter = 0;


function Precalc_loop(int y) {
    Vector2d vect = Vector2d(0, SCREEN_HEIGHT_D2 - y);
	for (x in 0 ..< SCREEN_WIDTH) {
		vect.x = SCREEN_WIDTH_D2 - x;
		float length = vect.Length();

		float radAngle = msvcrt.atan2(vect.y, vect.x);
		float anglePosition = (validRadian(radAngle) * 512.0) / 3.141592;

		float distance = (100.0 * 200.0) / (( length * 0.4 ) + 20.0);
		int dist = distance;
		int anglePosInt = anglePosition + 1024;

		int index = y * SCREEN_WIDTH * 2;
		index = index + (x*2);
		precalcValues[index] = dist;
		precalcValues[index+1] = anglePosInt;
	}
}

bool gotoSun = false;


function Draw_loop(int y) {
	int index = y * SCREEN_WIDTH * 2;
	u32* pixelBase = &pixels[0, y];
	int pictureOffsetX = frameCount << 1;
	int pictureOffsetY = offsetCounter;

	for (x in 0 ..< SCREEN_WIDTH) {
		int dist = precalcValues[index];
		int anglePosInt = precalcValues[index+1];

		int posX = (anglePosInt + pictureOffsetX) and 0x3ff;
		int posY = (dist + pictureOffsetY);
		if (gotoSun) {
			if (posY > 1023)
				posY = 1023;
		} else {
			if (posY > 888)
				posY = posY - 888;
		}
		
		if (!gotoSun) {
			if (dist > 888)
				*pixelBase = 0xff000000;
			else
				*pixelBase = ThePicture[posX, posY];
		}
		else
			*pixelBase = ThePicture[posX, posY];

		index = index + 2;
		pixelBase = pixelBase + 4;
	}
}

for (int y = 0; y < SCREEN_HEIGHT; y++)
	Precalc_loop(y);


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 2.0, 2.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+0.5, y+0.5, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xe0, 0xe0, 0xe0);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function PreSunFase1() {
	if (frameCount > 500 and frameCount < 800)
		writeText(renderer, 125.0, 174.0, "         Flying through Space is a Bliss       ");
}
function PreSunFase2() {
	if (frameCount > 1800 and frameCount < 2100)
		writeText(renderer, 125.0, 174.0, "              You feel the Eternity            ");
}
function PreSunFase3() {
	if (frameCount > 3200 and frameCount < 3240)
		writeText(renderer, 125.0, 174.0, "                       Ai..                    ");

	if (frameCount > 3340)
		StatusRunning = false;
}

function RenderTexts() {
	PreSunFase1();
	PreSunFase2();
	PreSunFase3();
}

function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
			for (int y = (SCREEN_HEIGHT / 2); y < SCREEN_HEIGHT; y++)
				Draw_loop(y);
			thread2Busy = false;
		}
	}
}
ptr thread2Handle = GC_CreateThread(Thread2);
kernel32.SetThreadPriority(thread2Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

//frameCount = 3*888;  // speed up seeing the sun.
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;
		if (*eventType == g.SDL_EVENT_KEY_DOWN)
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;
	loopStartTicks = sdl3.SDL_GetTicks();

	if (thread1Busy) {
		for (y = 0; y < (SCREEN_HEIGHT / 2); y++)
			Draw_loop(y);
		thread1Busy = false;
	}
	while (thread2Busy) { }

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;
	sdl3.SDL_UnlockTexture(texture);

	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	RenderTexts();

	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
	offsetCounter = offsetCounter + 4;
	if (!gotoSun) {
		if (offsetCounter >= 888) {
			offsetCounter = offsetCounter - 888;
			if (frameCount >= 2700)
				gotoSun = true;
		}
	} else {
		if (offsetCounter > 1023)
			offsetCounter = 1023;
	}
}

while (thread2Busy) { }

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

msvcrt.free(precalcValues);
sidelib.FreeImage(g.[texture_p]);

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
