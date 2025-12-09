// fire
// ground logo created using: https://fontmeme.com/futuristic-fonts/

#template sdl3

#include graphics_defines960x560.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sdl3_image sdl3_image.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll

#define nrPaletteElements 256

int frameCount = 0;
byte[SCREEN_WIDTH, SCREEN_HEIGHT] coolPixels = null;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
u32 seedRandom = 123123;
int coolmapWidth = SCREEN_WIDTH;
int coolmapHeight = SCREEN_HEIGHT;
u32[nrPaletteElements] palette = [];
int paletteCounter = 0;
int arraySize = SCREEN_WIDTH * SCREEN_HEIGHT;
coolPixels = msvcrt.calloc(1, arraySize);
byte[] fireBufferNew = msvcrt.calloc(1, arraySize);
byte[] fireBufferOld = msvcrt.calloc(1, arraySize);
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int pitch = SCREEN_LINESIZE;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
bool drawTheScene = true;
int coolingMapHeight = SCREEN_HEIGHT;
int coolingMapOffset = coolingMapHeight - 1;
asm data {logo_p dq 0}
g.[logo_p] = sidelib.LoadImage("image/groundlogo_960x109.png");
if (g.[logo_p] == null) {
	user32.MessageBox(null, "The groundlogo_960x109.png cannot be found!", "Message", g.MB_OK);
	return;
}


function msys_frand(u32* seed) : float
{
	seed[0] = seed[0] * 0x343FD + 0x269EC3;
	u32 a = (seed[0] >> 9) or 0x3f800000;

	float floatedA;
	asm {
		movss    xmm0, dword [a@msys_frand]
		cvtss2sd xmm1, xmm0
		movq     qword [floatedA@msys_frand], xmm1
	}
	float res = floatedA - 1.0;
	return res;
}

function SetWhites() {
	int aantalWhites = (coolmapHeight * coolmapWidth) / 50;
	int width = coolmapWidth - 6;
	int height = coolmapHeight - 6;
	for (int w = 0; w < aantalWhites; w++) {
		int newX = msys_frand(&seedRandom) * width;
		int newY = msys_frand(&seedRandom) * height;
		newX = newX + 3;
		newY = newY + 3;
		coolPixels[newX,newY] = 0xff;

		coolPixels[newX,(newY-1)] = 0xff;
		coolPixels[(newX-1),newY] = 0xff;
		coolPixels[(newX-1),(newY-1)] = 0xff;

		coolPixels[newX,(newY+1)] = 0xff;
		coolPixels[(newX+1),newY] = 0xff;
		coolPixels[(newX+1),(newY+1)] = 0xff;
	}
}

function AverageTheField() {
	int width = coolmapWidth - 2;
	int height = coolmapHeight - 2;
    for (int n = 0; n < 20; n++)
    {
        for (int x = 0; x < width; x++)
        {
            for (int y = 0; y < height; y++)
            {
				int theX = x + 1;
				int theY = y + 1;

                u32 coolValue = coolPixels[theX,theY] and 0xff;
                u32 coolBoven = coolPixels[theX,(theY-1)] and 0xff;
                u32 coolOnder = coolPixels[theX,(theY+1)] and 0xff;
                u32 coolLinks = coolPixels[(theX-1),theY] and 0xff;
                u32 coolRechts = coolPixels[(theX+1),theY] and 0xff;

				int average = coolValue + coolBoven + coolOnder + coolLinks + coolRechts;
				average = average / 5;
				coolPixels[theX,theY] = average;
            }
        }
    }
}

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() : int {
        return 0xff000000 + (this.red << 16) + (this.green << 8) + this.blue;
    }
}

function CreateGradient(int nrSteps, ColorRGB startColor, ColorRGB endColor) {
	ColorRGB color;
	float fSteps = nrSteps;

    for (int i = 0; i < nrSteps; i++) {
        color.red = startColor.red + (i * ((endColor.red - startColor.red) / fSteps));
        color.green = startColor.green + (i * ((endColor.green - startColor.green) / fSteps));
        color.blue = startColor.blue + (i * ((endColor.blue - startColor.blue) / fSteps));
        palette[paletteCounter] = color.ToInteger();
		paletteCounter++;
    }
}


// Create the coolingMap
SetWhites();
AverageTheField();

// Create the palette colors
CreateGradient(64, ColorRGB(0,0,0), ColorRGB(0x8b,0,0));
CreateGradient(64, ColorRGB(0x8b,0,0), ColorRGB(0xff,0,0));
CreateGradient(64, ColorRGB(0xff,0,0), ColorRGB(0xff,0xff,0));
CreateGradient(64, ColorRGB(0xff,0xff,0), ColorRGB(0xff,0xff,0xff));

// Create the Window
sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Fire", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

#include soundtracker.g
SoundtrackerInit("sound/mod/monday - random voice.mod", 127);


byte* stMod = null;
int stFile = msvcrt.fopen("sound/mod/monday - random voice.mod", "rb");
if (stFile != 0) {
	msvcrt.fseek64(stFile, 0, g.msvcrt_SEEK_END);
	int stSize = msvcrt.ftell(stFile);
	stMod = msvcrt.calloc(1, stSize);
	msvcrt.fseek64(stFile, 0, g.msvcrt_SEEK_SET);
	msvcrt.fread(stMod, stSize, 1, stFile);
	msvcrt.fclose(stFile);
} else
	return;

function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 2.0, 2.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}
function writeBytePtrText(ptr renderer, float x, float y, byte* text) {
	sdl3.SDL_SetRenderScale(renderer, 2.0, 2.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xef, 0xef, 0xef, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function PrintSongInfo() {
	writeBytePtrText(renderer, 10.0, 10.0, stMod);
	return;
	writeBytePtrText(renderer, 10.0, 10.0, *mikmodModule.songname);
	writeText(renderer, 10.0, 20.0, "Pattern position: " + *mikmodModule.patpos);
	writeText(renderer, 10.0, 30.0, "Song position: " + *mikmodModule.sngpos);
	writeText(renderer, 10.0, 40.0, "Number of patterns in song: " + *mikmodModule.numpat);
	writeText(renderer, 10.0, 50.0, "Number of positions in song: " + *mikmodModule.numpos);
}

while (StatusRunning)
{
	SoundtrackerUpdate();
	
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}
	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	loopStartTicks = sdl3.SDL_GetTicks();

	asm {SpeedFireLoop:}
	asm {
		mov	rcx, GC_SCREEN_WIDTH*(GC_SCREEN_HEIGHT-1)
		mov rdx, [fireBufferNew@main]
		add rdx, GC_SCREEN_WIDTH
		mov r8, [fireBufferOld@main]
		call Utils_CopyArray
	}

	coolingMapOffset = coolingMapOffset + 2;
	if (coolingMapOffset >= (coolingMapHeight-1))
		coolingMapOffset = 0;

	for (int f = 0; f < SCREEN_WIDTH; f++)
		fireBufferOld[(SCREEN_WIDTH*(SCREEN_HEIGHT-3))+f] = 0xff;

asm {
  push	rsi rdi
  mov	rcx, 0
  mov	rsi, [logo_p]
  mov	rdi, [fireBufferOld@main]
  add	rdi, GC_SCREEN_WIDTH*200
.logoPixel:
  mov	eax, [rsi+rcx*4]
  cmp	eax, 0
  je	.nextLogoPixel
  mov	al, 0xbf
  mov	[rdi+rcx], al
.nextLogoPixel:
  add	rcx, 1
  cmp	rcx, GC_SCREEN_WIDTH*108
  jne	.logoPixel
  pop	rdi rsi
}

	for (int y = 0; y < (SCREEN_HEIGHT-1); y++) {
		int coolingY = (y + coolingMapOffset) % SCREEN_HEIGHT;
		int coolingPosY = coolingY * SCREEN_WIDTH;
asm {
  mov	rcx, [y@main]
  mov	rdx, [coolingPosY@main]
  call	ASM_Fire
}
	}

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if ((currentTicks < 100) and (frameCount == 0)) {
asm {
  jmp	SpeedFireLoop
}
	}

	if (currentTicks < debugBestTicks)
		debugBestTicks = currentTicks;

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	PrintSongInfo();

	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

msvcrt.free(coolPixels);
msvcrt.free(fireBufferOld);
msvcrt.free(fireBufferNew);
msvcrt.free(stMod);
sidelib.FreeImage(g.[logo_p]);
SoundtrackerFree();

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);



asm procedures {
ASM_Fire:
	;rcx = y
	;rdx = coolingPosY
	push rsi
	push rdi
	push r12
	push r13
	push r14
	push r15

	mov r8, GC_SCREEN_HEIGHT
	sub r8d, ecx

	mov r9, [palette@main]
	mov	rax, r9
	call  GetMemoryPointerFromIndex
	mov r9, rax

	mov r11, 0
	mov r12, 0
	mov r10, [fireBufferNew@main]
	mov r15, [coolPixels@main]
	add r15, rdx                ; r15 = fire_coolingMap + coolingPosY
	mov rdi, [pixels_p]
	mov r14, [fireBufferOld@main]
	mov r13, GC_SCREEN_WIDTH

	mov eax, ecx
	mul r13d

	add r14, rax           ; r14 = fireBufferOld+(y*screenDimx)
	add r10, rax           ; r10 = fireBufferNew+(y*screenDimx)

	shl eax, 2             ; rdi = pixels+(y*screenDimx*4)
	add rdi, rax

	sub r13, 1			   ; fire-effect cannot do the first and last pixel.
	mov edx, 0

	mov ecx, 1				; fire-effect cannot do the first and last pixel.
.newPoint:
	mov eax, 0 
	mov r12b, [r15+rcx]    ;  BYTE cooling = coolingMap[coolingPosY+x]; al = cooling
	shr r12, 3
	mov r11b, [r14+rcx]    ;  BYTE fireValue = fireBufferOld[pos];
	mov dx, r11w
	add dx, r11w
	mov r11b, [r14+rcx+1]    ;  BYTE fireValue = fireBufferOld[pos];
	add dx, r11w
	mov r11b, [r14+rcx-1]    ;  BYTE fireValue = fireBufferOld[pos];
	add dx, r11w

	shr dx, 2
	mov r11w, dx

	sub r11w, r12w
	cmp r8w, 2
	jle .ClearAndNext
	cmp r11w, 22
	jge .volgende
.ClearAndNext:
	mov r11w, 0
	mov [r10+rcx], r11b
	mov dword [rdi+rcx*4], 0xff000000
	jmp .Next
.volgende:
	mov [r10+rcx], r11b

	mov eax, [r9+r11*4] ; lookup the fireGradient and put it an the screen.
	mov [rdi+rcx*4], eax
.Next:
	add ecx, 1

	cmp ecx, r13d
	jl .newPoint

	pop r15
	pop r14
	pop r13
	pop r12
	pop rdi
	pop rsi
	ret
}

