
#template sdl3

#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include bertus_helper.g


u32[960, 560] pixels = null;
byte[128] event = [];
u32* eventType = &event[0];
u32* eventScancode = &event[24];
bool StatusRunning = true;
int frameCount = 0;
int level = 1;
int levelCompleteFramecount = 0;
int gameOverFramecount = 0;
int gridStartX = 250;
int gridStartY = 100;
int[] jumpSimulation = [-6,-4,-2,-1,0,0,0,0,0,0,0,0,1,2,4,6];  // Simulates newton
int[] blockState =  [0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0];  // length: 49. State of each possible block.
int[] level1 = [3,9,10,16,17,18,22,23,24,25,29,30,31,32,33,35,36,37,38,39,40,42,43,44,45,46,47,48];			// which blocks of the blockState are solid. Defines the shape of the level.
int[] level2 = [7,9,10,12,14,15,16,18,19,20,21,22,23,24,25,26,29,30,31,32,33,36,37,38,39,43,44,45,46,47];	// which blocks of the blockState are solid. Defines the shape of the level.
int* levelShapePtr = &level1[0];
int levelShapeCount = sizeof(level1) / 8;
asm data {spritesheet_p dq 0}
g.[spritesheet_p] = sidelib.LoadImage("Bertus.png");
if (g.[spritesheet_p] == null) { user32.MessageBox(null, "The spritesheet cannot be found!", "Message", g.MB_OK); return; }
sidelib.FlipRedAndGreenInImage(g.[spritesheet_p], 256, 256);
u32[256, 256] spritesheet = g.[spritesheet_p];


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
	function nrElements() { return levelShapeCount; }
	function getIndexForElement(int elementNr) { return *(levelShapePtr+elementNr*8); }
	function getXY(int elementNr) {
		int theIndex = getIndexForElement(elementNr);
		int theRow = theIndex / 7;
		bool isOneven = ((theRow % 2) == 1);
		int remaining = theIndex % 7;
		this.y = theRow*48;
		this.x = remaining*64;
		if (isOneven) { this.x = this.x + 32; }
	}
	function getDestinationPointer(int elementNr) : ptr {
	    //getXY(elementNr);  // BUG!! deze werkt niet omdat de this niet goed meekomt in de methode aanroep.
		ptr result = ScreenPointerForXY(gridStartX + this.x, gridStartY + this.y + 14);
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
	int frame;
	bool visible;
	bool falling;
	bool drawOnBack;
	function draw() {
		ptr dest = ScreenPointerForXY(gridStartX + this.x, gridStartY + this.y);
		ptr qPic = g.[spritesheet_p] + (this.image*32*4);
		if (this.visible == true) {
			PlotSheetSprite(qPic, dest, 32, 32, 256);
		}
	}
	function jump(newX, newY, newImage) {
		this.movex = newX;
		this.movey = newY;
		this.image = newImage;
		this.frame = 0;
		this.falling = false;
	}
	function isHit(int otherX, int otherY) : bool {
		return msvcrt.abs(otherX-this.x) < 16 && msvcrt.abs(otherY-this.y) < 16;
	}
	function isArrived() {
		return (this.falling == false and this.movex == 0 and this.movey == 0);
	}
	function move() {
		this.arrivedAtIndex = -1;

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
			if (this.y >= (528-gridStartY)) {
				this.visible = false;
				this.movex = 0;
				this.movey = 0;
				this.falling = false;
			}
		} else {
			if (this.movey < 0) {
				this.y = this.y - 3 + jumpSimulation[this.frame];
				this.movey = this.movey + 3;
			}
			if (this.movey > 0) {
				this.y = this.y + 3 + jumpSimulation[this.frame];
				this.movey = this.movey - 3;
			}
			this.frame = this.frame + 1;
		}
	}
	function reset() {
		this.frame = 0;
		this.movex = 0;
		this.movey = 0;
		this.visible = false;
		this.falling = false;
		this.drawOnBack = false;
		this.arrivedAtIndex = -1;
	}
}


CubeShape shape;
Actor bertus;
Actor ball;
Actor ball2;


function initBertus() {
	bertus.reset();
	shape.getXY(0);
	bertus.x = shape.x+16;
	bertus.y = shape.y;
	bertus.image = 7;
	bertus.visible = true;
}

function initBall() {
	ball.reset();
	shape.getXY(3);
	ball.x = shape.x+16;
	ball.y = 0-gridStartY;
	ball.image = 3;
	ball.visible = true;
	ball.falling = true;
}

function initBall2() {
	ball2.reset();
	shape.getXY(5);
	ball2.x = shape.x+16;
	ball2.y = 0-gridStartY+64;
	ball2.image = 3;
	ball2.visible = true;
	ball2.falling = true;
}


function GoLevel(int level) {
	bertus.reset();
	levelCompleteFramecount = 0;
	gameOverFramecount = 0;
	for (i in 0..48) { blockState[i] = 0; }
	if (level == 1) {
		levelShapePtr = &level1[0];
		levelShapeCount = sizeof(level1) / 8;
	}
	if (level == 2) {
		levelShapePtr = &level2[0];
		levelShapeCount = sizeof(level2) / 8;
	}
	for (i in 0..< shape.nrElements()) {
		int indexForElement = shape.getIndexForElement(i);
		blockState[indexForElement] = 3;
	}
	initBertus();
	initBall();
	initBall2();
}


function Draw() {
	if (bertus.drawOnBack == true) { bertus.draw(); }
	if (ball.drawOnBack == true)   { ball.draw(); }
	if (ball2.drawOnBack == true)  { ball2.draw(); }

	ptr destPtr;
	for (i in 0..< shape.nrElements()) {
		shape.getXY(i);
		destPtr = shape.getDestinationPointer(i);
		int indexForElement = shape.getIndexForElement(i);
		int blockImage = blockState[indexForElement];
		PlotSheetSprite(g.[spritesheet_p]+(blockImage*64*256*4), destPtr, 64, 64, 256);
	}

	if (bertus.drawOnBack == false) { bertus.draw(); }
	if (ball.drawOnBack == false)   { ball.draw(); }
	if (ball2.drawOnBack == false)  { ball2.draw(); }
}


function MoveElements() {
	bertus.move();
	if (frameCount % 3 == 0 or ball.falling)  {  ball.move(); }
	if (frameCount % 2 == 0 or ball2.falling) {	ball2.move(); }

	// Is Bertus or a ball arrived at a block?
	for (i in 0..< shape.nrElements()) {
		shape.getXY(i);
		int theIndex = shape.getIndexForElement(i);
		if (bertus.falling == false && bertus.x == (shape.x+16) && bertus.y == shape.y) {
			bertus.arrivedAtIndex = theIndex;
			blockState[theIndex] = 2;
		}
		int random = 0;
		if (ball.drawOnBack == false && ball.x == (shape.x+16) && ball.y == shape.y) {
			ball.arrivedAtIndex = theIndex;
			random = msys_frand(&seedRandom);
			if (random % 2 == 0) {
				ball.jump(32,48,3);
			} else {
				ball.jump(-32,48,3);
			}
		}
		if (ball2.drawOnBack == false && ball2.x == (shape.x+16) && ball2.y == shape.y) {
			ball2.arrivedAtIndex = theIndex;
			random = msys_frand(&seedRandom);
			if (random % 2 == 0) {
				ball2.jump(32,48,3);
			} else {
				ball2.jump(-32,48,3);
			}
		}
	}

	if (bertus.falling == false) {
		if (bertus.isHit(ball.x, ball.y)) {
			gameOverFramecount = 1;
		}
		if (bertus.isHit(ball2.x, ball2.y)) {
			gameOverFramecount = 1;
		}
	}

	if (bertus.isArrived() and bertus.arrivedAtIndex == -1) {
		bertus.falling = true;
		bertus.drawOnBack = true;
	}

	if (bertus.visible == false) { bertus.visible = true; gameOverFramecount = 1; }
	if (ball.visible == false) { initBall(); }
	if (ball2.visible == false) { initBall2(); }

	if (ball.falling == false and ball.isArrived() and ball.arrivedAtIndex == -1) {
		ball.falling = true;
		ball.drawOnBack = true;
	}

	if (ball2.falling == false and ball2.isArrived() and ball2.arrivedAtIndex == -1) {
		ball2.falling = true;
		ball2.drawOnBack = true;
	}

	// All blocks are stepped on?
	bool allBlocksHit = true;
	for (i in 0..48) {
		if (blockState[i] == 3) { allBlocksHit = false; }
	}
	if (allBlocksHit) {	levelCompleteFramecount = 1; }
}


// BEGIN Mainloop:

GoLevel(level);
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT) {
			StatusRunning = false;
		}
		if ((bertus.movex == 0) && (bertus.movey == 0)) {
			if (*eventType == g.SDL_EVENT_KEY_DOWN) {
				if (*eventScancode == g.SDL_SCANCODE_LEFT)  { bertus.jump(-32,-48,0); }    // naar boven links
				if (*eventScancode == g.SDL_SCANCODE_RIGHT) { bertus.jump(32,48,5); }      // naar onder rechts
				if (*eventScancode == g.SDL_SCANCODE_UP)    { bertus.jump(32,-48,1); }     // naar boven rechts
				if (*eventScancode == g.SDL_SCANCODE_DOWN)  { bertus.jump(-32,48,7); }     // naar onder links
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
		if (levelCompleteFramecount > 180) {
			level++;
			if (level > 2) { level = 1; }
			GoLevel(level);
		} else {
			for (i in 0..< shape.nrElements()) {
				shape.getXY(i);
				int theIndex = shape.getIndexForElement(i);
				int theBlockNr = 2;
				int remain = (levelCompleteFramecount / 10) % 2;
				if (remain == 1) { theBlockNr = 3; }
				blockState[theIndex] = theBlockNr;
			}
		}
	}

	if (gameOverFramecount > 0) {
		writeText(renderer, 100.0, 70.0, "*** Game over! ***");
		writeText(renderer, 100.0, 90.0, "    Try again...");
		gameOverFramecount++;
		if (gameOverFramecount > 180) {
			GoLevel(level);
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
