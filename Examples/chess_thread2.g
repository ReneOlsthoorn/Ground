

ptr textInBuffer = msvcrt.calloc(1, READBUFFERSIZE);
ptr movesOutput = msvcrt.calloc(1, READBUFFERSIZE);


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
	bool freezeWasCommanded = FreezeThread2;
	while (FreezeThread2) {
		Thread2Frozen = true;
		kernel32.Sleep(100);
	}

	if (freezeWasCommanded) {
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
	zero(newMovesListNeedle, 8);
	while ((result[i] >= '0' and result[i] <= '9') or (result[i] >= 'a' and result[i] <= 'z')) {
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
			} else {
				break; // once found a zero, quit.
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
	if (modeELO_1) {
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

