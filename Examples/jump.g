
#template sdl3

#library user32 user32.dll
#library sidelib GroundSideLibrary.dll
#library soloud soloud_x64.dll
#library mikmod libmikmod-3.dll

#define BERTUS_WIDTH 24
#define BERTUS_WIDTH_D2 12
#define BERTUS_HEIGHT 32
#define PLATFORM_WIDTH 64
#define PLATFORM_WIDTH_D2 32
#define PLATFORM_HEIGHT 49
#define NR_PLATFORMS 12
#define PLATFORM_MARGIN_TOP 56
#define BERTUS_START_X 100
#define NUMBER_OF_STARS 700

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g


u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
u8* eventRepeat = &event[SDL3_KEYBOARDEVENT_REPEAT_U8];
int pitch = SCREEN_LINESIZE;
f32[4] srcRect = [];
f32[4] destRect = [];
int score = 0;
int[NR_PLATFORMS] platX = [] asm;
int[NR_PLATFORMS] platY = [] asm;
string gameStatus = "intro screen";    // "intro screen", "game running", "game over"

int SeedStarfield = 123123;
float[NUMBER_OF_STARS] star_x = []; //van -500 tot 500
float[NUMBER_OF_STARS] star_y = []; //van -500 tot 500
float[NUMBER_OF_STARS] star_z = []; //van 100 tot 1000
float[NUMBER_OF_STARS] star_zv = []; //speed: from .5 to 5
int[NUMBER_OF_STARS] star_screenx = [];
int[NUMBER_OF_STARS] star_screeny = [];
int bertusRandomSeed = 123123;
int x = BERTUS_START_X;
int y = 100;
int h = 200;
float dx = 0.0;
float dy = 0.0;


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.
sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Jump", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();
sdl3.SDL_srand(bertusRandomSeed);

// Loading images...
ptr tmpSurface = sdl3_image.IMG_Load("image/bertus24x32y.png");
if (tmpSurface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr bertusTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tmpSurface);
sdl3.SDL_SetTextureScaleMode(bertusTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(tmpSurface);

tmpSurface = sdl3_image.IMG_Load("image/bertus_jump24x32y.png");
ptr bertusJumpTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tmpSurface);
sdl3.SDL_SetTextureScaleMode(bertusJumpTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(tmpSurface);

tmpSurface = sdl3_image.IMG_Load("image/platform64x49y.png");
ptr platformTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tmpSurface);
sdl3.SDL_SetTextureScaleMode(platformTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(tmpSurface);

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

function playJump() { soloud.Soloud_play(soloudObject, jumpSfxr); }
function playFall() { soloud.Soloud_play(soloudObject, fallSfxr); }

f32 fontScale = 1.3;
function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, fontScale, fontScale);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+2.0, y, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function InitStarField()
{
	for (i in 0 ..< NUMBER_OF_STARS)
	{
		float starX = (sdl3.SDL_randf_r(&SeedStarfield) - 0.5) * 100.0;
		float starY = (sdl3.SDL_randf_r(&SeedStarfield) - 0.5) * 100.0;
		float starZ = (sdl3.SDL_randf_r(&SeedStarfield) * 900.0) + 100.0;
		float starZV = (sdl3.SDL_randf_r(&SeedStarfield) * 4.5) + 0.5;
		star_x[i] = starX;
		star_y[i] = starY;
		star_z[i] = starZ;
		star_zv[i] = starZV;
	}
}
InitStarField();

function SetPixel(int x, int y, u32 color)
{
	if ((x > SCREEN_WIDTH-5) or (x < 5) or (y > SCREEN_HEIGHT-5) or (y < 5))
		return;

	pixels[x,y] = color;
	pixels[x+1,y] = color;
	pixels[x,y+1] = color;
	pixels[x+1,y+1] = color;
}

function StarField()
{
	for (i in 0 ..< NUMBER_OF_STARS)
	{
		SetPixel(star_screenx[i], star_screeny[i], 0xff000000);
		star_z[i] = star_z[i] - star_zv[i];
		star_screenx[i] = ((star_x[i] / star_z[i]) * 6000.0) + SCREEN_WIDTH_D2_F;
		star_screeny[i] = ((star_y[i] / star_z[i]) * 4000.0) + SCREEN_HEIGHT_D2_F;

		int x = star_screenx[i];
		int y = star_screeny[i];

		int brightness = 255 - (star_z[i] * 0.255);
		u32 pixelColor = 0xff000000 or brightness or brightness << 8 or brightness << 16;
		SetPixel(x, y, pixelColor);

		if ((x > SCREEN_WIDTH-5) or (x < 5) or (y > SCREEN_HEIGHT-5) or (y < 5) or (star_z[i] < 0.0))
		{
			float starX = (sdl3.SDL_randf_r(&SeedStarfield) - 0.5) * 100.0;
			float starY = (sdl3.SDL_randf_r(&SeedStarfield) - 0.5) * 100.0;
			float starZ = (sdl3.SDL_randf_r(&SeedStarfield) + 0.1) * 900.0;
			star_x[i] = starX;
			star_y[i] = starY;
			star_z[i] = starZ;
		}
	}
}

function PrintScore() {
	fontScale = 1.3;
	string theScore = "Score: " + score;
	writeText(renderer, 5.0, 5.0, theScore);
}

function RestartGame() {
	bertusRandomSeed = 123123;
	score = 0;
	x = BERTUS_START_X;
	y = 100;
	h = 200;
	dx = 0.0;
	dy = 0.0;
	gameStatus = "game running";
	for (i in 0 ..< NR_PLATFORMS) {
		platX[i] = sdl3.SDL_rand_r(&bertusRandomSeed, SCREEN_WIDTH + 150);
		platY[i] = SCREEN_HEIGHT - ((i+1) * PLATFORM_MARGIN_TOP);

		// This is the start platform where Bertus is jumping on.
		if (i == 0)
			platX[i] = BERTUS_START_X - PLATFORM_WIDTH_D2 + BERTUS_WIDTH_D2;
	}
}

function IntroScreenInformation() {
	fontScale = 2.0;
	writeText(renderer, 100.0, 100.0, "Make Bertus jump on the platforms!");
	writeText(renderer, 100.0, 120.0, "    Use cursor keys to steer.");
	writeText(renderer, 100.0, 140.0, "     Press [space] to start.");
}

function GameOverInformation() {
	fontScale = 2.0;
	writeText(renderer, 140.0, 90.0,  "   *** Game over ***");
	writeText(renderer, 140.0, 110.0, "Bertus lost his Ground!");
	writeText(renderer, 140.0, 130.0, " Your score was " + score + ".");
	writeText(renderer, 140.0, 150.0, "Press [space] to restart.");
}

function DrawBertus(int x, int y, ptr theUsedTexture, float rotation) {
	destRect[0] = x;  destRect[1] = y; destRect[2] = BERTUS_WIDTH; destRect[3] = BERTUS_HEIGHT;
	sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	sdl3.SDL_RenderTextureRotated(renderer, theUsedTexture, null, destRect, rotation, null, g.SDL_FLIP_NONE);
}

#include soundtracker.g
SoundtrackerInit("sound/mod/mlp jeremias days today.mod", 30);

RestartGame();
gameStatus = "intro screen";

while (StatusRunning)
{
	SoundtrackerUpdate();

	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen") { 
						gameStatus = "game running";
					} else { 
						RestartGame();
					}
				}
			}
		}
	}

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (keyState[g.SDL_SCANCODE_UP]) { }
	if (keyState[g.SDL_SCANCODE_LEFT]) { x = x - 4; }
	if (keyState[g.SDL_SCANCODE_RIGHT]) { x = x + 4; }
	if (keyState[g.SDL_SCANCODE_DOWN]) { }

	if (gameStatus == "game running") {
		dy = dy + 0.2;
		y = y + dy;
		if (y > SCREEN_HEIGHT) {
			playFall();
			gameStatus = "game over";
		}
		if (y < h) {
			y = h;
			for (i in 0 ..< NR_PLATFORMS) {
				platY[i] = platY[i] - dy;
				score = score - (dy / 10);
				if (platY[i] > SCREEN_HEIGHT) {
					platY[i] = platY[i] - (SCREEN_HEIGHT + 2 * PLATFORM_MARGIN_TOP);
					platX[i] = sdl3.SDL_rand_r(&bertusRandomSeed, SCREEN_WIDTH + 150);
				}
			}
		}

		if (x < -BERTUS_WIDTH_D2)
			x = x + SCREEN_WIDTH;
		else if (x > ((SCREEN_WIDTH-1) - BERTUS_WIDTH_D2))
			x = x - SCREEN_WIDTH;

		for (i in 0 ..< NR_PLATFORMS) {
			if ((x > platX[i]-BERTUS_WIDTH) and (x < platX[i]+PLATFORM_WIDTH) and (y > platY[i]-BERTUS_HEIGHT) and (y < platY[i]+PLATFORM_HEIGHT-BERTUS_HEIGHT) and (dy > 0.0)) {
				playJump();
				dy = -10.5;
			}
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	SDL3_ClearScreenPixels(0xff000000);
	StarField();
	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (gameStatus == "game running") {
		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		for (i in 0 ..< NR_PLATFORMS) {
			if ((platX[i] < SCREEN_WIDTH - PLATFORM_WIDTH) and (platY[i] >= -PLATFORM_HEIGHT)) {
				destRect[0] = platX[i];  destRect[1] = platY[i]; destRect[2] = PLATFORM_WIDTH; destRect[3] = PLATFORM_HEIGHT;
				sdl3.SDL_RenderTextureRotated(renderer, platformTexture, null, destRect, 0.0, null, g.SDL_FLIP_NONE);
			}
		}

		ptr usedBertusTexture = bertusTexture;
		if (dy < -7.0)
			usedBertusTexture = bertusJumpTexture;

		DrawBertus(x, y, usedBertusTexture, 0.0);

		// When Bertus is at the edge of the screen, he must be painted twice, once half on the left, once half on the right of the screen.
		int secondDraw = 0;
		if (x > ((SCREEN_WIDTH-1) - BERTUS_WIDTH)) secondDraw = x-SCREEN_WIDTH;
		if ((x > -BERTUS_WIDTH_D2) and (x < 0)) secondDraw = x+SCREEN_WIDTH;
		if not (secondDraw == 0)
			DrawBertus(secondDraw, y, usedBertusTexture, 0.0);

		PrintScore();
	}

	if (gameStatus == "intro screen") {
		DrawBertus(315, 155, bertusTexture, 0.0);
		IntroScreenInformation();
	} else if (gameStatus == "game over") {
		DrawBertus(280, 170, bertusTexture, 180.0);
		GameOverInformation();
	}

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


soloud.Sfxr_destroy(jumpSfxr);
soloud.Sfxr_destroy(fallSfxr);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);
SoundtrackerFree();

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(bertusTexture);
sdl3.SDL_DestroyTexture(bertusJumpTexture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
