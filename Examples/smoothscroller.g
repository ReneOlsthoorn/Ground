
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
int frameCount = 0;
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
u32[256] palette = g.plasma_palette;

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
for (int i = 0; i < g.GC_Screen_TextSize; i++) {
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
			u32 pixelColor = plasma[x, y];

			if (plasmaArrayIsCalculated == false) {
				pixelColor = (128.0 + (127.0 * msvcrt.sin(x / 32.0)) +
						 128.0 + (127.0 * msvcrt.sin(y / 64.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt((x - g.GC_Screen_DimX / 2.0) * (x - g.GC_Screen_DimX / 2.0) + (y - g.GC_Screen_DimY / 2.0) * (y - g.GC_Screen_DimY / 2.0)) / 16.0)) + 
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt(x * x + y * y) / 64.0))
						 ) / 4;
				plasma[x,y] = pixelColor;
			}

			bg_image[x, y] = palette[ (pixelColor + frameCount) % 256 ];
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
            }
        }
        if (frameCount % 3 == 0) {
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

	frameCount++;
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

asm data {
plasma_palette dd 4286808187,4287268223,4288187783,4288975755,4289698188,4290420368,4291405459,4291931030
dd 4292653207,4293113497,4293639326,4294034338,4294297509,4294626474,4294824366,4294956466
dd 4294957490,4294893237,4294894520,4294633658,4294306492,4293979838,4293521856,4293129669
dd 4292605382,4292082122,4291361744,4290575826,4289723859,4288937683,4288216529,4287561684
dd 4286513112,4285792219,4285136606,4284350175,4283498211,4282580197,4281989863,4281334249
dd 4280743146,4280349676,4279824108,4279364589,4278970608,4278642418,4278247923,4278247413
dd 4278246133,4278245112,4278440440,4278701305,4279092729,4279353339,4279745275,4280203261
dd 4280529151,4281183231,4281902591,4282753023,4283472126,4284322302,4284976382,4285761278
dd 4286611455,4287461631,4288050431,4288900607,4289816318,4290666750,4291320317,4291974397
dd 4292431868,4293020668,4293412604,4293870075,4294195708,4294521850,4294847992,4294912502
dd 4294911222,4294910452,4294582002,4294384623,4294121712,4293858542,4293529837,4293201390
dd 4292610281,4292085738,4291364071,4290511845,4289594082,4288872928,4288086237,4287365339
dd 4286513369,4285727448,4285006037,4284285394,4283433682,4282647503,4281861582,4281207243
dd 4280748489,4280225221,4279635905,4279243453,4278851258,4278589622,4278459832,4278329524
dd 4278265265,4278331565,4278463915,4278661545,4278794404,4279123618,4279649695,4279912859
dd 4280635289,4281160596,4282014355,4282802576,4283459465,4284247431,4284839047,4285561218
dd 4286611584,4287399291,4288187516,4288910202,4289698164,4290486128,4291405422,4292062313
dd 4292587366,4293112930,4293639264,4294099550,4294362971,4294560855,4294693208,4294891091
dd 4294957902,4294893385,4294828617,4294567751,4294371910,4293913922,4293455679,4292997947
dd 4292605242,4291885111,4291230259,4290575665,4289723952,4289068845,4288347945,4287561511
dd 4286578213,4285792036,4285070881,4284349981,4283432477,4282580250,4281858582,4281334039
dd 4280677908,4280283923,4279758095,4279364366,4279036174,4278576906,4278313482,4278247175
dd 4278246153,4278310663,4278439941,4278635266,4279092483,4279419138,4279811077,4280137219
dd 4280529410,4281183490,4281837057,4282621696,4283406336,4284256768,4284910848,4285630208
dd 4286545920,4287265280,4287985153,4288835585,4289750784,4290601216,4291320064,4291974144
dd 4292562690,4293019907,4293412100,4293869318,4294195208,4294521352,4294782217,4294912266
dd 4294910985,4294910218,4294712588,4294449677,4294186513,4293792529,4293528850,4293200916
dd 4292544275,4292019733,4291363862,4290577178,4289659677,4288807454,4288282658,4287431203
dd 4286447653,4285595941,4285005864,4284153899,4283367984,4282582067,4281730101,4281141046
dd 4280617273,4280028472,4279635771,4279177789,4278785602,4278524487,4278459466,4278263884
dd 4278199631,4278200912,4278464084,4278596183,4278794073,4279188830,4279649635,4280044132
dd 4280635239,4281226345,4282079852,4282671214,4283524464,4284181620,4284970108,4285561729
}

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
