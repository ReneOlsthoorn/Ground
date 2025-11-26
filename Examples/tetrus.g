
#template sdl3

#define GRID_ELEMENTS_X 10
#define GRID_ELEMENTS_Y 19
#define GRID_ELEMENT_PIXELS 24
#define GRID_ELEMENT_PIXELS_KERN 22
#define GRID_POSY_OFFSET 52
#define KEYSTROKE_LEFT 1
#define KEYSTROKE_RIGHT 2
#define KEYSTROKE_UP 3
#define KEYSTROKE_SPACE 4
#define MAX_KSTACK 4

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#library user32 user32.dll
#library sidelib GroundSideLibrary.dll
#library soloud soloud_x64.dll
#library mikmod libmikmod-3.dll

//   The x,y of every point of every puzzle figure. The first 4 are the initial shape, the others are the rotated variants.
int[32,7] figures = [
    4,1, 5,1, 4,2, 5,2,  4,1, 5,1, 4,2, 5,2,  4,1, 5,1, 4,2, 5,2,  4,1, 5,1, 4,2, 5,2,  // O
    3,1, 4,1, 5,1, 6,1,  4,0, 4,1, 4,2, 4,3,  3,1, 4,1, 5,1, 6,1,  4,0, 4,1, 4,2, 4,3,  // I
    3,1, 4,1, 4,2, 5,2,  4,0, 4,1, 3,1, 3,2,  3,1, 4,1, 4,2, 5,2,  4,0, 4,1, 3,1, 3,2,  // Z
    4,1, 5,1, 3,2, 4,2,  4,1, 4,2, 3,1, 3,0,  4,1, 5,1, 3,2, 4,2,  4,1, 4,2, 3,1, 3,0,  // S
	3,1, 4,1, 5,1, 3,2,  4,0, 4,1, 3,0, 4,2,  5,0, 3,1, 4,1, 5,1,  4,0, 4,1, 4,2, 5,2,  // L
	3,1, 4,1, 5,1, 5,2,  4,0, 4,1, 3,2, 4,2,  3,0, 3,1, 4,1, 5,1,  4,0, 4,1, 4,2, 5,0,  // J
	3,1, 4,1, 5,1, 4,2,  4,0, 3,1, 4,1, 4,2,  4,0, 3,1, 4,1, 5,1,  4,0, 4,1, 5,1, 4,2   // T
] asm;

//   Colors of the figures.
u32[8] fgColorList = [ 0xff3D3D3C, 0xFF953692, 0xFFFEF74E, 0xFF51E1FC, 0xFFEA3D1D, 0xFF79AE3C, 0xFFF69431, 0xFFF16FB9 ];
u32[8] bgColorList = [ 0xff7B7B7B, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB ];


int[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
string gameStatus = "intro screen";    // "intro screen", "game running", "game over", "game finished"
bool StatusRunning = true;
int frameCount = 0;
int waitCount = 30;			//after how many frames a game 'tick' will occur.
int framesWaited = 0;
int framesKeyRepeat = 0;
bool downPressedForThisPiece = false;
int[6] keyboardStack = [ ] asm;
int keyboardStackNeedle = 0;
bool keyHitThisFrame = false;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_KEYBOARDEVENT_TYPE_U32];
u32* eventScancode = &event[SDL3_KEYBOARDEVENT_SCANCODE_U32];
u8* eventRepeat = &event[SDL3_KEYBOARDEVENT_REPEAT_U8];
int activeFigureIndex;
int activeFigureColor = 0;
int activeFigureVertical = 0;
int activeFigureHorizontal = 0;
int dx = 0;
int rotateState = 0;  // 0,1,2,3
int rotateDelta = 0;
int linesToComplete = 30;
int linesDoneCounter = 0;
int gameTimeFrameStart;
int secondsGameTime;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int screenpitch = SCREEN_LINESIZE;
int RandomSeed = 123123;    //msvcrt.time64(&RandomSeed);
class Point {
	int x;
	int y;
}
Point[4] activeFigure = [];	//active figure on screen with 4 points.
Point[4] oldFigure = [];	//backup copy of figureActive when performing rotation, etc...


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Tetrus", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();
sdl3.SDL_srand(RandomSeed);


ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr sfxrObject = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(sfxrObject, "sound/sfxr/explosion4.sfs");
if (sfxrLoaded != 0) return;
ptr dropObject = soloud.Sfxr_create();
int dropLoaded = soloud.Sfxr_loadParams(dropObject, "sound/sfxr/hit3.sfs");
if (dropLoaded != 0) return;
ptr sfxrSelectObject = soloud.Sfxr_create();
int sfxrSelectLoaded = soloud.Sfxr_loadParams(sfxrSelectObject, "sound/sfxr/select.sfs");
if (sfxrSelectLoaded != 0) return;

f32 theVolume = 1.0;
soloud.Sfxr_setVolume(sfxrObject, theVolume);
soloud.Sfxr_setVolume(dropObject, theVolume);
theVolume = 0.5;
soloud.Sfxr_setVolume(sfxrSelectObject, theVolume);
soloud.Sfxr_setLooping(sfxrObject, false);

function playSound() { soloud.Soloud_play(soloudObject, sfxrObject); }
function playDrop() { soloud.Soloud_play(soloudObject, dropObject); }
function playTurn() { soloud.Soloud_play(soloudObject, sfxrSelectObject); }

function writeText(ptr renderer, float x, float y, string text) {
	f32 scale = 3.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	f32 theX = x;
	f32 theY = y;
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX+2.0, theY, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
}

function ScreenPointerForXY(int x, int y) : ptr {	
	ptr result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}

function FillGridElementPixels(pointer p, u32 color) asm {
  push	rdi
  mov   rdi, [p@FillGridElementPixels]
  mov   rax, [color@FillGridElementPixels]
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_SCREEN_PIXELSIZE
  inc   rcx
  cmp	rcx, GC_GRID_ELEMENT_PIXELS
  jne	.loop
  pop	rdi
}


function FillGridElementBody(pointer p, u32 fgColor, u32 bgColor) asm {
  push	rdi
  mov   rdi, [p@FillGridElementBody]
  mov   rax, [fgColor@FillGridElementBody]
  mov   rdx, [bgColor@FillGridElementBody]
  mov	[rdi], edx
  add	rdi, GC_SCREEN_PIXELSIZE
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_SCREEN_PIXELSIZE
  inc   rcx
  cmp	rcx, GC_GRID_ELEMENT_PIXELS_KERN
  jne	.loop
  mov	[rdi], edx
  pop	rdi
}


function DrawGridElement(int x, int y, int shape) {
	u32 fgColor = fgColorList[shape];
	u32 bgColor = bgColorList[shape];

	int spelVlakXOffset = (SCREEN_WIDTH - (GRID_ELEMENTS_X * GRID_ELEMENT_PIXELS)) / 2;
	pointer p = &pixels[(x * GRID_ELEMENT_PIXELS)+spelVlakXOffset, (y * GRID_ELEMENT_PIXELS) + GRID_POSY_OFFSET];
	int offsetToNextLine = SCREEN_WIDTH << 2;

	FillGridElementPixels(p, bgColor);
	p = p + offsetToNextLine;
	for (i in 0..< GRID_ELEMENT_PIXELS_KERN) {
		FillGridElementBody(p, fgColor, bgColor);
		p = p + offsetToNextLine;
	}
	FillGridElementPixels(p, bgColor);
}


function FillHorizontal(int y, int nrLines, u32 color) {
	u32* p = ScreenPointerForXY(0, y);
	for (i in 0..< (SCREEN_WIDTH * nrLines)) { p[i] = color; }
}


function DrawBoard() {
	for (i in 0 ..< 4)
		board[activeFigure[i].x, activeFigure[i].y] = activeFigureColor;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			DrawGridElement(x,y, board[x,y]);

	for (i in 0 ..< 4)
		board[activeFigure[i].x, activeFigure[i].y] = 0;
}


function ClearBoard() {
	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			board[x,y] = 0;
}


function CollisionStatus() : int {
	for (i in 0..< 4) {
		if (activeFigure[i].x < 0)
			return -1;
		if (activeFigure[i].x >= GRID_ELEMENTS_X)
			return -2;
		if (activeFigure[i].y >= GRID_ELEMENTS_Y)
			return -3;
		if (board[activeFigure[i].x, activeFigure[i].y] > 0)
			return -4;
	}
	return 1;
}


function CheckChangeDirection() {
	dx = 0;
	rotateDelta = 0;

	if (keyboardStackNeedle == 0) { return; }

	int gewensteRichting = keyboardStack[0];
	if (gewensteRichting == KEYSTROKE_LEFT)	 { dx = -1; }
	if (gewensteRichting == KEYSTROKE_RIGHT) { dx = 1; }
	if (gewensteRichting == KEYSTROKE_UP)    { rotateDelta = 1; playTurn(); }
	if (gewensteRichting == KEYSTROKE_SPACE) { rotateDelta = 1; playTurn(); }

	for (i in 1..keyboardStackNeedle) {
		keyboardStack[i-1] = keyboardStack[i];
	}
	keyboardStackNeedle = keyboardStackNeedle - 1;
}


function GenerateNewPiece() {
	int n = sdl3.SDL_rand_r(&RandomSeed, 7);
	activeFigureIndex = n;
	activeFigureColor = n+1;
	activeFigureVertical = 0;
	activeFigureHorizontal = 0;
	rotateState = 0;

	for (i in 0 ..< 4) {
		activeFigure[i].x = figures[(i*2), n];
	    activeFigure[i].y = figures[(i*2)+1, n];
	}
}

int oldFigureHorizontal;
function CopyActiveToOld() {
	for (i in 0 ..< 4) {
		oldFigure[i].x = activeFigure[i].x;
		oldFigure[i].y = activeFigure[i].y;
	}
	oldFigureHorizontal = activeFigureHorizontal;
}
function CopyOldToActive() {
	for (i in 0 ..< 4) {
		activeFigure[i].x = oldFigure[i].x;
		activeFigure[i].y = oldFigure[i].y;
	}
	activeFigureHorizontal = oldFigureHorizontal;
}

function ChangeRotateState(int delta) {
	rotateState = rotateState + delta;
	if (rotateState > 3)
		rotateState = rotateState - 4;
	else if (rotateState < 0)
		rotateState = rotateState + 4;
}

function Rotate() {
	ChangeRotateState(1);
	if (activeFigureIndex == 0)
		return;
	CopyActiveToOld();
	for (i in 0 ..< 4) {
		activeFigure[i].x = figures[(rotateState*8)+(i*2), activeFigureIndex] + activeFigureHorizontal;
		activeFigure[i].y = figures[(rotateState*8)+(i*2)+1, activeFigureIndex] + activeFigureVertical;
	}
	int collStatus = CollisionStatus();
	if (collStatus < 0) {
		CopyOldToActive();
		ChangeRotateState(-1);
	}
}


function CheckLines() {
	// These loops will collapse all filled lines.
	// It does this by copying the entire field from bottom to top and
	// at the same time NOT lowering the destination counter when the entire line is occupied.
    int k = GRID_ELEMENTS_Y - 1;
	for (int y = GRID_ELEMENTS_Y - 1; y > 0; y--)
	{
		int count = 0;
		for (x in 0 ..< GRID_ELEMENTS_X) {
		    if (board[x,y] > 0)
				count++;
		    board[x,k] = board[x,y];
		}
		if (count < GRID_ELEMENTS_X)
			k--;
		else {
			linesDoneCounter = linesDoneCounter + 1;
			playSound();
			if (linesDoneCounter == linesToComplete) {
				gameStatus = "game finished";
				return;
			}				
		}
	}
}


function MovePiece() {
	CopyActiveToOld();
	CheckChangeDirection();

	if (rotateDelta != 0)
		Rotate();

	for (i in 0 ..< 4)
		activeFigure[i].x = activeFigure[i].x + dx;
	activeFigureHorizontal = activeFigureHorizontal + dx;

	if (CollisionStatus() < 0)
		CopyOldToActive();

	if (framesWaited < waitCount) { return; }
	framesWaited = 0;

	for (i in 0 ..< 4)
		activeFigure[i].y = activeFigure[i].y + 1;
	activeFigureVertical = activeFigureVertical + 1;

	if (CollisionStatus() < 0)
	{
		for (i in 0 ..< 4) { board[oldFigure[i].x, oldFigure[i].y] = activeFigureColor; }

		waitCount = 30;
		downPressedForThisPiece = false;
		playDrop();
		GenerateNewPiece();

		if (CollisionStatus() < 0) {
			gameStatus = "game over";
			return;
		}
	}
	CheckLines();
}


function IntroScreenInformation() {
	writeText(renderer, 60.0, 70.0, ("  Try to fully fill " + linesToComplete));
	writeText(renderer, 60.0, 80.0, "    horizontal lines.");
	writeText(renderer, 60.0, 110.0, " Press [space] to start.");
}

function GameOverInformation() {
	writeText(renderer, 60.0, 50.0, "   *** Game over ***");
	writeText(renderer, 60.0, 70.0, "  You needed " + linesToComplete + " lines.");
	writeText(renderer, 60.0, 80.0, "  You have done " + linesDoneCounter + " lines.");
	writeText(renderer, 60.0, 130.0, "Press [space] to restart");
}

function GameFinishedInformation() {
	writeText(renderer, 70.0, 50.0, "***  Game Completed! ***");
	writeText(renderer, 70.0, 70.0, "You solved " + linesToComplete + " lines");
	writeText(renderer, 70.0, 80.0, "in " + secondsGameTime + " seconds!");
	writeText(renderer, 70.0, 130.0, "Press [space] to restart.");
}

function GameRunningInformation() {
	writeText(renderer, 5.0, 40.0, "Remaining");
	writeText(renderer, 5.0, 50.0, "lines: " + (linesToComplete - linesDoneCounter));
	writeText(renderer, 5.0, 70.0, "Time");
	secondsGameTime = (frameCount - gameTimeFrameStart) / 60;
	writeText(renderer, 5.0, 80.0, "elapsed: " + secondsGameTime);
}


function RestartGame() {
	gameStatus = "game running";
	waitCount = 30;
	ClearBoard();
	GenerateNewPiece();
	linesDoneCounter = 0;
	gameTimeFrameStart = frameCount;
}
RestartGame();
gameStatus = "intro screen";

#include soundtracker.g
SoundtrackerInit("sound/mod/tip - princess of dawn.mod", 50);

//   MAINLOOP
while (StatusRunning)
{
	SoundtrackerUpdate();
	u8* keyState = sdl3.SDL_GetKeyboardState(null);

	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN && *eventRepeat == 0) {
			if (*eventScancode == g.SDL_SCANCODE_LEFT)  { keyHitThisFrame = true; keyboardStack[keyboardStackNeedle] = KEYSTROKE_LEFT; if (keyboardStackNeedle < MAX_KSTACK) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_RIGHT) { keyHitThisFrame = true; keyboardStack[keyboardStackNeedle] = KEYSTROKE_RIGHT; if (keyboardStackNeedle < MAX_KSTACK) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_UP)    { keyboardStack[keyboardStackNeedle] = KEYSTROKE_UP; if (keyboardStackNeedle < MAX_KSTACK) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen")
						gameStatus = "game running";
					else
						RestartGame();
				} else {
					keyboardStack[keyboardStackNeedle] = KEYSTROKE_SPACE;
					if (keyboardStackNeedle < MAX_KSTACK)
						keyboardStackNeedle++;
				}
			}
			if (*eventScancode == g.SDL_SCANCODE_DOWN)  { waitCount = 3; downPressedForThisPiece = true; }
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
		if (*eventType == g.SDL_EVENT_KEY_UP && *eventScancode == g.SDL_SCANCODE_DOWN)
			waitCount = 30;
	}

	if (keyState[g.SDL_SCANCODE_RIGHT] or keyState[g.SDL_SCANCODE_LEFT]) {
		waitCount = 30;
	}

	if (framesKeyRepeat >= 7) {
		framesKeyRepeat = 0;
		if (keyHitThisFrame == false) {
			if (keyState[g.SDL_SCANCODE_DOWN] and !keyState[g.SDL_SCANCODE_LEFT] and !keyState[g.SDL_SCANCODE_RIGHT] and downPressedForThisPiece) {
				waitCount = 3;
			}
			if (keyState[g.SDL_SCANCODE_LEFT]) { keyboardStack[keyboardStackNeedle] = KEYSTROKE_LEFT; if (keyboardStackNeedle < MAX_KSTACK) { keyboardStackNeedle++; } }
			if (keyState[g.SDL_SCANCODE_RIGHT]) { keyboardStack[keyboardStackNeedle] = KEYSTROKE_RIGHT; if (keyboardStackNeedle < MAX_KSTACK) { keyboardStackNeedle++; } }
		}
		keyHitThisFrame = false;
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	if (gameStatus == "game running") { MovePiece(); }

	SDL3_ClearScreenPixels(0xff000000);
	DrawBoard();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (gameStatus == "intro screen") IntroScreenInformation();
	else if (gameStatus == "game over") GameOverInformation();
	else if (gameStatus == "game finished") GameFinishedInformation();
	else if (gameStatus == "game running") GameRunningInformation();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
	framesWaited++;
	framesKeyRepeat++;
}
soloud.Sfxr_destroy(sfxrSelectObject);
soloud.Sfxr_destroy(sfxrObject);
soloud.Sfxr_destroy(dropObject);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);
SoundtrackerFree();

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
