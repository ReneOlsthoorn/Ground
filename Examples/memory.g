
#template sdl3


// DEFINES

#define START_LEVEL 1
#define WAITTIME_COMBINATION 45
#define WAITTIME_GAMEOVER 240
#define TILE_WIDTH 150
#define TILE_HEIGHT 150
#define OUTLINE_WIDTH 180
#define OUTLINE_HEIGHT 180
#define SHEET_NRS_WIDTH 6
#define MAX_ITEMS 28


// GENERIC INCLUDES

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library soloud soloud_x64.dll


// GENERIC GLOBAL VARIABLES

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int screenpitch = SCREEN_LINESIZE;


// CREATING A WINDOW

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Memory", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_SetRenderVSync(renderer, 1);


// SPECIFIC GLOBAL VARIABLES

int level;
int turnsRemaining;
int nrTilesX;
int nrTilesY;
int nrTiles;
int turnWaitCounter = 0;		// after a turn, the computer waits WAITTIME_COMBINATION frames.
int gameOverWaitCounter = 0;	// after a game over, the computer waits WAITTIME_GAMEOVER frames.
string gameStatus = "next level";    // "game running", "next level", "game over", "game completed"
f32[4] sheetSrcRect = [5*TILE_WIDTH,0,TILE_WIDTH,TILE_HEIGHT];
f32[4] itemDestRect = [0,0,TILE_WIDTH,TILE_HEIGHT];
f32[4] closedOutlineSrcRect = [0,0,OUTLINE_WIDTH,OUTLINE_HEIGHT];
f32[4] openedOutlineSrcRect = [0,OUTLINE_HEIGHT,OUTLINE_WIDTH,OUTLINE_HEIGHT];
f32[4] outlineDestRect = [0,0,OUTLINE_WIDTH,OUTLINE_HEIGHT];
MouseState mouseState;


// LOADING RESOURCES

ptr tmpSurface = sdl3_image.IMG_Load("image/memory_tiles.jpg");
if (tmpSurface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr sheetTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tmpSurface);
sdl3.SDL_SetTextureScaleMode(sheetTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(tmpSurface);

tmpSurface = sdl3_image.IMG_Load("image/memory_outline.png");
if (tmpSurface == null) { user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK); return; }
ptr outlineTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tmpSurface);
sdl3.SDL_SetTextureScaleMode(outlineTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(tmpSurface);


// SOUND RELATED

ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;

ptr sfxr1 = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(sfxr1, "sound/sfxr/select.sfs");
if (sfxrLoaded != 0) return;
soloud.Sfxr_setVolume(sfxr1, 1.0);
function PlaySound1() { soloud.Soloud_play(soloudObject, sfxr1); }

ptr sfxr2 = soloud.Sfxr_create();
sfxrLoaded = soloud.Sfxr_loadParams(sfxr2, "sound/sfxr/coin.sfs");
if (sfxrLoaded != 0) return;
soloud.Sfxr_setVolume(sfxr2, 1.0);
function PlaySound2() { soloud.Soloud_play(soloudObject, sfxr2); }


// SCREEN MESSAGES

f32 fontScale = 3.0;
function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, fontScale, fontScale);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x80, 0x80, 0x80, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+1.0, y+1.0, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x40, 0x40, 0x4f, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function NextLevelInformation() {
	if (level > 1)
		writeText(renderer, 120.0, 30.0,  "       Good Job!   ");

	writeText(renderer, 120.0, 60.0,  "        Level " + level);
	writeText(renderer, 120.0, 90.0,  "Solve the memory puzzle");
	writeText(renderer, 120.0, 110.0,  " consisting of " + nrTiles + " cards");
	writeText(renderer, 120.0, 130.0, "    within " + turnsRemaining + " turns.");
	writeText(renderer, 120.0, 160.0, " Press [space] to start.");
}

function ShowTurnsRemaining() {
    fontScale = 2.0;
	writeText(renderer, 10.0, 175.0,  "Turns left: " + turnsRemaining);
    fontScale = 3.0;
}

function GameOverInformation() {
	writeText(renderer, 120.0, 90.0,  "      Game over! ");
}

function GameCompletedInformation() {
	writeText(renderer, 120.0, 60.0,  "       Good Job!   ");
	writeText(renderer, 120.0, 80.0,  " You completed all levels!");
	writeText(renderer, 120.0, 100.0,  "   Thanks for playing.");
}


// LOGIC

class Item {
	int	x;
	int y;
	bool clickState;
	bool leftAllowed;
	bool picVisible;
	bool visible;
	int picIndex;

	function Init() {
		this.leftAllowed = true;
	}
	function IsWithin(int mouseX, int mouseY) : bool {
		return (mouseX >= this.x) and (mouseX <= (this.x + OUTLINE_WIDTH)) and (mouseY >= this.y) and (mouseY <= (this.y + OUTLINE_HEIGHT));
	}
	function IsClicked() : bool {
		return this.clickState;
	}
	function Handle(int mouseX, int mouseY, bool leftPressed) {
		if not (this.visible)
			return;
		this.clickState = false;
		if (this.IsWithin(mouseX, mouseY)) {
			if (leftPressed and this.leftAllowed) {
				this.leftAllowed = false;
			} else if (!leftPressed and !this.leftAllowed) {
				this.clickState = true;
				this.leftAllowed = true;
				this.picVisible = true;
			}
		} else
			this.leftAllowed = true;
	}
	function Render() {
		if not (this.visible)
			return;
		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		outlineDestRect[0] = this.x;
		outlineDestRect[1] = this.y;
		if (this.picVisible)
			sdl3.SDL_RenderTextureRotated(renderer, outlineTexture, openedOutlineSrcRect, outlineDestRect, 0.0, null, g.SDL_FLIP_NONE);
		else
			sdl3.SDL_RenderTextureRotated(renderer, outlineTexture, closedOutlineSrcRect, outlineDestRect, 0.0, null, g.SDL_FLIP_NONE);
		itemDestRect[0] = this.x+10;
		itemDestRect[1] = this.y+12;

		int rijNr = this.picIndex / SHEET_NRS_WIDTH;
		int offsetInRij = this.picIndex % SHEET_NRS_WIDTH;
		sheetSrcRect[0] = offsetInRij*TILE_WIDTH;
		sheetSrcRect[1] = rijNr*TILE_HEIGHT;
		if (this.picVisible)
			sdl3.SDL_RenderTextureRotated(renderer, sheetTexture, sheetSrcRect, itemDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}
}
Item[MAX_ITEMS] items = [];


function AllCardsSolved() : bool {
	for (i in 0..< nrTiles)
		if (items[i].visible)
			return false;
	return true;
}


function TwoPicturesTurned() : bool {
	int nrTurned = 0;
	for (i in 0..< nrTiles) {
		if (items[i].visible and items[i].picVisible)
			nrTurned++;
	}
	return (nrTurned == 2);
}


function IsSamePicturesTurned() : bool {
	int nrTurned = 0;
	int firstItemIndex = 0;
	for (i in 0..< nrTiles) {
		if (items[i].visible and items[i].picVisible) {
			nrTurned++;
			if (nrTurned == 1)
				firstItemIndex = i;
			if (nrTurned == 2)
				return (items[i].picIndex == items[firstItemIndex].picIndex);
		}
	}
	return false;
}


function HandleSamePictureTurned() : bool {
	int nrTurned = 0;
	int firstItemIndex = 0;
	for (i in 0..< nrTiles) {
		if (items[i].visible and items[i].picVisible) {
			nrTurned++;
			if (nrTurned == 1)
				firstItemIndex = i;
			if (nrTurned == 2) {
				if (items[i].picIndex == items[firstItemIndex].picIndex) {
					items[i].visible = false;
					items[firstItemIndex].visible = false;
					PlaySound2();
					return true;
				} else {
					items[i].picVisible = false;
					items[firstItemIndex].picVisible = false;
					return false;
				}
			}
		}
	}
	return false;
}


function HasPicIndex(int searchIndex) : bool {
	for (i in 0..< nrTiles) {
		if (items[i].picIndex == searchIndex)
			return true;
	}
	return false;
}


function Game(int tilesX, int tilesY, int turns) {
	nrTilesX = tilesX;
	nrTilesY = tilesY;
	nrTiles = tilesX * tilesY;
	turnsRemaining = turns;

	for (i in 0..< nrTiles) {
		items[i].Init();
		items[i].picVisible = false;
		items[i].picIndex = -1;
		items[i].visible = true;
	}

	int nrPics = nrTiles / 2;
	int nrTilesAllocated = 0;
	for (i in 1..nrPics) {
		int chosenPic = sdl3.SDL_rand(51);
		while (HasPicIndex(chosenPic)) {
			chosenPic = sdl3.SDL_rand(51);
		}
		int nrFreePlaces = nrTiles - nrTilesAllocated;
		int picToSet = sdl3.SDL_rand(nrFreePlaces);
		int picNr = 0;
		for (j in 0..< nrTiles) {
			if (items[j].picIndex == -1) {
				if (picToSet == picNr) {
					items[j].picIndex = chosenPic;
					nrTilesAllocated++;
					break;
				}
				picNr++;
			}				
		}
		nrFreePlaces = nrTiles - nrTilesAllocated;
		picToSet = sdl3.SDL_rand(nrFreePlaces);
		picNr = 0;
		for (j in 0..< nrTiles) {
			if (items[j].picIndex == -1) {
				if (picToSet == picNr) {
					items[j].picIndex = chosenPic;
					nrTilesAllocated++;
					break;
				}
				picNr++;
			}				
		}
	}

	int totalWidth = nrTilesX * OUTLINE_WIDTH;
	int totalHeight = nrTilesY * OUTLINE_HEIGHT;
	int leftOffset = (SCREEN_WIDTH - totalWidth) / 2;
	int topOffset = (SCREEN_HEIGHT - totalHeight) / 2;

	int counter = 0;
	for (y in 0..< nrTilesY) {
		for (x in 0..< nrTilesX) {
			items[counter].x = leftOffset + (x * OUTLINE_WIDTH);
			items[counter].y = topOffset + (y * OUTLINE_HEIGHT);
			counter++;
		}
	}
}


function SetLevel(int theLevel) : bool {
	level = theLevel;
	if (level == 1)
		Game(2,2,2);	// 4 pictures = 2 turns all revealed.
	else if (level == 2)
		Game(2,3,4);	// 6 pictures = 3 turns all revealed. Plus 1.
	else if (level == 3)
		Game(4,3,8);	// 12 pictures = 6 turns all revealed. Plus 2.
	else if (level == 4)
		Game(4,4,13);	// 16 pictures = 8 turns all revealed. Plus 6.
	else if (level == 5)
		Game(5,4,20);	// 20 pictures = 10 turns all revealed. Plus 10.
	else if (level == 6)
		Game(6,4,26);	// 24 pictures = 12 turns all revealed. Plus 14.
	else if (level == 7)
		Game(7,4,32);	// 28 pictures = 14 turns all revealed. Plus 18.
	else
		return false;
	return true;
}


// INIT

// The initial white fill of the background texture using Lock & Unlock.
sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
g.[pixels_p] = pixels;
GC_ClearScreenPixels(0xffffffff);
sdl3.SDL_UnlockTexture(texture);

SetLevel(START_LEVEL);
gameStatus = "next level";


// MAINLOOP

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running")
					gameStatus = "game running";
			}
		}
	}

	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	mouseState.GetMouseState();
	if ((gameStatus == "next level") and mouseState.LeftWasClicked)
		gameStatus = "game running";

	for (i in 0..< nrTiles) {
		if not (items[i].visible)
			continue;
		bool oldPicVisible = items[i].picVisible;
		if (turnWaitCounter == 0 and (gameStatus == "game running")) {
			items[i].Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
			if (items[i].IsClicked()) {
				if (!oldPicVisible and items[i].picVisible)
					PlaySound1();
				if (TwoPicturesTurned() and (turnWaitCounter == 0)) {
					turnWaitCounter = WAITTIME_COMBINATION;
					if not (IsSamePicturesTurned())
						turnsRemaining = turnsRemaining - 1;
						if (turnsRemaining == 0) {
							gameStatus = "game over";
							gameOverWaitCounter = WAITTIME_GAMEOVER;
						}
				}
			}
		}
		items[i].Render();
	}

	if (gameStatus == "next level")
		NextLevelInformation();

	if (gameStatus == "game running")
		ShowTurnsRemaining();

	if (gameStatus == "game over")
		GameOverInformation();

	if (gameStatus == "game completed")
		GameCompletedInformation();

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
	if (turnWaitCounter > 0) {
		turnWaitCounter = turnWaitCounter - 1;
		if (turnWaitCounter == 0) {
			if (HandleSamePictureTurned()) {
				if (AllCardsSolved()) {
					level++;
					gameStatus = "next level";
					if not (SetLevel(level))
						gameStatus = "game completed";
				}
			}
		}
	}
	if (gameOverWaitCounter > 0) {
		gameOverWaitCounter = gameOverWaitCounter - 1;
		if (gameOverWaitCounter == 0) {
			SetLevel(1);
			gameStatus = "next level";
		}
	}
}

soloud.Sfxr_destroy(sfxr2);
soloud.Sfxr_destroy(sfxr1);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);

sdl3.SDL_DestroyTexture(outlineTexture);
sdl3.SDL_DestroyTexture(sheetTexture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
