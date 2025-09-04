
#template sdl3

//https://www.codewithfaraz.com/c/94/how-to-create-snake-game-in-c-programming-step-by-step-guide

#define GRID_ELEMENTS_X 40
#define GRID_ELEMENTS_Y 23
#define GRID_ELEMENT_PIXELS 24
#define GRID_ELEMENT_PIXELS_KERN 22
#define GRID_POSY_OFFSET 4

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include snake_helper.g
#include soloud.g

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
int[128] snakeX = [] asm;
int[128] snakeY = [] asm;
int snakeLength = 3;
int dx;		// x-delta for each move of the snake.
int dy;     // y-delta
int foodX = -1;
int foodY = -1;
int waitCount = 10;		    // nr frames to wait before moving the snake
string gameStatus = "intro screen";    // "intro screen", "game running", "game over", "game finished"
bool StatusRunning = true;
int frameCount = 0;
u32[6] fgColorList = [ 0xff7D7D7C, 0xffffff00, 0xffffffff, 0xffff00ff, 0xff00ffff, 0xffffffff ];
u32[6] bgColorList = [ 0xffBBBBBB, 0xffffff00, 0xffbbbbbb, 0xffff00ff, 0xffFEE92D, 0xffffffff ];
int[6] keyboardStack = [ ] asm;
int keyboardStackNeedle = 0;

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Snake", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();

ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr sfxrObject = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(sfxrObject, "sound/sfxr/powerup.sfs");
if (sfxrLoaded != 0) return;
f32 theVolume = 1.0;
soloud.Sfxr_setVolume(sfxrObject, theVolume);
soloud.Sfxr_setLooping(sfxrObject, 0);   // 1 = true, 0 = false

function playSound() {
	soloud.Soloud_play(soloudObject, sfxrObject);
}


function GenerateFood() {
	bool keepLooping = true;
	while (keepLooping) {
		foodX = (msys_frand(&seedRandom) % (GRID_ELEMENTS_X-2)) + 1;   // food on the edges is not fun.
		foodY = (msys_frand(&seedRandom) % (GRID_ELEMENTS_Y-2)) + 1;
		if (board[foodX, foodY] == 0) { keepLooping = false; }
	}
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

	pointer p = &pixels[x * GRID_ELEMENT_PIXELS, y * GRID_ELEMENT_PIXELS + GRID_POSY_OFFSET];
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
	FillHorizontal(0, 3, fgColorList[0]);
	FillHorizontal(3, 1, bgColorList[0]);
	for (y in 0 ..< GRID_ELEMENTS_Y) {
		for (x in 0 ..< GRID_ELEMENTS_X) {
			DrawGridElement(x,y, board[x,y]);
		}
	}
	FillHorizontal(SCREEN_HEIGHT-4, 1, bgColorList[0]);
	FillHorizontal(SCREEN_HEIGHT-3, 3, fgColorList[0]);
}


function UpdateBoard() {
	for (y in 0 ..< GRID_ELEMENTS_Y) {
		for (x in 0 ..< GRID_ELEMENTS_X) {
			board[x,y] = 0;
		}
	}
	for (i in 0..< snakeLength) {
        board[snakeX[i], snakeY[i]] = 1;
    }
	if not (foodX == -1 and foodY == -1) {
		board[foodX, foodY] = 2;
	}
}


function CheckEatingFood() {
    if (snakeX[0] == foodX && snakeY[0] == foodY) {
		snakeX[snakeLength] = snakeX[snakeLength-1];
		snakeY[snakeLength] = snakeY[snakeLength-1];
		playSound();
        snakeLength = snakeLength + 1;
		if (snakeLength == 100) { gameStatus = "game finished"; foodX = -1; foodY = -1; return; }
		if (snakeLength % 12 == 0) { if (waitCount > 4) { waitCount = waitCount - 1; } }
        GenerateFood();
    }
}

function CheckCollision(int newX, int newY) : int {
    if (newX < 0 or newX >= GRID_ELEMENTS_X or newY < 0 or newY >= GRID_ELEMENTS_Y) {
        return 1;      // The wall is undefeated.
    }
    for (int i = 1; i < (snakeLength-1); i++) {
        if (newX == snakeX[i] and newY == snakeY[i]) {
            return 2;  // Snake bites itself.
        }
    }
	return 0;
}


function CheckChangeDirection() {
	if (keyboardStackNeedle == 0) { return; }

	int gewensteRichting = keyboardStack[0];
	if (gewensteRichting == 1)  { if not (dx == 1 and dy == 0) { dx = -1; dy = 0; } }
	if (gewensteRichting == 2)  { if not (dx == -1 and dy == 0) { dx = 1; dy = 0; } }
	if (gewensteRichting == 3)  { if not (dy == 1 and dx == 0) { dy = -1; dx = 0; } }
	if (gewensteRichting == 4)  { if not (dy == -1 and dx == 0) { dy = 1; dx = 0; } }

	for (i in 1..keyboardStackNeedle) {
		keyboardStack[i-1] = keyboardStack[i];
	}
	keyboardStackNeedle = keyboardStackNeedle - 1;
}



function MoveSnake() {
	if (frameCount % waitCount != 0) { return; }

	CheckChangeDirection();

	int newX = snakeX[0] + dx;
	int newY = snakeY[0] + dy;

	int collision = CheckCollision(newX, newY);
	if (collision > 0) { gameStatus = "game over"; return; }

    for (int i = snakeLength - 1; i > 0; i--) {
        snakeX[i] = snakeX[i - 1];
        snakeY[i] = snakeY[i - 1];
    }

    snakeX[0] = newX;
    snakeY[0] = newY;

	CheckEatingFood();
}


function RestartGame() {
	gameStatus = "game running";
	waitCount = 10;
	dx = 1;
	dy = 0;
	snakeLength = 3;
	for (i in 0..< snakeLength) { snakeX[i] = 5-i; snakeY[i] = 10; }
	UpdateBoard();
	GenerateFood();
}

function IntroScreenInformation() {
	writeText(renderer, 60.0, 50.0, "Feed the Snake 100 meals!");
	writeText(renderer, 60.0, 70.0, "Use cursor keys to steer.");
	writeText(renderer, 60.0, 90.0, " Press [space] to start.");
}

function GameOverInformation() {
	writeText(renderer, 60.0, 50.0, "   *** Game over ***");
	writeText(renderer, 60.0, 70.0, "Do not let the Snake bite");
	writeText(renderer, 60.0, 90.0, "  itself or hit a wall!");
	writeText(renderer, 60.0, 110.0, " The Snake size was " + snakeLength + ".");
	writeText(renderer, 60.0, 130.0, "Press [space] to restart");
}

function GameFinishedInformation() {
	writeText(renderer, 70.0, 50.0, "***  Game Completed! ***");
	writeText(renderer, 70.0, 70.0, "Finally after 100 meals,");
	writeText(renderer, 70.0, 90.0, " the Snake is satisfied!");
	writeText(renderer, 70.0, 130.0, "Press [space] to restart.");
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
			if (*eventScancode == g.SDL_SCANCODE_DOWN)  { keyboardStack[keyboardStackNeedle] = 4; if (keyboardStackNeedle < 4) { keyboardStackNeedle++; } }
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen") { 
						gameStatus = "game running";
					} else { 
						RestartGame();
					}
				}
			}
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	if (gameStatus == "game running") { MoveSnake(); }

	UpdateBoard();
	DrawBoard();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (gameStatus == "intro screen")
		IntroScreenInformation();
	else if (gameStatus == "game over")
		GameOverInformation();
	else if (gameStatus == "game finished")
		GameFinishedInformation();

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

soloud.Sfxr_destroy(sfxrObject);
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
