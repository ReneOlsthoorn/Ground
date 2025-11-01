

#define MAX_PATH 260

OPENFILENAMEA ofn;
byte[MAX_PATH] szFile = [ ] asm;
asm data {
align 8
lpstrFilter db 'All Files',0,'*.*',0
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

	ptr gameFile = msvcrt.fopen(szFile, "rb");
	if (gameFile == 0)
		return;
	msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_END);
	int gameSize = msvcrt.ftell(gameFile);
	msvcrt.fseek64(gameFile, 0, g.msvcrt_SEEK_SET);
	msvcrt.fread(loadFileBuffer, gameSize, 1, gameFile);
	msvcrt.fclose(gameFile);

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