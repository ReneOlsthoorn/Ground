// Precalculated colorcycling plasma with a smoothscroller. Optimized version.
#template retrovm
//https://lodev.org/cgtutor/plasma.html

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g
#include sidelib.g

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

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
string scrollText = "Smoothscroller written in Ground!                            You are very " + chr$(0x8f) + chr$(0x8f)+ " old " + chr$(0x8f) + chr$(0x8f) + " if you recognize the font.                   ";
bool StatusRunning = true;
bool thread1Busy = false;
bool thread2Busy = false;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
g.[screenmode] = g.TEXT1_FONT32;
g.[next_copperline] = -1;

byte[] font32_p_original = msvcrt.calloc(1, 256 * 32);
byte[] font256_p_original = msvcrt.calloc(1, 256 * 256);
g.[font32_p] = font32_p_original;
g.[font256_p] = font256_p_original;

g.[bg_image_p] = msvcrt.calloc(1, g.GC_Screen_DimX * g.GC_Screen_DimY * g.GC_ScreenPixelSize);
u32[960,560] bg_image = g.[bg_image_p];

asm data {plasma_p dq 0}
g.[plasma_p] = msvcrt.calloc(1, g.GC_Screen_DimX * g.GC_Screen_DimY * g.GC_ScreenPixelSize);
u32[960,560] plasma = g.[plasma_p];
asm data {plasma_palette dd 256 dup(0)}
u32[256] palette = g.plasma_palette;

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return (65536 * this.red) + (256 * this.green) + this.blue;
    }
}

for (int i = 0; i < 256; i++) {
	ColorRGB color;
    color.red = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 64.0)));
    color.green = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 128.0)));
    color.blue = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 256.0)));
    palette[i] = color.ToInteger();
}

byte[] font256OnDisk = sidelib.LoadImage("charset16x16.png");
if (font256OnDisk == null) {
	user32.MessageBox(null, "The font charset16x16.png cannot be found!", "Message", g.MB_OK);
	return;
}
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

function fillLine(int y, int charValue) {
    for (int x = 0; x < GC_Screen_TextColumns; x++) {
        screenArray[x,y] = charValue;
    }
}
// fill the screen with the special "bg_image" character (0xff)
for (int y = 0; y < GC_Screen_TextRows; y++) {
    if not (y >= whichLineToScroll-1 and y <= whichLineToScroll+1) {
        fillLine(y, 0xff);
    }
}
// fill the colors of the screen with backgroundcolor blue (value 6) and frontcolor lightblue (value e)
for (i = 0; i < g.GC_Screen_TextSize; i++) {
	colorsArray[i] = 0x6e;
}

// this moves the screentext 1 position to the left
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

// this rotates the special 0x8f character
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
ptr thread2Handle = GC_CreateThread(Thread2);
kernel32.SetThreadPriority(thread2Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.


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


bool plasmaArrayIsCalculated = false;

function PlasmaCalculation() {
	for (int y = 0; y < g.GC_Screen_DimY; y++) {
		for (int x = 0; x < g.GC_Screen_DimX; x++) {
			u32 pixelColor;

			//pixelColor = plasma[x, y];
			int xyBufferOffset;
			asm {
				mov	rax, [y@PlasmaCalculation]
				mov	rdx, GC_Screen_DimX*4
				mul	rdx
				mov r8, [x@PlasmaCalculation]
				shl r8, 2
				add	rax, r8
				mov	[xyBufferOffset@PlasmaCalculation], rax
				add	rax, [plasma_p]
				mov	edx, dword [rax]
				mov	[pixelColor@PlasmaCalculation], edx
			}

			if (plasmaArrayIsCalculated == false) {
				pixelColor = (128.0 + (127.0 * msvcrt.sin(x / 32.0)) +
						 128.0 + (127.0 * msvcrt.sin(y / 64.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt((x - g.GC_Screen_DimX / 2.0) * (x - g.GC_Screen_DimX / 2.0) + (y - g.GC_Screen_DimY / 2.0) * (y - g.GC_Screen_DimY / 2.0)) / 16.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt(x * x + y * y) / 64.0))
						 ) / 4;
				plasma[x,y] = pixelColor;
			}

			//bg_image[x, y] = palette[ (pixelColor + g.[frameCount]) % 256 ];
			asm {
				mov	edx, [pixelColor@PlasmaCalculation]
				add rdx, [frameCount]

				and rdx, 0xff
				shl	rdx, 2
				lea rax, [plasma_palette]
				mov	eax, [rax+rdx]

				mov rdx, [bg_image_p]
				mov	rcx, [xyBufferOffset@PlasmaCalculation]
				mov [rdx+rcx], eax
			}
		}
	}
	plasmaArrayIsCalculated = true;
}


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
	loopStartTicks = sdl2.SDL_GetTicks();

	if (thread1Busy) {
        xscrollNeedle++;
        if (xscrollNeedle == 16) {
            xscrollNeedle = 0;
            MoveScreenline(whichLineToScroll);
            screenArray[g.GC_Screen_TextColumns-1, whichLineToScroll] = scrollText[scrollTextNeedle++];
            if (scrollText[scrollTextNeedle] == 0) {
                scrollTextNeedle = 0;
				println("The Retro VM actually draws\r\nthe entire screen every frame,\r\nlike the legendary VIC-2 Chip\r\nfrom the Commodore 64.\r\n\r\nThe Retro VM has a textbuffer\r\nthat is able to scroll,\r\nand also to smoothscroll.\r\nIt also has Copper look-a-like functionality,\r\ninspired by the Amiga 500.\r\n");
            }
        }
        if (g.[frameCount] % 3 == 0) {
            RotateChar(0x8f);
        }

		PlasmaCalculation();

		int currentTicks = sdl2.SDL_GetTicks() - loopStartTicks;
		if (currentTicks < debugBestTicks) {
			debugBestTicks = currentTicks;
		}

		thread1Busy = false;
	}
	while (thread2Busy) { }

	sdl2.SDL_UnlockTexture(texture);
	sdl2.SDL_RenderCopy(renderer, texture, null, null);
	sdl2.SDL_RenderPresent(renderer);

	asm { inc [frameCount] }
}

sdl2.SDL_DestroyTexture(texture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

msvcrt.free(g.[font32_p]);
msvcrt.free(g.[font256_p]);
msvcrt.free(g.[colortable_p]);
msvcrt.free(g.[screentext1_p]);
msvcrt.free(g.[screentext4_p]);
msvcrt.free(g.[font32_charcolor_p]);
msvcrt.free(g.[bg_image_p]);
msvcrt.free(g.[plasma_p]);

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

string showStr = "Best innerloop time: " + debugBestTicks + "ms";
user32.MessageBox(null, showStr, "Message", g.MB_OK);
