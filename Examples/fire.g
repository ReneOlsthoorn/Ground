// fire
// ground logo created using: https://fontmeme.com/futuristic-fonts/

#template sdl3

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g

int frameCount = 0;
u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;

int arraySize = SCREEN_WIDTH * SCREEN_HEIGHT;
byte[] fireBufferNew = msvcrt.calloc(1, arraySize);
byte[] fireBufferOld = msvcrt.calloc(1, arraySize);


int coolmapFile = msvcrt.fopen("fire_coolmap.bin", "rb");
byte[] coolmapPointer = msvcrt.calloc(1, arraySize);
msvcrt.fread(coolmapPointer, 1, arraySize, coolmapFile);
msvcrt.fclose(coolmapFile);

#define palette_nr_elements 256
int paletteFile = msvcrt.fopen("fire_palette.bin", "rb");
u32[palette_nr_elements] palette = [];
msvcrt.fread(palette, SCREEN_PIXELSIZE, palette_nr_elements, paletteFile);
msvcrt.fclose(paletteFile);


sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Fire", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);

byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int pitch = g.GC_ScreenLineSize;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
bool drawTheScene = true;
int coolingMapHeight = SCREEN_HEIGHT;
int coolingMapOffset = coolingMapHeight - 1;


asm data {logo_p dq 0}
g.[logo_p] = sidelib.LoadImage("groundlogo_960x109.png");
if (g.[logo_p] == null) {
	user32.MessageBox(null, "The groundlogo_960x109.png cannot be found!", "Message", g.MB_OK);
	return;
}


while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT) {
			StatusRunning = false;
		}
		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE) {
				StatusRunning = false;
			}
		}
	}
	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	loopStartTicks = sdl3.SDL_GetTicks();

	asm {SpeedFireLoop:}
	asm {
		mov	rcx, 960*(560-1)
		mov rdx, [fireBufferNew@main]
		add rdx, GC_Screen_DimX
		mov r8, [fireBufferOld@main]
		call Utils_CopyArray
	}

	coolingMapOffset = coolingMapOffset + 2;
	if (coolingMapOffset >= (coolingMapHeight-1)) {
		coolingMapOffset = 0;
	}

	for (int f = 0; f < SCREEN_WIDTH; f++) {
		fireBufferOld[(SCREEN_WIDTH*(SCREEN_HEIGHT-3))+f] = 0xff;
	}

	asm {
	  push	rsi rdi
	  mov	rcx, 0
	  mov	rsi, [logo_p]
	  mov	rdi, [fireBufferOld@main]
	  add	rdi, 960*200
.logoPixel:
	  mov	eax, [rsi+rcx*4]
	  cmp	eax, 0
	  je	.nextLogoPixel
	  mov	al, 0xbf
	  mov	[rdi+rcx], al
.nextLogoPixel:
	  add	rcx, 1
	  cmp	rcx, 960*108
	  jne	.logoPixel
	  pop	rdi rsi
	}

	for (int y = 0; y < (SCREEN_HEIGHT-1); y++) {
		int coolingY = (y + coolingMapOffset) % SCREEN_HEIGHT;
		int coolingPosY = coolingY * g.GC_Screen_DimX;

		asm {
		  mov	rcx, [y@main]
		  mov	rdx, [coolingPosY@main]
		  call	ASM_Fire
		}
	}

	//Palette:
	//for (int i = 0; i < 256; i++) {
	//	for (int y = 0; y < g.GC_Screen_DimY; y++) {
	//		pixels[i,y] = palette[i];
	//	}
	//}

	//Coolmap:
	//u32[] pixelsFlat = pixels;
	//for (int i = 0; i < 960*560; i++) {
	//	u32 aPixel = coolmapPointer[i] + (coolmapPointer[i] << 8);
	//	pixelsFlat[i] = aPixel;
	//}

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if ((currentTicks < 300) and (frameCount == 0)) {
		asm {
			jmp SpeedFireLoop
		}
	}

	if (currentTicks < debugBestTicks) {
		debugBestTicks = currentTicks;
	}

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

msvcrt.free(coolmapPointer);
msvcrt.free(fireBufferOld);
msvcrt.free(fireBufferNew);
sidelib.FreeImage(g.[logo_p]);

// string showStr = "Best innerloop time: " + debugBestTicks + "ms";
// user32.MessageBox(null, showStr, "Message", g.MB_OK);

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

	mov r8, GC_Screen_DimY
	sub r8d, ecx

	mov r9, [palette@main]
	mov	rax, r9
	call  GetMemoryPointerFromIndex
	mov r9, rax

	mov r11, 0
	mov r12, 0
	mov r10, [fireBufferNew@main]
	mov r15, [coolmapPointer@main]
	add r15, rdx                ; r15 = fire_coolingMap + coolingPosY
	mov rdi, [pixels_p]
	mov r14, [fireBufferOld@main]
	mov r13, GC_Screen_DimX

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

	;mov eax, [rdi+rcx*4]
	;and eax, 001000000h   ; We controleren of de eerste bit van het alpha kanaal gezet is, anders gaan we de vuurpixel niet zetten.
	;cmp eax, 0
	;je Next
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

