

// Temporary variables:
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
bool FreezeThread2 = false;
bool Thread2Frozen = false;
byte[8] selectorPosition = [ ] asm;


class STARTUPINFOA {  //sizeof: 104 bytes
    u32 cb;
    ptr lpReserved;
    ptr lpDesktop;
    ptr lpTitle;
    u32 dwX;
    u32 dwY;
    u32 dwXSize;
    u32 dwYSize;
    u32 dwXCountChars;
    u32 dwYCountChars;
    u32 dwFillAttribute;
    u32 dwFlags;
    u16 wShowWindow;
    u16 cbReserved2;
    ptr lpReserved2;
    u64 hStdInput;
    u64 hStdOutput;
    u64 hStdError;
}
STARTUPINFOA si;
si.cb = sizeof(si);
si.dwFlags = g.kernel32_STARTF_USESHOWWINDOW;
si.wShowWindow = g.kernel32_SW_HIDE;
assert(sizeof(si)==104);


class PROCESS_INFORMATION {     //sizeof: 24 bytes
    u64 hProcess;
    u64 hThread;
    u32 dwProcessId;
    u32 dwThreadId;
}
PROCESS_INFORMATION pi;
assert(sizeof(pi)==24);


class SECURITY_ATTRIBUTES {   //sizeof: 24 bytes
    u32 nLength;
    ptr lpSecurityDescriptor;
    u32 bInheritHandle;
    u32 _filler;
}
SECURITY_ATTRIBUTES sa;
sa.nLength = sizeof(sa);
sa.lpSecurityDescriptor = null;
sa.bInheritHandle = true;
assert(sizeof(sa)==24);



class ClickableButton {
	int x;
	int y;
	int width;
	int height;
	bool clickState;
	bool leftAllowed;
	string label;

	function Init() {
		this.leftAllowed = true;
	}

	function IsWithin(int mouseX, int mouseY) : bool {
		return (mouseX >= this.x) and (mouseX <= (this.x + this.width)) and (mouseY >= this.y) and (mouseY <= (this.y + this.height));
	}
	function IsClicked() : bool {
		return this.clickState;
	}
	function Handle(int mouseX, int mouseY, bool leftPressed) {
		this.clickState = false;
		if (this.IsWithin(mouseX, mouseY)) {
			sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0x00, 0xff, 0xff);
			if (leftPressed and this.leftAllowed) {
				this.leftAllowed = false;
			} else if (!leftPressed and !this.leftAllowed) {
				this.clickState = true;
				this.leftAllowed = true;
			}
		} else {
			sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
			this.leftAllowed = true;
		}
		sdl3.SDL_RenderDebugText(renderer, this.x, this.y, this.label);
	}
}

ClickableButton buttonNewGame;
buttonNewGame.x = 825;
buttonNewGame.y = 20;
buttonNewGame.width = 70;
buttonNewGame.height = 12;
buttonNewGame.Init();
buttonNewGame.label = "New Game";

ClickableButton buttonMoveBack;
buttonMoveBack.x = 825;
buttonMoveBack.y = 40;
buttonMoveBack.width = 70;
buttonMoveBack.height = 12;
buttonMoveBack.Init();
buttonMoveBack.label = "Backspace";

ClickableButton buttonLoadTmp;
buttonLoadTmp.x = 825;
buttonLoadTmp.y = 100;
buttonLoadTmp.width = 70;
buttonLoadTmp.height = 12;
buttonLoadTmp.Init();
buttonLoadTmp.label = "Load TMP";

ClickableButton buttonSaveTmp;
buttonSaveTmp.x = 825;
buttonSaveTmp.y = 120;
buttonSaveTmp.width = 70;
buttonSaveTmp.height = 12;
buttonSaveTmp.Init();
buttonSaveTmp.label = "Save TMP";

ClickableButton buttonLoadFile;
buttonLoadFile.x = 825;
buttonLoadFile.y = 180;
buttonLoadFile.width = 70;
buttonLoadFile.height = 12;
buttonLoadFile.Init();
buttonLoadFile.label = "Load File ...";



function NrMoves() : int {
	return ((movesListNeedle - movesList) / BYTES_PER_MOVE);
}


function WaitingForWhite() : bool {
	return ((NrMoves() % 2) == 0);
}


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 3.0, 4.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

int writeBytePtrTextColor = 0;
function writeBytePtrText(ptr renderer, float x, float y, byte* text) {
	sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+1.0, y+1.0, text);
	if (writeBytePtrTextColor == 0)
		sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	if (writeBytePtrTextColor == 1)
		sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0x00, 0xff, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function PrintReady() {
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
    if (isWaitingForUser) {
		if (WaitingForWhite())
		    sdl3.SDL_RenderDebugText(renderer, 4.0, 4.0, "Move a white piece.");
		else
		    sdl3.SDL_RenderDebugText(renderer, 4.0, 4.0, "Move a black piece.");
    } else {
		sdl3.SDL_RenderDebugText(renderer, 4.0, 4.0, "Please wait.");
	}
}


function MakeThread2Freeze() {
	FreezeThread2 = true;
	while (!Thread2Frozen) {
		kernel32.Sleep(100);
	}
}


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


function PrintMoves() {
	if (NrMoves() == 0)
		return;

	if (stepNeedle != null)
		writeBytePtrTextColor = 1;

	float blackOffset = 80.0;
	string movesTxt = "White";
	writeBytePtrText(renderer, 4.0, 20.0, &movesTxt);
	movesTxt = "Black";
	writeBytePtrText(renderer, 4.0 + blackOffset, 20.0, &movesTxt);

	if (stepNeedle != null)
		writeBytePtrTextColor = 0;


	float yPos = 30.0;
	float xPos = 4.0;
	ptr movesNeedle = movesList;
	int counter = 0;
	while (movesNeedle < movesListNeedle) {
		if (stepNeedle != null and (movesNeedle == stepNeedle - BYTES_PER_MOVE))
			writeBytePtrTextColor = 1;
		writeBytePtrText(renderer, xPos, yPos, movesNeedle);
		writeBytePtrTextColor = 0;
		if (counter % 2 == 1) {
			xPos = xPos - 80.0;
			yPos = yPos + 10.0;
		} else {
			xPos = xPos + 80.0;
		}
		movesNeedle = movesNeedle + BYTES_PER_MOVE;
		counter++;
		if (counter == 106) {
			xPos = xPos + 800.0;
			yPos = yPos - 340.0;
		}
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


#define MAX_PATH 260

ptr loadFileBuffer = msvcrt.calloc(1, LOADFILEBUFFERSIZE);
OPENFILENAMEA ofn;
byte[MAX_PATH] szFile = [ ] asm;
asm data {
align 8
lpstrFilter db 'All Files',0,'*.*',0
}


function ReplayLoadedMoves() {
	bool mustFreeze = !Thread2Frozen;
	if (mustFreeze)
		MakeThread2Freeze();
	SetStartPosition();
	SetPiecesTextures();
	ptr movesNeedle = movesList;
	while (movesNeedle < movesListNeedle) {
		MovePiece(movesNeedle);
		movesNeedle = movesNeedle + BYTES_PER_MOVE;
	}
	if (mustFreeze)
		FreezeThread2 = false;
}


function ReplayTillStepNeedle() {
	bool mustFreeze = !Thread2Frozen;
	if (mustFreeze)
		MakeThread2Freeze();
	SetStartPosition();
	SetPiecesTextures();
	ptr movesNeedle = movesList;
	while (movesNeedle < stepNeedle) {
		MovePiece(movesNeedle);
		movesNeedle = movesNeedle + BYTES_PER_MOVE;
	}
	if (mustFreeze)
		FreezeThread2 = false;
}


function SaveTmpGame() {
	int gameFile = msvcrt.fopen("chessgame.bin", "wb");
	int gameFileSize = movesListNeedle - movesList;
	msvcrt.fwrite(movesList, gameFileSize, 1, gameFile);
	msvcrt.fclose(gameFile);
}


function LoadTmpGameFile() {
	int gameFile = msvcrt.fopen("chessgame.bin", "rb");
	if (gameFile != 0) {
		msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_END);
		int gameSize = msvcrt.ftell(gameFile);
		msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_SET);
		msvcrt.fread(movesList, gameSize, 1, gameFile);
		movesListNeedle = movesList + gameSize;
		msvcrt.fclose(gameFile);
		ReplayLoadedMoves();
	}
}


function AddToGameTitle(string content) {
	int strLen = gc.strlen(content);
	for (i in 0..< strLen) {
		*gameTitleNeedle = content[i];
		gameTitleNeedle++;
	}
}

function AddValueToGameTitle(string keyStr) {
	byte* result = msvcrt.strstr(loadFileBuffer, &keyStr);

	if (result != 0) {
		result = result + gc.strlen(keyStr);
		int strLen = gc.cstr_linelen(result);
		for (i in 0..< strLen) {
			*gameTitleNeedle = result[i];
			gameTitleNeedle++;
		}
	}
}


function SelectAndLoadFile() {
	zero(ofn);
	zero(szFile, MAX_PATH);

	ofn.lStructSize = sizeof(ofn);
	ofn.hwndOwner = null;
	ofn.lpstrFile = szFile;
	ofn.nMaxFile = MAX_PATH;
	ofn.lpstrFilter = g.lpstrFilter;
	ofn.nFilterIndex = 1;
	ofn.Flags = g.OFN_PATHMUSTEXIST | g.OFN_FILEMUSTEXIST | g.OFN_NOCHANGEDIR;

	bool isFileSelected = comdlg32.GetOpenFileNameA(ofn);
	if not (isFileSelected)
		return;

	stepNeedle = null;

	ptr gameFile = msvcrt.fopen(szFile, "rb");
	if (gameFile == 0)
		return;
	msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_END);
	int gameSize = msvcrt.ftell(gameFile);
	msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_SET);
	msvcrt.fread(loadFileBuffer, gameSize, 1, gameFile);
	msvcrt.fclose(gameFile);

	gameTitleNeedle = gameTitle;
	AddToGameTitle("Chess - ");
	AddValueToGameTitle("// Date:   ");
	AddToGameTitle(" - White: ");
	AddValueToGameTitle("// White:  ");
	AddToGameTitle(" - Black: ");
	AddValueToGameTitle("// Black:  ");
	AddToGameTitle(" - ");
	AddValueToGameTitle("// Result: ");
	*gameTitleNeedle = 0;
	sdl3.SDL_SetWindowTitle(window, gameTitle);

	byte* theBytes = loadFileBuffer;
	bool skipEntireLine = false;
	int moveIndex = 0;

	zero(movesList, MOVES_STORAGE * BYTES_PER_MOVE);
	movesListNeedle = movesList;

	for (i in 0..< gameSize) {
		byte readChar = theBytes[i];

		if (readChar == 0x0a) {
			skipEntireLine = false;
			moveIndex = 0;
			if (movesListNeedle[moveIndex] != 0)
				movesListNeedle = movesListNeedle + BYTES_PER_MOVE;
			continue;
		}
		if (skipEntireLine)
			continue;
		if (readChar == '/' or readChar == '[') {
			skipEntireLine = true;
			continue;
		}
		if (readChar == ' ' or readChar == 0x09) {  // 0x09 is tab
			moveIndex = 0;
			movesListNeedle = movesListNeedle + BYTES_PER_MOVE;
			continue;
		}
		movesListNeedle[moveIndex] = readChar;
		moveIndex++;
	}
	if (moveIndex >= 2)
		movesListNeedle = movesListNeedle + BYTES_PER_MOVE;

	isPlayingWhite = (NrMoves() % 2) == 0;
	ReplayLoadedMoves();
}

