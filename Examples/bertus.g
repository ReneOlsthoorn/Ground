
#template sdl3

#define SPRITESHEET_WIDTH 256
#define SPRITESHEET_HEIGHT 256
#define SPRITESHEET_ACTOR_WIDTH 32
#define SPRITESHEET_ACTOR_HEIGHT 32
#define SPRITESHEET_CUBE_WIDTH 64
#define SPRITESHEET_CUBE_HEIGHT 64
#define SPRITESHEET_IMAGE_BALL 3
#define SPRITESHEET_BLOCK_RED 1
#define SPRITESHEET_BLOCK_YELLOW 2
#define SPRITESHEET_BLOCK_BLUE 3
#define GRID_START_X 250
#define GRID_START_Y 100
#define MAX_NR_BALLS 5

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include bertus_helper.g

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int frameCount = 0;
int level = 1;
int levelCompleteFramecount = 0;
int gameOverFramecount = 0;
int nrBlocksHit = 0;
int nrEnemyBalls = 5;
int[] jumpSimulation = [-6,-4,-2,-1,0,0,0,0,0,0,0,0,1,2,4,6];  // Simulates newton
int[] randomBallSpread = [0,1,2,3,4,5,6,1,2,3,4,5,2,3,4,3];
int[] blockState =  [0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0];  // length: 49. State of each possible block.
int[] level1 = [3,9,10,16,17,18,22,23,24,25,29,30,31,32,33,35,36,37,38,39,40,42,43,44,45,46,47,48];			// which blocks of the blockState are solid. Defines the shape of the level.
int[] level2 = [7,9,10,12,14,15,16,18,19,20,21,22,23,24,25,26,29,30,31,32,33,36,37,38,39,43,44,45,46,47];	// which blocks of the blockState are solid. Defines the shape of the level.
int[] level3 = [8,9,10,11,15,16,17,18,19,21,22,25,26,29,30,32,33,35,36,37,38,39,40,42,43,44,45,46,47,48];
int[] level4 = [1,2,4,5,7,8,9,10,11,12,14,15,17,19,20,21,22,23,24,25,26,28,30,31,32,34,35,36,37,38,39,40];
int* levelPtr = &level1[0];
int levelSize = sizeof(level1) / sizeof(int);
asm data {spritesheet_p dq 0}
g.[spritesheet_p] = sidelib.LoadImage("Bertus.png");
if (g.[spritesheet_p] == null) { user32.MessageBox(null, "The spritesheet cannot be found!", "Message", g.MB_OK); return; }
sidelib.FlipRedAndGreenInImage(g.[spritesheet_p], SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT);
u32[SPRITESHEET_WIDTH, SPRITESHEET_HEIGHT] spritesheet = g.[spritesheet_p];


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Bertus", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();


class CubeShape {
	int x;
	int y;

	function nrElements() { return levelSize; }
	function getIndexForElement(int elementNr) { return levelPtr[elementNr]; }
	function getXY(int elementNr) {
		int theIndex = this.getIndexForElement(elementNr);
		int theRow = theIndex / 7;
		bool isOneven = ((theRow % 2) == 1);
		int remaining = theIndex % 7;
		this.y = theRow * 48;
		this.x = remaining * SPRITESHEET_CUBE_WIDTH;
		if (isOneven) { this.x = this.x + 32; }
	}
	function getDestinationPointer(int elementNr) : ptr {
	    this.getXY(elementNr);
		ptr result = ScreenPointerForXY(GRID_START_X + this.x, GRID_START_Y + this.y + 14);
		return result;
	}
}


class Actor {
	int x;
	int y;
	int arrivedAtIndex;
	int movex;
	int movey;
	int image;
	int jumpSimulationPosition;
	bool visible;
	bool falling;
	int fallenOffCounter;
	int waitingTime;

	function draw() {
		if (this.waitingTime > 0) { return; }
		ptr dest = ScreenPointerForXY(GRID_START_X + this.x, GRID_START_Y + this.y);
		ptr qPic = g.[spritesheet_p] + (this.image * SPRITESHEET_ACTOR_WIDTH * SCREEN_PIXELSIZE);
		if (this.visible == true) {
			PlotSheetSprite(qPic, dest, SPRITESHEET_ACTOR_WIDTH, SPRITESHEET_ACTOR_HEIGHT, SPRITESHEET_WIDTH);
		}
	}
	function jump(newX, newY, newImage) {
		this.movex = newX;
		this.movey = newY;
		this.image = newImage;
		this.jumpSimulationPosition = 0;
		this.falling = false;
	}
	function isHit(int otherX, int otherY) : bool {
		return msvcrt.abs(otherX-this.x) < 16 && msvcrt.abs(otherY-this.y) < 16;
	}
	function isArrivedAtBlock() {
		return (this.falling == false and this.movex == 0 and this.movey == 0);
	}
	function move() {
		this.arrivedAtIndex = -1;
		if (this.waitingTime > 0) {
			this.waitingTime = this.waitingTime - 1;
			return;
		}
		if (this.movex < 0) {
			this.x = this.x - 2;
			this.movex = this.movex + 2;
		}
		if (this.movex > 0) {
			this.x = this.x + 2;
			this.movex = this.movex - 2;
		}
		if (this.falling) {
			this.y = this.y + 2;
			if (this.y >= (528 - GRID_START_Y)) {
				this.visible = false;
				this.movex = 0;
				this.movey = 0;
				this.falling = false;
			}
		} else {
			if (this.movey < 0) {
				this.y = this.y - 3 + jumpSimulation[this.jumpSimulationPosition];
				this.movey = this.movey + 3;
			}
			if (this.movey > 0) {
				this.y = this.y + 3 + jumpSimulation[this.jumpSimulationPosition];
				this.movey = this.movey - 3;
			}
			this.jumpSimulationPosition = this.jumpSimulationPosition + 1;
		}
		if (this.fallenOffCounter > 0) { this.fallenOffCounter = this.fallenOffCounter + 1; }
	}
	function reset() {
		this.waitingTime = 0;
		this.jumpSimulationPosition = 0;
		this.movex = 0;
		this.movey = 0;
		this.visible = false;
		this.falling = false;
		this.arrivedAtIndex = -1;
		this.fallenOffCounter = 0;
	}
}


CubeShape shape;
Actor bertus;
Actor[MAX_NR_BALLS] balls = [ ];

function initBertus() {
	bertus.reset();
	shape.getXY(0);
	bertus.x = shape.x+16;
	bertus.y = shape.y;
	bertus.image = 7;
	bertus.visible = true;
}

function getRandomLevelIndex() : int {
	int randomValue = randomBallSpread[(msys_frand(&seedRandom) % 16)];
	return randomValue;
}

function initBall(int idx) {
	balls[idx].reset();
	bool goodValue = false;
	while (goodValue == false) {
		goodValue = true;
		shape.x = getRandomLevelIndex() * 64;
		if ((shape.x+16) == bertus.x and nrBlocksHit < 2) { goodValue = false; }
		for (i in 0 ..< nrEnemyBalls) {
			if (i != idx) {
				if ((shape.x+16) == balls[i].x) { goodValue = false; }
			}
		}
	}
	balls[idx].x = shape.x+16;
	balls[idx].y = 0 - GRID_START_Y;
	balls[idx].image = SPRITESHEET_IMAGE_BALL;
	balls[idx].visible = true;
	balls[idx].falling = true;
	balls[idx].waitingTime = getRandomLevelIndex() * 20;
}


function GotoLevel(int level) {
	nrBlocksHit = 0;
	bertus.reset();
	for (i in 0 ..< nrEnemyBalls) { balls[i].reset(); }
	levelCompleteFramecount = 0;
	gameOverFramecount = 0;
	for (i in 0..48) { blockState[i] = 0; }
	if (level == 1) { levelPtr = &level1[0]; levelSize = sizeof(level1) / sizeof(int); }
	if (level == 2) { levelPtr = &level2[0]; levelSize = sizeof(level2) / sizeof(int); }
	if (level == 3) { levelPtr = &level3[0]; levelSize = sizeof(level3) / sizeof(int); }
	if (level == 4) { levelPtr = &level4[0]; levelSize = sizeof(level4) / sizeof(int); }
	for (i in 0..< shape.nrElements()) {
		int indexForElement = shape.getIndexForElement(i);
		blockState[indexForElement] = SPRITESHEET_BLOCK_BLUE;
	}
	initBertus();
	for (i in 0 ..< nrEnemyBalls) { initBall(i); }
}


function Draw() {
	if (bertus.fallenOffCounter >= 16) { bertus.draw(); }
	for (i in 0 ..< nrEnemyBalls) {
		if (balls[i].fallenOffCounter >= 16) {
			balls[i].draw();
		}
	}

	ptr destPtr;
	for (i in 0..< shape.nrElements()) {
		destPtr = shape.getDestinationPointer(i);
		int indexForElement = shape.getIndexForElement(i);
		int blockImage = blockState[indexForElement];
		PlotSheetSprite(g.[spritesheet_p]+(blockImage * SPRITESHEET_CUBE_HEIGHT * SPRITESHEET_WIDTH * SCREEN_PIXELSIZE), destPtr, SPRITESHEET_CUBE_WIDTH, SPRITESHEET_CUBE_HEIGHT, SPRITESHEET_WIDTH);
	}

	if (bertus.fallenOffCounter < 16) { bertus.draw(); }
	for (i in 0 ..< nrEnemyBalls) {
		if (balls[i].fallenOffCounter < 16) {
			balls[i].draw();
		}
	}
}


function MoveElements() {
	bertus.move();
	for (j in 0 ..< nrEnemyBalls) {
		if (j % 2 == 0) {
			if (frameCount % 3 == 0 or balls[j].falling) { balls[j].move();	}
		} else {
			if (frameCount % 2 == 0 or balls[j].falling) { balls[j].move();	}
		}
	}

	// Is Bertus or a ball arrived at a block?
	for (i in 0..< shape.nrElements()) {
		shape.getXY(i);
		int theIndex = shape.getIndexForElement(i);
		if (bertus.fallenOffCounter == 0 && bertus.x == (shape.x+16) && bertus.y == shape.y) {
			bertus.arrivedAtIndex = theIndex;
			blockState[theIndex] = SPRITESHEET_BLOCK_YELLOW;
		}
		int random = 0;
		for (j in 0 ..< nrEnemyBalls) {
			if (balls[j].fallenOffCounter == 0 && balls[j].x == (shape.x+16) && balls[j].y == shape.y) {
				balls[j].arrivedAtIndex = theIndex;
				random = msys_frand(&seedRandom);
				if (random % 2 == 0) {
					balls[j].jump(32,48,SPRITESHEET_IMAGE_BALL);
				} else {
					balls[j].jump(-32,48,SPRITESHEET_IMAGE_BALL);
				}
			}
		}
	}

	if (bertus.fallenOffCounter == 0) {
		for (j in 0 ..< nrEnemyBalls) {
			if (balls[j].fallenOffCounter == 0 && balls[j].falling == false && bertus.isHit(balls[j].x, balls[j].y)) {
				gameOverFramecount = 1;
			}
		}
	}

	if (bertus.isArrivedAtBlock() and bertus.arrivedAtIndex == -1) {
		bertus.falling = true;
		bertus.fallenOffCounter = 1;
	}

	if (bertus.visible == false) { bertus.visible = true; gameOverFramecount = 1; }
	for (j in 0 ..< nrEnemyBalls) {
		if (balls[j].visible == false && balls[j].waitingTime == 0) {
			initBall(j);
		}
	}

	for (j in 0 ..< nrEnemyBalls) {
		if (balls[j].falling == false and balls[j].isArrivedAtBlock() and balls[j].arrivedAtIndex == -1) {
			balls[j].falling = true;
			balls[j].fallenOffCounter = 1;
		}
	}

	// All blocks are stepped on?
	bool allBlocksHit = true;
	nrBlocksHit = 0;
	for (i in 0..48) {
		if (blockState[i] == SPRITESHEET_BLOCK_BLUE) { allBlocksHit = false; }
		if (blockState[i] == SPRITESHEET_BLOCK_YELLOW) { nrBlocksHit = nrBlocksHit + 1; }
	}
	if (allBlocksHit) {	levelCompleteFramecount = 1; }
}

// BEGIN Mainloop:
GotoLevel(level);
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT) {
			StatusRunning = false;
		}
		if ((bertus.movex == 0) && (bertus.movey == 0)) {
			if (*eventType == g.SDL_EVENT_KEY_DOWN) {
				if (bertus.falling == false and bertus.visible == true) {
					if (*eventScancode == g.SDL_SCANCODE_LEFT)  { bertus.jump(-32,-48,0); }    // naar boven links
					if (*eventScancode == g.SDL_SCANCODE_RIGHT) { bertus.jump(32,48,5); }      // naar onder rechts
					if (*eventScancode == g.SDL_SCANCODE_UP)    { bertus.jump(32,-48,1); }     // naar boven rechts
					if (*eventScancode == g.SDL_SCANCODE_DOWN)  { bertus.jump(-32,48,7); }     // naar onder links
				}
				if (*eventScancode == g.SDL_SCANCODE_ESCAPE) {
					StatusRunning = false;
				}
			}
		}
	}

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	loopStartTicks = sdl3.SDL_GetTicks();

	SDL3_ClearScreenPixels();
	Draw();
	if (levelCompleteFramecount == 0 and gameOverFramecount == 0) {
		MoveElements();
	}

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks) {
		debugBestTicks = currentTicks;
	}

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	if (levelCompleteFramecount > 0) {
		writeText(renderer, 100.0, 70.0, "Level complete!");
		levelCompleteFramecount++;
		if (levelCompleteFramecount > 125) {
			level++;
			if (level > 4) { level = 1; }
			GotoLevel(level);
		} else {
			for (i in 0..< shape.nrElements()) {
				shape.getXY(i);
				int theIndex = shape.getIndexForElement(i);
				int theBlockNr = SPRITESHEET_BLOCK_YELLOW;
				int remain = (levelCompleteFramecount / 10) % 2;
				if (remain == 1) { theBlockNr = SPRITESHEET_BLOCK_BLUE; }
				blockState[theIndex] = theBlockNr;
			}
		}
	}

	if (gameOverFramecount > 0) {
		writeText(renderer, 100.0, 70.0, "*** Game over! ***");
		writeText(renderer, 100.0, 90.0, "    Try again...");
		gameOverFramecount++;
		if (gameOverFramecount > 125) {
			GotoLevel(level);
		}
	}

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}
// END Mainloop

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

sidelib.FreeImage(g.[spritesheet_p]);

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
