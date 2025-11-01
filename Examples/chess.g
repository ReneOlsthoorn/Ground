
#template sdl3


// DEFINES

#define GRID_COLUMNS 8
#define GRID_ROWS 8
#define NR_PIECES 32
#define BLOCK_DIM 70
#define OFFSET_PIXELS_GRID_LEFT 200
#define MOVES_STORAGE 1000
#define BYTES_PER_MOVE 8
#define READBUFFERSIZE 32000
#define LOADFILEBUFFERSIZE 20000


// GENERIC INCLUDES

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include comdlg32.g


// SETTINGS

bool isPlayingWhite = true;
bool modeELO_1 = false;		// false: stockfish will beat you.  true: maybe you have a chance.


// GENERIC GLOBAL VARIABLES

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
string gameStatus = "game running";
bool thread2Busy = true;
MouseState mouseState;


// CREATING A WINDOW

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Chess", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
sdl3.SDL_SetRenderVSync(renderer, 1);

#include chess_piece.g


// SPECIFIC GLOBAL VARIABLES

byte* movesList = msvcrt.calloc(1, MOVES_STORAGE * BYTES_PER_MOVE);
byte* movesListNeedle = movesList;
bool isWaitingForUser = false;
Piece[NR_PIECES] pieces = [ ];
Piece selector;			// Not a real piece. It is the selection when you go over a field with the mouse.
Piece startSelection;
Piece endSelection;

#include chess_texture.g
#include chess_helper.g
#include chess_thread2.g


function Init() {
	selector.visible = false;
	startSelection.visible = false;
	isWaitingForUser = false;
}

function RestartGame() {
	Init();
	gameStatus = "game running";
	SetStartPosition();
	SetPiecesTextures();
	movesListNeedle = movesList;
}
RestartGame();


// MAINLOOP

bool moveSelectionLeftAllowed = true;
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen") { 
						gameStatus = "game running";
					} else { 
						RestartGame();
					}
				}
			}
		}
	}

	mouseState.GetMouseState();

	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	if (gameStatus == "game running") {
		for (i in 0 ..< NR_PIECES)
			pieces[i].Render();

		selector.FillFrom(mouseState.x, mouseState.y);
		selector.GetAlphaPosition(selectorPosition);
		writeBytePtrText(renderer, 940.0, 550.0, selectorPosition);
		selector.Render();

		PrintMoves();

		if (mouseState.LeftPressed and moveSelectionLeftAllowed) {
			if (startSelection.visible) {
				endSelection.FillFrom(mouseState.x, mouseState.y);
				moveSelectionLeftAllowed = false;

				if ((endSelection.gridX == startSelection.gridX) and (endSelection.gridY == startSelection.gridY)) {
					startSelection.visible = false;
					endSelection.visible = false;			
				} else {
					// Store a new move
					startSelection.GetAlphaPosition(movesListNeedle);
					endSelection.GetAlphaPosition(movesListNeedle+2);
					movesListNeedle = movesListNeedle + BYTES_PER_MOVE;

					startSelection.visible = false;
					endSelection.visible = false;
				}
			} else {
				startSelection.FillFrom(mouseState.x, mouseState.y);
				moveSelectionLeftAllowed = false;
			}
		} else if (!mouseState.LeftPressed and !moveSelectionLeftAllowed) {
			moveSelectionLeftAllowed = true;
		}

		startSelection.Render();
	}

	sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	PrintReady();

	buttonNewGame.Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
	if (buttonNewGame.IsClicked()) {
		MakeThread2Freeze();
		RestartGame();
		FreezeThread2 = false;
	}
		
	buttonMoveBack.Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
	if (buttonMoveBack.IsClicked()) {
		MakeThread2Freeze();
		if (movesListNeedle > movesList)
			movesListNeedle = movesListNeedle - 8;
		SetPiecesTextures();
		SetStartPosition();
		ReplayLoadedMoves();
		FreezeThread2 = false;
	}

	buttonLoadTmp.Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
	if (buttonLoadTmp.IsClicked()) {
		MakeThread2Freeze();
		LoadTmpGameFile();
		FreezeThread2 = false;
	}

	buttonSaveTmp.Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
	if (buttonSaveTmp.IsClicked()) {
		MakeThread2Freeze();
		SaveTmpGame();
		FreezeThread2 = false;
	}

	buttonLoadFile.Handle(mouseState.x, mouseState.y, mouseState.LeftPressed);
	if (buttonLoadFile.IsClicked()) {
		MakeThread2Freeze();
		SelectAndLoadFile();
		FreezeThread2 = false;
	}

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

while (thread2Busy) { }

FreePieceTextures();
msvcrt.free(movesList);
msvcrt.free(textInBuffer);
msvcrt.free(movesOutput);
msvcrt.free(loadFileBuffer);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
