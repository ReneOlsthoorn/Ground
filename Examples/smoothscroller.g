
#template retrovm

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include sidelib.g

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Retro VM", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);
ptr texture = sdl2.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy);

u32[] pixels = null;
byte[56] event = [];
u32* eventType = &event[0];
int pitch = g.Graphics_ScreenLineSize;

int xscrollNeedle = 0;
int scrollTextNeedle = 0;
int whichLineToScroll = 16;
string scrollText = "Smoothscroller written in Ground!                            You are very old if you recognize the font.                   ";

int frameCount = 0;
bool StatusRunning = true;
bool thread1Busy = false;
bool thread2Busy = false;
g.[screenmode] = g.TEXT1_FONT32;
g.[next_copperline] = -1;

byte[] font32_p_original = msvcrt.calloc(1, 256 * 32);
byte[] font256_p_original = msvcrt.calloc(1, 256 * 256);
g.[font32_p] = font32_p_original;
g.[font256_p] = font256_p_original;

byte[] font256OnDisk = sidelib.LoadImage("charset16x16.png");
if (font256OnDisk == null) { return; }
sidelib.ConvertFonts(font256OnDisk, g.[font256_p], g.[font32_p]);
sidelib.FreeImage(font256OnDisk);

g.[colortable_p] = msvcrt.calloc(1, 256 * 4);
g.[screentext1_p] = msvcrt.calloc(1, g.GC_Screen_TextSize);
g.[screentext4_p] = msvcrt.calloc(1, g.GC_Screen_TextSize * 4);
g.[font32_charcolor_p] = msvcrt.calloc(1, g.GC_Screen_TextSize);

u32[256] colors = g.[colortable_p];
#include retrovm_colortable.g
insertColors(g.[colortable_p]);

byte[61,36] screenArray = g.[screentext1_p];
byte[61,36] colorsArray = g.[font32_charcolor_p];

function colorLine(int x, int colorValue) {
    for (int y=0; y<GC_Screen_TextRows; y++) {
        if not (y >= whichLineToScroll-1 and y <= whichLineToScroll+1) {
            colorsArray[x,y] = colorValue;
        } else {
            colorsArray[x,y] = 0x6e;
        }
    }
}

function fillLine(int y, int charValue) {
    for (int x=0; x < GC_Screen_TextColumns; x++) {
        screenArray[x,y] = charValue;
    }
}

int[] colorPairs = [ 0x01, 0x87, 0x6e, 0x5d, 0xba, 0xbc, 0x2a ];

// Fill the colors of the characters on the screen
for (int x = 0; x < GC_Screen_TextColumns; x++) {
    int choosenColor = colorPairs[(x / 12) % 5];
    colorLine(x, choosenColor);
}

// Fill the screen with the "rotating" character
for (int y = 0; y < GC_Screen_TextRows; y++) {
    if not (y >= whichLineToScroll-1 and y <= whichLineToScroll+1) {
        fillLine(y, 0x8f);
    }
}


function MoveScreenline(int lineNr) asm {
  push  r15 rsi rdi
  mov	r8, [screentext1_p]
  mov   rax, [lineNr@MoveScreenline]
  mov   rcx, GC_Screen_TextColumns
  mul   rcx
  add   r8, rax
  mov	rsi, r8
  inc	rsi
  mov	rdi, r8
  mov	rcx, GC_Screen_TextColumns-1
  rep movsb
  pop   rdi rsi r15
}


function RotateChar(int theChar) asm {
  mov   rax, [theChar@RotateChar]
  shl   rax, 5
  mov   r8, [font32_p]
  add   r8, rax

  mov   cx, word [r8]
  mov   rax, [r8+2]
  mov   [r8], rax
  mov   rax, [r8+10]
  mov   [r8+8], rax
  mov   rax, [r8+18]
  mov   [r8+16], rax
  mov   eax, [r8+26]
  mov   [r8+24], eax
  mov   ax, [r8+30]
  mov   [r8+28], ax
  mov   [r8+30], cx

  mov   rcx, 15
.loop:
  ror   word [r8+rcx*2], 1
  dec   rcx
  jns   .loop
}


function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
            asm { call DrawAllCRTLines }
			thread2Busy = false;
		}
	}
}

ptr threadId = 0;
kernel32.CreateThread(null, 0x10000, g.Thread2Startup, null, 0, &threadId);
asm {
  jmp	AfterThread2Startup
Thread2Startup:
  mov	rax, [main_rbp]
  mov	rbp, rax
}
Thread2();
kernel32.ExitThread(0);
asm {AfterThread2Startup: }


function GC_Copper(int line) {
    if (line == 0) {
        g.[next_copperline] = whichLineToScroll * 16;
        g.[xscroll] = 0;
    }
    if (line == whichLineToScroll * 16) {
        g.[next_copperline] = (whichLineToScroll+1) * 16;
        g.[xscroll] = xscrollNeedle;
    }
    if (line == (whichLineToScroll+1) * 16) {
        g.[xscroll] = 0;
        g.[next_copperline] = 0;
    }
}
asm {
  lea   rax, [_f_GC_Copper]
  mov   [user_copper_p], rax
}
g.[next_copperline] = 0;   // Default next_copperline is -1, which triggers nothing. Let's trigger line 0.


while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	sdl2.SDL_LockTexture(texture, null, &pixels, &pitch);

	g.[pixels_p] = pixels;
	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;

	if (thread1Busy) {

        xscrollNeedle++;
        if (xscrollNeedle == 16) {
            xscrollNeedle = 0;
            MoveScreenline(whichLineToScroll);
            screenArray[60, whichLineToScroll] = scrollText[scrollTextNeedle++];
            if (scrollText[scrollTextNeedle] == 0) {
                scrollTextNeedle = 0;
            }
        }
        if (frameCount % 2 == 0) {
            RotateChar(0x8f);
        }

		thread1Busy = false;
	}
	while (thread2Busy) { }

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

kernel32.WaitForSingleObject(threadId, -1);
kernel32.CloseHandle(threadId);

msvcrt.free(g.[font32_p]);
msvcrt.free(g.[font256_p]);
msvcrt.free(g.[colortable_p]);
msvcrt.free(g.[screentext1_p]);
msvcrt.free(g.[screentext4_p]);
msvcrt.free(g.[font32_charcolor_p]);
