
// John Conway's Game Of Life.
// Calculate whether the center cell of every 3x3 block on the board is alive with the following rules:
// 1) When a center cell is surrounded by exactly 3 live cells, the center cell is born.
// 2) When the living center cell is surrounded with 2 or 3 colored cells, it remains alive.

#template sdl3

#define GRID_ELEMENTS_X 120
#define GRID_ELEMENTS_Y 70
#define GRID_ELEMENT_PIXELS 8
#define GRID_ELEMENT_PIXELS_KERN 7
#define GRID_POSY_OFFSET 0

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] board = [ ] asm;
byte[GRID_ELEMENTS_X, GRID_ELEMENTS_Y] nextBoard = [ ] asm;
u32[6] fgColorList = [ 0xff7D7D7C, 0xffffff00, 0xffffffff, 0xffff00ff, 0xff00ffff, 0xffffffff ];
u32[6] bgColorList = [ 0xffBBBBBB, 0xffFEE92D, 0xffbbbbbb, 0xffff00ff, 0xff00ffff, 0xffffffff ];
bool StatusRunning = true;
int frameCount = 0;
int frameCountToStartGeneration = 0;   // The value the frameCount must have to start the Game Of Life generation
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = g.GC_ScreenLineSize;
int figureShow = 4;


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.
sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Game Of Life", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);


#include game-of-life helper.g


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


function DoGeneration() {
	if (frameCount < frameCountToStartGeneration)
		return;

	if (frameCount % 5 != 0)
		return;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			nextBoard[x,y] = 0;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			CalculateCenterCellIn3x3Block(x,y);

	// Overwrite the board with nextBoard
	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			board[x,y] = nextBoard[x,y];
}


#include game-of-life patterns.g


function ShowNextFigure() {
	figureShow++;
	if (figureShow == 9)
		figureShow = 1;

	for (y in 0 ..< GRID_ELEMENTS_Y)
		for (x in 0 ..< GRID_ELEMENTS_X)
			board[x,y] = 0;

	if (figureShow == 1) {
		PlaceAchimsp16(15, 16);
		PlaceAchimsp16(55, 16);
		PlaceAchimsp16(95, 16);
		PlaceAchimsp16(35, 40);
		PlaceAchimsp16(75, 40);
	}
	if (figureShow == 2) {
		PlaceAchimsp144(10, 12);
		PlaceAchimsp144(60, 12);
		PlaceAchimsp144(30, 40);
		PlaceAchimsp144(80, 40);
	}
	if (figureShow == 3) {
		PlaceBeluchenkosp37(12,13);
		PlaceBeluchenkosp37(70,13);
	}
	if (figureShow == 4) {
		PlaceMerzenich(15, 13);
		PlaceMerzenich(55, 13);
		PlaceMerzenich(95, 13);
		PlaceMerzenich(35, 40);
		PlaceMerzenich(75, 40);
	}
	if (figureShow == 5)
		PlaceSuhajda104P177(35,12);
	if (figureShow == 6)
		Place119P4H1V0(40,20);
	if (figureShow == 7)
		PlaceGliderGun(4,4);
	if (figureShow == 8)
		Place106P135(32,20);

	frameCountToStartGeneration = frameCount + 60;
}


ShowNextFigure();
while (StatusRunning)
{
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

	writeText(renderer, 10.0, 10.0, "Press [space] for new fig. " + figureShow);

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
