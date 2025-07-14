
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
#include tetrus_helper.g


class Point {
	int x;
	int y;
}

Point[4] pointActive = [];  // een figuur heeft 4 punten.
Point[4] pointOld = [];

int[4,7] figures = [
	1,3,5,7, // I
	2,4,5,7, // Z
	3,5,4,6, // S
	3,5,4,7, // T
	2,3,5,7, // L
	3,5,7,6, // J
	2,3,4,5  // O
];
int colorNum = 1;
int dx = 0;
int rotateDelta = 0;
int linesToComplete = 20;
int linesDoneCounter = 0;

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
int waitCount = 10;
string gameStatus = "intro screen";    // "intro screen", "game running", "game over", "game finished"
bool StatusRunning = true;
int frameCount = 0;
u32[8] fgColorList = [ 0xff3D3D3C, 0xFFFEF84C, 0xFF51E1FC, 0xFFE93D1E, 0xFF79AE3D, 0xFFF69230, 0xFFF16EB9, 0xFF943692 ];
u32[8] bgColorList = [ 0xff7B7B7B, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB, 0xffBBBBBB ];
int[6] keyboardStack = [ ] asm;
int keyboardStackNeedle = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Tetrus", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

bool wavLoaded = sdl3.SDL_LoadWAV("coin.wav", &spec, &wavData, &wavDataLen);
stream = sdl3.SDL_OpenAudioDeviceStream(g.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, null, null);
if (!wavLoaded or (stream == null)) { user32.MessageBox(null, "The sound cannot be loaded!", "Message", g.MB_OK); return; }
function playSound() {
	sdl3.SDL_ResumeAudioStreamDevice(stream);
	sdl3.SDL_PutAudioStreamData(stream, wavData, wavDataLen);
}


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
		board[pointActive[i].x, pointActive[i].y] = colorNum;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			DrawGridElement(x,y, board[x,y]);

	for (i in 0 ..< 4)
		board[pointActive[i].x, pointActive[i].y] = 0;
}


function ClearBoard() {
	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			board[x,y] = 0;
}


function NoCollision() : int {
	for (i in 0..< 4)
		if (pointActive[i].x < 0 or pointActive[i].x >= GRID_ELEMENTS_X or pointActive[i].y >= GRID_ELEMENTS_Y)
			return 0;
		else if (board[pointActive[i].x, pointActive[i].y] > 0)
			return 0;

	return 1;
}


function CheckChangeDirection() {
	dx = 0;
	rotateDelta = 0;

	if (keyboardStackNeedle == 0) { return; }

	int gewensteRichting = keyboardStack[0];
	if (gewensteRichting == 1)  { dx = -1; }
	if (gewensteRichting == 2)  { dx = 1; }
	if (gewensteRichting == 3)  { rotateDelta = 1; }
	if (gewensteRichting == 4)  { rotateDelta = 1; }

	for (i in 1..keyboardStackNeedle) {
		keyboardStack[i-1] = keyboardStack[i];
	}
	keyboardStackNeedle = keyboardStackNeedle - 1;
}


function GenerateNewPiece() {
	int n = msys_frand(&seedRandom) % 7;
	colorNum = n+1;

	for (i in 0 ..< 4) {
		pointActive[i].x = 4 + figures[i, n] % 2;
	    pointActive[i].y = figures[i, n] / 2;
	}
}


function CopyActiveToOld() {
	for (i in 0 ..< 4) {
		pointOld[i].x = pointActive[i].x;
		pointOld[i].y = pointActive[i].y;
	}
}

function CopyOldToActive() {
	for (i in 0 ..< 4) {
		pointActive[i].x = pointOld[i].x;
		pointActive[i].y = pointOld[i].y;
	}
}


Point rotationPoint;
function Rotate() {
	CopyActiveToOld();

	rotationPoint.x = pointActive[1].x;  // center of rotation
	rotationPoint.y = pointActive[1].y;
	for (i in 0 ..< 4) {
		int x = pointActive[i].y - rotationPoint.y;
		int y = pointActive[i].x - rotationPoint.x;
		pointActive[i].x = rotationPoint.x - x;
		pointActive[i].y = rotationPoint.y + y;
	}

	if not (NoCollision())
		CopyOldToActive();
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
		if (count < GRID_ELEMENTS_X) {
			k--;
		}
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
		pointActive[i].x = pointActive[i].x + dx;

	if not (NoCollision())
		CopyOldToActive();

	if (frameCount % waitCount != 0) { return; }


	for (i in 0 ..< 4)
		pointActive[i].y = pointActive[i].y + 1;


	if not (NoCollision())
	{
		for (i in 0 ..< 4) { board[pointOld[i].x, pointOld[i].y] = colorNum; }

		waitCount = 30;
		GenerateNewPiece();

		if not (NoCollision()) {
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
}


RestartGame();
gameStatus = "intro screen";
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_LEFT)  { keyboardStack[keyboardStackNeedle] = 1; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_RIGHT) { keyboardStack[keyboardStackNeedle] = 2; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_UP)    { keyboardStack[keyboardStackNeedle] = 3; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen") { 
						gameStatus = "game running";
					} else { 
						RestartGame();
					}
				} else {
					keyboardStack[keyboardStackNeedle] = 4; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; }
				}
			}
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	sdl3.SDL_PumpEvents();
	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (keyState[g.SDL_SCANCODE_DOWN])
		waitCount = 4;
    else
		waitCount = 30;

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	if (gameStatus == "game running") { MovePiece(); }

	SDL3_ClearScreenPixels(0xff000000);
	DrawBoard();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (gameStatus == "intro screen") {
		writeText(renderer, 60.0, 50.0, ("  Try to fully fill " + linesToComplete));
		writeText(renderer, 60.0, 60.0, "  horizontal lines.");
		writeText(renderer, 60.0, 90.0, " Press [space] to start.");
	}

	if (gameStatus == "game over") {
		writeText(renderer, 60.0, 50.0, "   *** Game over ***");
		writeText(renderer, 60.0, 70.0, "  You needed " + linesToComplete + " lines.");
		writeText(renderer, 60.0, 80.0, "  You have done " + linesDoneCounter + " lines.");
		writeText(renderer, 60.0, 130.0, "Press [space] to restart");
	}

	if (gameStatus == "game finished") {
		writeText(renderer, 70.0, 50.0, "***  Game Completed! ***");
		writeText(renderer, 70.0, 70.0, "You solved " + linesToComplete + " lines!");
		writeText(renderer, 70.0, 130.0, "Press [space] to restart.");
	}

	if (gameStatus == "game running") {
		writeText(renderer, 5.0, 50.0, "Lines to do:" + (linesToComplete - linesDoneCounter));
	}

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks)
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

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
