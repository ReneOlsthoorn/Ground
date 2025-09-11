
#template sdl3

#define NR_BUGS 5

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include soloud.g

bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = g.GC_ScreenLineSize;
f32[4] srcRect = [];
f32[4] destRect = [];
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
string gameStatus = "intro screen";    // "intro screen", "game running", "next level", "game over"
int nextLevelCount = 0;
int RandomSeed = 123123;

function IsPointInCircle(float px, float py, float cx, float cy, float radius) : bool {
    float dx = px - cx;
    float dy = py - cy;
    bool result = (dx * dx + dy * dy) < (radius * radius);
	return result;
}

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Bugs", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
sdl3.SDL_SetRenderVSync(renderer, 1);

ptr surface = sdl3_image.IMG_Load("image/bugs_wood.jpg");
if (surface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr convertedSurface = sdl3.SDL_ConvertSurface(surface, g.SDL_PIXELFORMAT_ARGB8888);
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);

SDL_Surface* psurface = convertedSurface;
ptr surfacePixels = *psurface.pixels;
sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
sdl3.SDL_memcpy(pixels, surfacePixels, SCREEN_HEIGHT * SCREEN_WIDTH * SCREEN_PIXELSIZE);
//for (y in 0..< SCREEN_HEIGHT) {
//	for (x in 0..< SCREEN_WIDTH) {
//		if not (IsPointInCircle(x, y, 488.0, 285.0, 250.0))
//			pixels[x,y] = 0xffff0000;
//		else
//			if not (IsPointInCircle(x, y, 488.0, 285.0, 235.0))
//				pixels[x,y] = 0xffffff00;
//	}
//}
sdl3.SDL_UnlockTexture(texture);

// ptr texture = sdl3.SDL_CreateTextureFromSurface(renderer, convertedSurface);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
sdl3.SDL_DestroySurface(convertedSurface);

surface = sdl3_image.IMG_Load("image/bug.png");
ptr bugTexture = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
sdl3.SDL_SetTextureScaleMode(bugTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);
surface = sdl3_image.IMG_Load("image/bug2.png");
ptr bug2Texture = sdl3.SDL_CreateTextureFromSurface(renderer, surface);
sdl3.SDL_SetTextureScaleMode(bug2Texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(surface);


// Loading sounds...
ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr hurtSfxr = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(hurtSfxr, "sound/sfxr/hurt.sfs");
if (sfxrLoaded != 0) return;
ptr fallSfxr = soloud.Sfxr_create();
sfxrLoaded = soloud.Sfxr_loadParams(fallSfxr, "sound/sfxr/fall.sfs");
if (sfxrLoaded != 0) return;

function playHurt() { soloud.Soloud_play(soloudObject, hurtSfxr); }
function playFall() { soloud.Soloud_play(soloudObject, fallSfxr); }


class Actor {
	float x;
	float y;
	float rotation;
	float rotationSpeed;
	bool visible;

	function Spin() {
		this.rotation = this.rotation + this.rotationSpeed;
		if (this.rotation > 360.0)
			this.rotation = this.rotation - 360.0;
		else if (this.rotation < 0.0)
			this.rotation = this.rotation + 360.0;
	}

	function Move() {
		float r = 3.0;
		float angle_rad = this.rotation * (MATH_PI / 180.0);
		this.x = this.x + (r * sdl3.SDL_cos(angle_rad));
		this.y = this.y + (r * sdl3.SDL_sin(angle_rad));
	}

	function IsOutside() : bool {
		bool result = IsPointInCircle(this.x, this.y, 488.0, 285.0, 250.0);
		return !result;
	}

	function IsInWarningZone() : bool {
		bool result = IsPointInCircle(this.x, this.y, 488.0, 285.0, 225.0);
		return !result;
	}
}
Actor[NR_BUGS] bugs = [ ];

function RestartGame() {
	gameStatus = "game running";
	for (i in 0..< NR_BUGS) {
		bugs[i].x = ((sdl3.SDL_randf_r(&RandomSeed) - 0.5) * 330.0) + 488.0;
		bugs[i].y = ((sdl3.SDL_randf_r(&RandomSeed) - 0.5) * 330.0) + 285.0;
		bugs[i].rotation = sdl3.SDL_randf_r(&RandomSeed) * 360.0;
		float rand = (sdl3.SDL_randf_r(&RandomSeed) - 0.5) * 12.0;
		if (rand < 0.0)
			rand = rand - 3.0;
		else
			rand = rand + 3.0;
		bugs[i].rotationSpeed = rand;
		bugs[i].visible = true;
	}
}
RestartGame();
gameStatus = "intro screen";

int writeColor = 0;
function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 3.0, 4.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+0.5, y+0.5, text);
	if (writeColor == 1)
		sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0x00, 0x00, 0xff);
	else if (writeColor == 2)
		sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0x00, 0xff);
	else
		sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function IntroScreenInformation() {
	writeColor = 0;
	writeText(renderer, 60.0, 40.0, "Make the bugs eat eachother.");
	writeText(renderer, 10.0, 60.0, "Use Left Mousebutton to make them move.");
	writeText(renderer, 80.0, 80.0, "Press [space] to start.");
}

function GameOverInformation() {
	writeColor = 0;
	writeText(renderer, 60.0, 40.0, "    *** Game over ***");
	writeText(renderer, 60.0, 60.0, "      A Bug escaped!");
	writeText(renderer, 60.0, 80.0, " Press [space] to restart.");
}

function NextLevelInformation() {
	writeColor = 2;
	writeText(renderer, 60.0, 40.0, "      Level Completed!");
	writeText(renderer, 60.0, 60.0, "   Next level coming up...");
}

while (StatusRunning)
{
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
	if (keyState[g.SDL_SCANCODE_LEFT]) { }
	if (keyState[g.SDL_SCANCODE_RIGHT]) { }
	if (keyState[g.SDL_SCANCODE_DOWN]) { }

	bool mouseLeftPressed = false;
	bool mouseRightPressed = false;
	f32 mouseX;
	f32 mouseY;
	u32 mouseState = sdl3.SDL_GetMouseState(&mouseX, &mouseY);
	mouseLeftPressed = mouseState & g.SDL_BUTTON_LMASK;
	//mouseRightPressed = mouseState & g.SDL_BUTTON_RMASK;

	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	bool warningNeeded = false;

	if (gameStatus == "game running" or gameStatus == "next level") {
		ptr theBugTexture = bugTexture;
		int frameCountMod20 = frameCount % 20;
		if (frameCountMod20 > 10)
			theBugTexture = bug2Texture;

		for (i in 0..< NR_BUGS) {
			if (bugs[i].visible) {
				srcRect[0] = 0;  srcRect[1] = 0; srcRect[2] = 59; srcRect[3] = 63;
				destRect[0] = bugs[i].x-30;  destRect[1] = bugs[i].y-30; destRect[2] = 59; destRect[3] = 63;
				sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
				sdl3.SDL_RenderTextureRotated(renderer, theBugTexture, srcRect, destRect, bugs[i].rotation, null, g.SDL_FLIP_NONE);
				if (gameStatus != "next level") {
					if (mouseLeftPressed)
						bugs[i].Move();
					else
						bugs[i].Spin();
				}

				if (bugs[i].IsOutside()) {
					gameStatus = "game over";
					playFall();
				}

				if (bugs[i].IsInWarningZone())
					warningNeeded = true;

				for (j in 0..< NR_BUGS) {
					if (j != i and bugs[j].visible) {
						if (IsPointInCircle(bugs[j].x, bugs[j].y, bugs[i].x, bugs[i].y, 25.0)) {
							bugs[j].visible = false;
							playHurt();
						}
					}
				}
			}
		}
	}

	if (warningNeeded) {
		writeColor = 1;
		writeText(renderer, 5.0, 5.0,   "Bug on Edge!               Bug on Edge!");
		writeText(renderer, 5.0, 15.0,  "WARNING!                       WARNING!");
		writeText(renderer, 5.0, 115.0, "WARNING!                       WARNING!");
		writeText(renderer, 5.0, 125.0, "Bug on Edge!               Bug on Edge!");
	}

	if (gameStatus == "intro screen")
		IntroScreenInformation();

	if (gameStatus == "game over")
		GameOverInformation();

	if (gameStatus == "next level")
		NextLevelInformation();

	int aantalBugs = 0;
	for (i in 0..< NR_BUGS) {
		if (bugs[i].visible)
			aantalBugs = aantalBugs + 1;
	}
	if ((aantalBugs == 1 and gameStatus == "game running") or mouseRightPressed) {
		gameStatus = "next level";
		nextLevelCount = 0;
	}
	if (gameStatus == "next level") {
		nextLevelCount = nextLevelCount + 1;
		if (nextLevelCount == 180) {
			RestartGame();
		}
	}

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

soloud.Sfxr_destroy(hurtSfxr);
soloud.Sfxr_destroy(fallSfxr);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);

sdl3.SDL_DestroyTexture(bugTexture);
sdl3.SDL_DestroyTexture(bug2Texture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
