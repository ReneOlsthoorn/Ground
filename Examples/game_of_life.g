
// John Conway's Game Of Life.
// Calculate whether the center cell of every 3x3 block on the board is alive with the following rules:
// 1) When a center cell is surrounded by exactly 3 live cells, the center cell is born.
// 2) When the living center cell is surrounded with 2 or 3 colored cells, it remains alive.

#template sdl3

#define GRID_ELEMENTS_X 160
#define GRID_ELEMENTS_Y 90
#define GRID_ELEMENT_PIXELS 8
#define GRID_ELEMENT_PIXELS_KERN 7
#define GRID_POSY_OFFSET 0

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll

bool optimizedExecution = true;

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
byte[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] nextBoard = [ ] asm;
byte[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] oldBoard = [ ] asm;
u32[6] fgColorList = [ 0xff7D7D7C, 0xffffff00, 0xffffffff, 0xffff00ff, 0xff00ffff, 0xffffffff ];
u32[6] bgColorList = [ 0xffBBBBBB, 0xffFEE92D, 0xffbbbbbb, 0xffff00ff, 0xff00ffff, 0xffffffff ];
bool StatusRunning = true;
int frameCount = 0;
int frameCountToStartGeneration = 0;   // The value the frameCount must have to start the Game Of Life generation
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
int figureShow = 0;
int generations = 0;

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.
sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Game Of Life", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

#include game_of_life_helper.g

function NrNeighbours(int x, int y) : int {
	int nr = 0;
	int theLeft = x-1;
	if (theLeft == -1)
		theLeft = GRID_ELEMENTS_X - 1;
	int theRight = x+1;
	if (theRight == GRID_ELEMENTS_X)
		theRight = 0;
	int theTop = y-1;
	if (theTop == -1)
		theTop = GRID_ELEMENTS_Y - 1;
	int theBottom = y+1;
	if (theBottom == GRID_ELEMENTS_Y)
		theBottom = 0;

	nr = nr + board[theLeft,theTop] + board[x,theTop] + board[theRight,theTop];
	nr = nr + board[theLeft,y] + board[theRight,y];
	nr = nr + board[theLeft,theBottom] + board[x,theBottom] + board[theRight,theBottom];
	return nr;
}

function CalculateCenterCellIn3x3Block(int x, int y) {
	int nrNeighboursAliveIn3x3Block = NrNeighbours(x, y);
	bool isAlive = (board[x,y] == 1);

	// 1) When a center cell is surrounded by exactly 3 live cells, the center cell is born.
	if (nrNeighboursAliveIn3x3Block == 3)
		nextBoard[x,y] = 1; // born or remains alive

	// 2) When the living center cell is surrounded with 2 or 3 colored cells, it remains alive.
	if (nrNeighboursAliveIn3x3Block == 2 && isAlive)
		nextBoard[x,y] = 1;
}


function DoGenerationX64() {

	asm {
	  mov	rcx, GC_GRID_ELEMENTS_X * GC_GRID_ELEMENTS_Y
	  lea	rdx, [nextBoard@main]
	  xor	eax, eax
	  call	StoreBytes
	}

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			CalculateCenterCellIn3x3Block(x,y);

	bool isOldBoardNextBoard = true;

	asm {
	  xor	ecx, ecx
	  lea	r8, [oldBoard@main]
	  lea	r9, [nextBoard@main]
.loop:
	  mov	al, [r8]
	  cmp	al, [r9]
	  je	.nextElement
	  mov	qword [isOldBoardNextBoard@DoGenerationX64], 0
	  jmp	.exit
.nextElement:
	  inc	r8
	  inc	r9
	  inc	rcx
	  cmp	rcx, GC_GRID_ELEMENTS_X * GC_GRID_ELEMENTS_Y
	  jne	.loop
.exit:
	}

	if not (isOldBoardNextBoard)
		generations++;

	asm {
	  xor	ecx, ecx
	  lea	r8, [oldBoard@main]
	  lea	r9, [board@main]
	  lea	r10, [nextBoard@main]
.loop:
	  mov	al, [r9]
	  mov	[r8], al
	  mov	al, [r10]
	  mov	[r9], al
	  inc	r8
	  inc	r9
	  inc	r10
	  inc	rcx
	  cmp	rcx, GC_GRID_ELEMENTS_X * GC_GRID_ELEMENTS_Y
	  jne	.loop
.exit:
	}
}


function DoGeneration() {
	if (frameCount < frameCountToStartGeneration)
		return;

	if (frameCount % 5 != 0)
		return;

	if (optimizedExecution) {
		DoGenerationX64();
		return;
	}

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			nextBoard[x,y] = 0;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			CalculateCenterCellIn3x3Block(x,y);

	bool isOldBoardNextBoard = true;
	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			if (oldBoard[x,y] != nextBoard[x,y])
				isOldBoardNextBoard = false;

	if not (isOldBoardNextBoard)
		generations++;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X) {
			oldBoard[x,y] = board[x,y];
			board[x,y] = nextBoard[x,y];
		}
}

#include game_of_life_patterns.g

function ShowNextFigure() {
	int halfX = GRID_ELEMENTS_X / 2;
	int halfY = GRID_ELEMENTS_Y / 2;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			board[x,y] = 0;

	figureShow++;
	if (figureShow == 9)
		figureShow = 1;

	if (figureShow == 1) {
		PlaceSuhajda104P177(55,18);
	}
	if (figureShow == 2) {
		PlaceShip1(135,3);
		Place119P4H1V0(5,10);
		PlaceShip5(130,55);
		PlaceShip2(20,55);
	}
	if (figureShow == 3) {
	    PlaceAchimsp16(15, 16);
		PlaceAchimsp144(20, 40);
		PlaceBeluchenkosp37(70,13);
	}
	if (figureShow == 4) {
		PlacePufferTrain(5, 16);
		PlaceShip3(90,50);
		PlaceShip4(10,50);
		PlaceShip6(50,50);
	}
	if (figureShow == 5) {
		PlaceGliderGun(4,4);
		PlaceGliderEater(21,57);
	}
	if (figureShow == 6) {
		PlacePentomino(halfX-2,halfY-2);
	}
	if (figureShow == 7) {
		PlaceMerzenich(15, 13);
		Place106P135(52,20);
	}
	if (figureShow == 8) {
		PlaceShip8(90,15);
		PlaceShip9(40,1);
	}

	frameCountToStartGeneration = frameCount + 60;
	generations = 0;
}

function PrintInformation() {
	writeText(renderer, 10.0, 4.0, "Figure: " + figureShow + " Generation: " + generations); // + " X: " + gridPosX + " Y: " + gridPosY);
	writeText(renderer, 10.0, 14.0, "Press [space] for next.");
}

#include soundtracker.g
SoundtrackerInit("sound/mod/musiklinjen.mod", 64);

ShowNextFigure();
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
				ShowNextFigure();
			}
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	DoGeneration();
	DrawBoard();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	f32 mouseX;
	f32 mouseY;
	sdl3.SDL_GetMouseState(&mouseX, &mouseY);
	int gridPosX = mouseX / GRID_ELEMENT_PIXELS;
	int gridPosY = mouseY / GRID_ELEMENT_PIXELS;
	PrintInformation();

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
