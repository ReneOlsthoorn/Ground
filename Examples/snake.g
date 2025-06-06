
#template sdl3

//https://www.codewithfaraz.com/c/94/how-to-create-snake-game-in-c-programming-step-by-step-guide

#define GRID_ELEMENTS_X 40
#define GRID_ELEMENTS_Y 23
#define GRID_ELEMENT_PIXELS 24

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include snake_helper.g

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
u32[6] colorlist = [ 0xff000000, 0xffffff00, 0xffff00ff, 0xff00ffff, 0xffffffff, 0xffffffff ];
int[6] keyboardStack = [ ] asm;
int keyboardStackNeedle = 0;

int[100] snakeX = [] asm;
int[100] snakeY = [] asm;
int dx;
int dy;
int snakeLength = 3;
int foodX = -1;
int foodY = -1;

byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int frameCount = 0;
int waitCount = 10;
int gameOverFramecount = 0;

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Snake", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();


class SDL_AudioSpec {
	u32 format;
	i32 channels;
	i32 freq;
}
SDL_AudioSpec spec;
string wavPath = "coin.wav";
ptr stream = null;
u8* wavData = null;
u32 wavDataLen = 0;
bool wavLoaded = sdl3.SDL_LoadWAV(wavPath, &spec, &wavData, &wavDataLen);
stream = sdl3.SDL_OpenAudioDeviceStream(g.SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, null, null);
if (!wavLoaded or !stream)
	StatusRunning = false;

function playSound() {
	sdl3.SDL_ResumeAudioStreamDevice(stream);
	sdl3.SDL_PutAudioStreamData(stream, wavData, wavDataLen);
}


function GenerateFood() {
	bool keepLooping = true;
	while (keepLooping) {
		foodX = msys_frand(&seedRandom) % GRID_ELEMENTS_X;
		foodY = msys_frand(&seedRandom) % GRID_ELEMENTS_Y;

		if (board[foodX, foodY] == 0) { keepLooping = false; }
	}
}


function DrawGridElement(int x, int y) {
	int shape = board[x,y];
	u32 color = colorlist[shape];
	for (j in 2..< GRID_ELEMENT_PIXELS) {
		for (i in 2..< GRID_ELEMENT_PIXELS) {
			pixels[(x*GRID_ELEMENT_PIXELS)+i,(y*GRID_ELEMENT_PIXELS)+j+4] = color;
		}
	}
}


function DrawBoard() {
	for (y in 0 ..< GRID_ELEMENTS_Y) {
		for (x in 0 ..< GRID_ELEMENTS_X) {
			DrawGridElement(x,y);
		}
	}
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
		board[foodX, foodY] = 4;
	}
}

function CheckEatingFood() {
    if (snakeX[0] == foodX && snakeY[0] == foodY) {
		snakeX[snakeLength] = snakeX[snakeLength-1];
		snakeY[snakeLength] = snakeY[snakeLength-1];
		playSound();
        snakeLength = snakeLength + 1;
		if (snakeLength % 5 == 0) { if (waitCount > 4) { waitCount = waitCount - 1; } }
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
	if (collision > 0) { gameOverFramecount = 1; return; }

    for (int i = snakeLength - 1; i > 0; i--) {
        snakeX[i] = snakeX[i - 1];
        snakeY[i] = snakeY[i - 1];
    }

    snakeX[0] = newX;
    snakeY[0] = newY;

	CheckEatingFood();
}


function RestartGame() {
	gameOverFramecount = 0;
	waitCount = 10;
	dx = 1;
	dy = 0;
	snakeLength = 3;
	for (i in 0..< snakeLength) { snakeX[i] = 5-i; snakeY[i] = 10; }

	UpdateBoard();
	GenerateFood();
}



RestartGame();
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
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	SDL3_ClearScreenPixels();
	if (gameOverFramecount == 0) { MoveSnake(); }

	UpdateBoard();
	DrawBoard();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (gameOverFramecount > 0) {
		writeText(renderer, 100.0, 70.0, "*** Game over! ***");
		writeText(renderer, 100.0, 90.0, "    Try again...");
		gameOverFramecount++;
		if (gameOverFramecount > 125) {	
			RestartGame();
		}
	}	

	//writeText(renderer, 60.0, 60.0, "waitcount: " + waitCount);

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
