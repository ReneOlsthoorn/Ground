
// Temporary variables:
f32[4] srcRect = [];
f32[4] destRect = [];
f32[4] pieceSrcRect = [];
pieceSrcRect[0] = 0;  pieceSrcRect[1] = 0; pieceSrcRect[2] = 70; pieceSrcRect[3] = 70;
f32[4] pieceDestRect = [];
pieceDestRect[2] = 70; pieceDestRect[3] = 70;
int RandomSeed = 123123;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = g.GC_ScreenLineSize;


class STARTUPINFOA {
    u32 cb;
    u32 _filler01;
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
    u32 _filler02;
    ptr lpReserved2;
    u64 hStdInput;
    u64 hStdOutput;
    u64 hStdError;
} // 104 bytes

STARTUPINFOA si;
si.cb = 104;
si.dwFlags = g.kernel32_STARTF_USESHOWWINDOW;
si.wShowWindow = g.kernel32_SW_HIDE;


class PROCESS_INFORMATION {
    u64 hProcess;
    u64 hThread;
    u32 dwProcessId;
    u32 dwThreadId;
} // 24 bytes

PROCESS_INFORMATION pi;


class SECURITY_ATTRIBUTES {
    u32 nLength;
    u32 _filler01;
    ptr lpSecurityDescriptor;
    u32 bInheritHandle;
    u32 _filler02;
} // 24 bytes

SECURITY_ATTRIBUTES sa;
sa.nLength = 24;
sa.lpSecurityDescriptor = null;
sa.bInheritHandle = true;


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

function PrintReady() {
    if (isWaitingForUser) {
	    sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);
	    sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	    sdl3.SDL_RenderDebugText(renderer, 4.0, 4.0, "Ready.");
    }
}
