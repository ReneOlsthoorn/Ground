
#template sdl3

#define GRID_ELEMENTS_X 10
#define GRID_ELEMENTS_Y 20
#define GRID_ELEMENT_PIXELS 24
#define GRID_ELEMENT_PIXELS_KERN 22
#define GRID_POSY_OFFSET 4

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include soloud.g
#include tetrus_helper.g

class Point {
	int x;
	int y;
}
Point[4] activeFigure = [];  //active figure on screen with 4 points.
Point[4] oldFigure = [];     //backup copy of figureActive when performing rotation, etc...

int[4,7] figures = [
	2,3,4,5, // O
	1,3,5,7, // I
	3,5,4,6, // S
	2,4,5,7, // Z
	2,3,5,7, // L
	3,5,7,6, // J
	3,5,4,7  // T
] asm;
int activeFigureColor = 0;
int dx = 0;
int rotateDelta = 0;
int linesToComplete = 30;
int linesDoneCounter = 0;

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
int waitCount;				//integer which determines at which modulo of frameCount a game 'tick will occur.
string gameStatus = "intro screen";    // "intro screen", "game running", "game over", "game finished"
bool StatusRunning = true;
int frameCount = 0;
u32[8] fgColorList = [ 0xff3D3D3C, 0xFF953692, 0xFFFEF74E, 0xFF51E1FC, 0xFFEA3D1D, 0xFF79AE3C, 0xFFF69431, 0xFFF16FB9 ];
u32[8] bgColorList = [ 0xff7B7B7B, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB ];
int[6] keyboardStack = [ ] asm;
int keyboardStackNeedle = 0;
bool keyHitThisFrame = false;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_KEYBOARDEVENT_TYPE_U32];
u32* eventScancode = &event[SDL3_KEYBOARDEVENT_SCANCODE_U32];
u8* eventRepeat = &event[SDL3_KEYBOARDEVENT_REPEAT_U8];
int gameTimeFrameStart;
int secondsGameTime;

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Tetrus", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

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
//soloud.Sfxr_setLooping(sfxrObject, 0);   // 1 = true, 0 = false

function playSound() { soloud.Soloud_play(soloudObject, sfxrObject); }
function playDrop() { soloud.Soloud_play(soloudObject, dropObject); }
function playTurn() { soloud.Soloud_play(soloudObject, sfxrSelectObject); }

function FillGridElementPixels(pointer p, u32 color) asm {
  push	rdi
  mov   rdi, [p@FillGridElementPixels]
  mov   rax, [color@FillGridElementPixels]
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_ScreenPixelSize
  inc   rcx
  cmp	rcx, GRID_ELEMENT_PIXELS
  jne	.loop
  pop	rdi
}


function FillGridElementBody(pointer p, u32 fgColor, u32 bgColor) asm {
  push	rdi
  mov   rdi, [p@FillGridElementBody]
  mov   rax, [fgColor@FillGridElementBody]
  mov   rdx, [bgColor@FillGridElementBody]
  mov	[rdi], edx
  add	rdi, GC_ScreenPixelSize
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_ScreenPixelSize
  inc   rcx
  cmp	rcx, GRID_ELEMENT_PIXELS_KERN
  jne	.loop
  mov	[rdi], edx
  pop	rdi
}


function DrawGridElement(int x, int y, int shape) {
	u32 fgColor = fgColorList[shape];
	u32 bgColor = bgColorList[shape];

	int spelVlakXOffset = (SCREEN_WIDTH - (GRID_ELEMENTS_X * GRID_ELEMENT_PIXELS)) / 2;
	int spelVlakYOffset = 50;
	pointer p = &pixels[(x * GRID_ELEMENT_PIXELS)+spelVlakXOffset, y * GRID_ELEMENT_PIXELS + spelVlakYOffset];
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
	if (gewensteRichting == 1)  { dx = -1; }
	if (gewensteRichting == 2)  { dx = 1; }
	if (gewensteRichting == 3)  { rotateDelta = 1; playTurn(); }
	if (gewensteRichting == 4)  { rotateDelta = 1; playTurn(); }

	for (i in 1..keyboardStackNeedle) {
		keyboardStack[i-1] = keyboardStack[i];
	}
	keyboardStackNeedle = keyboardStackNeedle - 1;
}


function GenerateNewPiece() {
	int n = msvcrt.rand() % 7;
	activeFigureColor = n+1;

	for (i in 0 ..< 4) {
		activeFigure[i].x = 4 + figures[i, n] % 2;
	    activeFigure[i].y = figures[i, n] / 2;
	}
}


function CopyActiveToOld() {
	for (i in 0 ..< 4) {
		oldFigure[i].x = activeFigure[i].x;
		oldFigure[i].y = activeFigure[i].y;
	}
}

function CopyOldToActive() {
	for (i in 0 ..< 4) {
		activeFigure[i].x = oldFigure[i].x;
		activeFigure[i].y = oldFigure[i].y;
	}
}


Point rotationPoint;
function Rotate() {
	CopyActiveToOld();

	rotationPoint.x = activeFigure[1].x;  // center of rotation
	rotationPoint.y = activeFigure[1].y;
	for (i in 0 ..< 4) {
		int x = activeFigure[i].y - rotationPoint.y;
		int y = activeFigure[i].x - rotationPoint.x;
		activeFigure[i].x = rotationPoint.x - x;
		activeFigure[i].y = rotationPoint.y + y;
	}

	int collStatus = CollisionStatus();
	if (collStatus < 0) {
		while (collStatus == -1) {  // a point of the piece is too much on the left. Try moving the piece to the right.
			for (i in 0 ..< 4)
				activeFigure[i].x = activeFigure[i].x + 1;
			collStatus = CollisionStatus();
		}
		while (collStatus == -2) {
			for (i in 0 ..< 4)
				activeFigure[i].x = activeFigure[i].x - 1;
			collStatus = CollisionStatus();
		}
		if (CollisionStatus() < 0)
			CopyOldToActive();
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

	if (CollisionStatus() < 0)
		CopyOldToActive();

	if (frameCount % waitCount != 0) { return; }

	for (i in 0 ..< 4)
		activeFigure[i].y = activeFigure[i].y + 1;

	if (CollisionStatus() < 0)
	{
		for (i in 0 ..< 4) { board[oldFigure[i].x, oldFigure[i].y] = activeFigureColor; }

		waitCount = 30;
		playDrop();
		GenerateNewPiece();

		if (CollisionStatus() < 0) {
			gameStatus = "game over";
			return;
		}
	}
	CheckLines();
}


function RestartGame() {
	gameStatus = "game running";
	waitCount = 30;
	ClearBoard();
	GenerateNewPiece();
	linesDoneCounter = 0;
	gameTimeFrameStart = frameCount;
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


RestartGame();
gameStatus = "intro screen";
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN && *eventRepeat == 0) {
			if (*eventScancode == g.SDL_SCANCODE_LEFT)  { keyHitThisFrame = true; keyboardStack[keyboardStackNeedle] = 1; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_RIGHT) { keyHitThisFrame = true; keyboardStack[keyboardStackNeedle] = 2; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_UP)    { keyboardStack[keyboardStackNeedle] = 3; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen")
						gameStatus = "game running";
					else
						RestartGame();
				} else {
					keyboardStack[keyboardStackNeedle] = 4; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; }
				}
			}
			if (*eventScancode == g.SDL_SCANCODE_DOWN)    { waitCount = 3; }
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
		if (*eventType == g.SDL_EVENT_KEY_UP && *eventScancode == g.SDL_SCANCODE_DOWN)
			waitCount = 30;
	}

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (frameCount % 7 == 0) {
		if (keyHitThisFrame == false) {
			if (keyState[g.SDL_SCANCODE_LEFT]) { keyboardStack[keyboardStackNeedle] = 1; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (keyState[g.SDL_SCANCODE_RIGHT]) { keyboardStack[keyboardStackNeedle] = 2; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
		}
		keyHitThisFrame = false;
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
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
}
soloud.Sfxr_destroy(sfxrSelectObject);
soloud.Sfxr_destroy(sfxrObject);
soloud.Sfxr_destroy(dropObject);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
