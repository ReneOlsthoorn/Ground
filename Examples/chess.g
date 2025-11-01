
#template sdl3

#define GRID_COLUMNS 8
#define GRID_ROWS 8
#define NR_PIECES 32
#define BLOCK_DIM 70
#define OFFSET_PIXELS_GRID_LEFT 200
#define MOVES_STORAGE 1000
#define BYTES_PER_MOVE 8
#define READBUFFERSIZE 32000
#define LOADFILEBUFFERSIZE 20000

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include comdlg32.g

bool isPlayingWhite = true;
bool modeElo1 = false;

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
string gameStatus = "game running";
byte* movesList = msvcrt.calloc(1, MOVES_STORAGE * BYTES_PER_MOVE);
byte* movesListNeedle = movesList;
ptr textInBuffer = msvcrt.calloc(1, READBUFFERSIZE);
ptr movesOutput = msvcrt.calloc(1, READBUFFERSIZE);
bool isWaitingForUser = false;
bool thread2Busy = true;
MouseState mouseState;
ptr loadFileBuffer = msvcrt.calloc(1, LOADFILEBUFFERSIZE);


sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Chess", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
sdl3.SDL_SetRenderVSync(renderer, 1);

#include chess_helper.g


class Piece {
	int gridX;		// 0..7
	int gridY;		// 0..7
	int x;			// somewhere on the screen
	int y;
	int type;		// 0 = Pawn, 1 = King, 2 = Queen, 3 = Rook, 4 = Bishop, 5 = Knight
	ptr texture;
	bool isWhite;
	bool visible;

	function IsKing() : bool { return (this.type == 1); }
	function IsPawn() : bool { return (this.type == 0); }

	function FillXY() {
		if not (this.visible)
			return;
		this.x = this.gridX * BLOCK_DIM + OFFSET_PIXELS_GRID_LEFT;
		this.y = this.gridY * BLOCK_DIM;
	}

	function Render() {
		if not (this.visible)
			return;
		pieceDestRect[0] = this.x;
		pieceDestRect[1] = this.y;
		sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
		sdl3.SDL_RenderTextureRotated(renderer, this.texture, pieceSrcRect, pieceDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}

	function FillFrom(int px, int py) {
		this.visible = true;
		int startX = px - OFFSET_PIXELS_GRID_LEFT;
		if (startX < 0) {
			this.visible = false;
			return;
		}
		if (startX >= GRID_COLUMNS*BLOCK_DIM) {
			this.visible = false;
			return;
		}
		this.gridX = startX / BLOCK_DIM;
		this.gridY = py / BLOCK_DIM;
		this.FillXY();
	}

	function GetAlphaPosition(byte* p) {
		p[0] = this.gridX + 'a';
		p[1] = '1' + (7 - this.gridY);
		p[2] = 0;
	}

	function HasPosition(byte* p) {
		if not (this.visible)
			return false;
		int startGridX = p[0] - 'a';
		int startGridY = 7-(p[1] - '1');
		bool result = (this.gridX == startGridX and this.gridY == startGridY);
		return result;
	}

	function SetPosition(byte* p) {
		if not (this.visible)
			return;
		this.gridX = p[0] - 'a';
		this.gridY = 7-(p[1] - '1');
		this.FillXY();
	}
}

function NrMoves() : int {
	return ((movesListNeedle - movesList) >> 3);
}

function WaitingForWhite() : bool {
	return ((NrMoves() % 2) == 0);
}

Piece[NR_PIECES] pieces = [ ];
Piece selector;			// Not a real piece. It is the selection when you go over a field with the mouse.
Piece startSelection;
Piece endSelection;

#include chess_texture_loading.g


function Init() {
	selector.visible = false;
	startSelection.visible = false;
	isWaitingForUser = false;
}
Init();


function SetStartPosition() {
	for (i in 0 ..< NR_PIECES) {
		pieces[i].visible = true;
		pieces[i].isWhite = false;
		if (i < 8) {
			pieces[i].gridX = i;
			pieces[i].gridY = 0;
		} else if (i < 16) {
			pieces[i].gridX = i-8;
			pieces[i].gridY = 1;
		} else if (i < 24) {
			pieces[i].gridX = i-16;
			pieces[i].gridY = 6;
		} else {
			pieces[i].gridX = i-24;
			pieces[i].gridY = 7;
		}
		pieces[i].FillXY();

		if (i >= 16)
			pieces[i].isWhite = true;
	}
}

function MakeThread2Freeze() {
	FreezeThread2 = true;
	while (!Thread2Frozen) {
		kernel32.Sleep(100);
	}
}

function RestartGame() {
	SetPiecesTextures();
	isWaitingForUser = false;
	gameStatus = "game running";
	SetStartPosition();
	movesListNeedle = movesList;
}
RestartGame();


function PrintMoves() {
	if (NrMoves() == 0)
		return;

	float blackOffset = 80.0;
	string movesTxt = "White";
	writeBytePtrText(renderer, 4.0, 20.0, &movesTxt);
	movesTxt = "Black";
	writeBytePtrText(renderer, 4.0 + blackOffset, 20.0, &movesTxt);

	float yPos = 30.0;
	float xPos = 4.0;
	ptr movesNeedle = movesList;
	int counter = 0;
	while (movesNeedle < movesListNeedle) {
		writeBytePtrText(renderer, xPos, yPos, movesNeedle);
		if (counter % 2 == 1) {
			xPos = xPos - 80.0;
			yPos = yPos + 10.0;
		} else {
			xPos = xPos + 80.0;
		}
		movesNeedle = movesNeedle + BYTES_PER_MOVE;
		counter++;
	}
}


function MovePiece(ptr moveStr) {
	byte* p = moveStr;
	if (p[0] == 0)
		return;
	for (i in 0 ..< NR_PIECES) {
		if (pieces[i].HasPosition(p+2))
			pieces[i].visible = false;
	}
	for (i in 0 ..< NR_PIECES) {
		if (pieces[i].HasPosition(p)) {
			int oldGridX = pieces[i].gridX;
			int oldGridY = pieces[i].gridY;
			pieces[i].SetPosition(p+2);
			int newGridX = pieces[i].gridX;
			int newGridY = pieces[i].gridY;

			// Check casting and perform Rook move.
			if (pieces[i].IsKing() and (msvcrt.abs(oldGridX-newGridX) == 2)) {
				if (pieces[i].isWhite and (pieces[i].gridX == 2)) {
					pieces[24].gridX = 3;
					pieces[24].FillXY();
				} else if (pieces[i].isWhite and (pieces[i].gridX == 6)) {
					pieces[31].gridX = 5;
					pieces[31].FillXY();
				} else if ((!pieces[i].isWhite) and (pieces[i].gridX == 6)) {
					pieces[7].gridX = 5;
					pieces[7].FillXY();
				} else if ((!pieces[i].isWhite) and (pieces[i].gridX == 2)) {
					pieces[0].gridX = 3;
					pieces[0].FillXY();
				}
			} else if (pieces[i].IsPawn() and newGridY == 0) {
				p[4] = 'q';
				p[5] = 0;
				pieces[i].type = 2; //transform into queen
				pieces[i].texture = pieceTextures[8];
			} else if (pieces[i].IsPawn() and newGridY == 7) {
				p[4] = 'q';
				p[5] = 0;
				pieces[i].type = 2; //transform into queen
				pieces[i].texture = pieceTextures[2];
			}
		}
	}
}


function WaitForChange() {
asm {
WaitForChangeRestart:
}
	Thread2Frozen = false;
	int oldNrMoves = NrMoves();
	while ((oldNrMoves == NrMoves()) and StatusRunning and !FreezeThread2) {
		isWaitingForUser = true;
		kernel32.Sleep(100);
	}
	while (FreezeThread2) {
		Thread2Frozen = true;
		kernel32.Sleep(100);
asm {
	jmp WaitForChangeRestart
}
	}

	isWaitingForUser = false;
	if (StatusRunning) {
		if ((oldNrMoves+1) == NrMoves())
			MovePiece(movesListNeedle-8);
	}
}


function AddComputerMove() : bool {
	string bestMoveStr = "bestmove ";
	byte* result = msvcrt.strstr(textInBuffer, &bestMoveStr);
	if (result == 0)
		return false;
	result = result + 9;  //length of "bestmove "

	int i = 0;
	byte* newMovesListNeedle = movesListNeedle;
	while ((result[i] != 0x20) and (result[i] != 0x0a) and (result[i] != 0)) {
		newMovesListNeedle[i] = result[i];
		i++;
	}
	newMovesListNeedle[i] = 0;
	movesListNeedle = movesListNeedle + BYTES_PER_MOVE;
	MovePiece(movesListNeedle-8);

	return true;
}


int hStdOutRead;
int hStdOutWrite;
int hStdInRead;
int hStdInWrite;
u32 bytesRead = 0;
u32 bytesWritten = 0;

function AppendToLog(ptr cstrBuffer) {
	/*
	int logFile = msvcrt.fopen("logfile.txt", "ab");
	msvcrt.fprintf(logFile, "%s", cstrBuffer);
	msvcrt.fclose(logFile);
	*/
}

function WriteToProcess(int stdInWrite, byte* data, u32* bytesWritten) : bool {
    return kernel32.WriteFile(stdInWrite, data, msvcrt.strlen(data), bytesWritten, null);
}

function ReadFromProcess(int stdOutRead, byte* buffer, u32 bufferSize, u32* bytesRead) : bool {
    buffer[0] = 0;
    bool result = kernel32.ReadFile(stdOutRead, buffer, bufferSize - 1, bytesRead, null);
    buffer[*bytesRead] = 0;
    return result;
}

function ReadFromStockFish(int sleepTime) : bool {
    kernel32.Sleep(sleepTime);
    bool result = ReadFromProcess(hStdOutRead, textInBuffer, READBUFFERSIZE, &bytesRead);
	AppendToLog(textInBuffer);
    return result;
}

function WriteToStockFish(byte* cmd) : bool {
	AppendToLog(cmd);
    return WriteToProcess(hStdInWrite, cmd, &bytesWritten);
}
function WriteToStockFishString(string cmd) : bool {
	AppendToLog(&cmd);
    return WriteToProcess(hStdInWrite, &cmd, &bytesWritten);
}

function InsertMoves() {
	byte* outputNeedle = movesOutput;
	int nrMoves = NrMoves();
	if (nrMoves == 0) {
		*outputNeedle = 0x0a;  // add a \n
		outputNeedle++;
		*outputNeedle = 0;
		outputNeedle++;
		WriteToStockFish(movesOutput);
		return;
	}
	WriteToStockFishString(" moves ");
	byte* movesNeedle = movesList;
	for (i in 0 ..< nrMoves) {
		for (j in 0..7) {
			byte byteToCopy = movesNeedle[j];
			if (byteToCopy != 0) {
				*outputNeedle = byteToCopy;
				outputNeedle++;
			}
		}
		*outputNeedle = 0x20;  // add a space
		outputNeedle++;
		movesNeedle = movesNeedle + BYTES_PER_MOVE;		
	}
	*outputNeedle = 0x0a;  // add a \n
	outputNeedle++;
	*outputNeedle = 0;
	outputNeedle++;
	WriteToStockFish(movesOutput);
}


function Thread2StockFish() {
    kernel32.CreatePipe(&hStdOutRead, &hStdOutWrite, &sa, 0);
    kernel32.SetHandleInformation(hStdOutRead, g.kernel32_HANDLE_FLAG_INHERIT, 0);

    kernel32.CreatePipe(&hStdInRead, &hStdInWrite, &sa, 0);
    kernel32.SetHandleInformation(hStdInWrite, g.kernel32_HANDLE_FLAG_INHERIT, 0);

    si.dwFlags = g.STARTF_USESTDHANDLES;
    si.hStdOutput = hStdOutWrite;
    si.hStdError = hStdOutWrite;
    si.hStdInput = hStdInRead;

	string exePath = "stockfish-windows-x86-64-avx2.exe";
	bool waarde = kernel32.CreateProcessA(exePath, null, null, null, true, g.kernel32_CREATE_NO_WINDOWS, null, null, &si, &pi);

	if not (waarde) {
		StatusRunning = false;
		return;
	}

    ReadFromStockFish(2000);
    WriteToStockFishString("uci\n");
    ReadFromStockFish(2000);
	if (modeElo1) {
		WriteToStockFishString("setoption name UCI_LimitStrength value true\n");
		WriteToStockFishString("setoption name UCI_Elo value 1\n");
	}
    WriteToStockFishString("isready\n");
    ReadFromStockFish(1000);

    WriteToStockFishString("ucinewgame\n");
	while (StatusRunning) {
		if not (NrMoves() == 0 and !isPlayingWhite)
			WaitForChange();
		if (StatusRunning) {
			WriteToStockFishString("position startpos");
			InsertMoves();
			WriteToStockFishString("go movetime 1000\n");

			bool moveFound = false;
			while (!moveFound) {
				ReadFromStockFish(2000);
				moveFound = AddComputerMove();
			}
		}
	}

	kernel32.CloseHandle(hStdInRead);
    kernel32.CloseHandle(hStdOutWrite);
    kernel32.CloseHandle(hStdOutRead);
    kernel32.CloseHandle(hStdInWrite);

	string terminateSuccessStr = "terminate success";
	int tm = kernel32.TerminateProcess(pi.hProcess, 0);
	if (tm != 0)
		AppendToLog(&terminateSuccessStr);

    kernel32.CloseHandle(pi.hProcess);
    kernel32.CloseHandle(pi.hThread);
	thread2Busy = false;
}
GC_CreateThread(Thread2StockFish);


function ReplayLoadedMoves() {
	bool mustFreeze = !Thread2Frozen;
	if (mustFreeze)
		MakeThread2Freeze();
	SetPiecesTextures();
	SetStartPosition();
	ptr movesNeedle = movesList;
	while (movesNeedle < movesListNeedle) {
		MovePiece(movesNeedle);
		movesNeedle = movesNeedle + BYTES_PER_MOVE;
	}
	if (mustFreeze)
		FreezeThread2 = false;
}

#include chess_file_handling.g


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
