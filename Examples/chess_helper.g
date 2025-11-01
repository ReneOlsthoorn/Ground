
// Temporary variables:
f32[4] srcRect = [];
f32[4] destRect = [];
f32[4] pieceSrcRect = [0,0,70,70];
f32[4] pieceDestRect = [0,0,70,70];
int RandomSeed = 123123;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
bool FreezeThread2 = false;
bool Thread2Frozen = false;

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


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 3.0, 4.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function writeBytePtrText(ptr renderer, float x, float y, byte* text) {
	sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+1.0, y+1.0, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}


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
