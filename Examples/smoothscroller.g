
// Precalculated colorcycling plasma with a smoothscroller. Optimized version.
// https://lodev.org/cgtutor/plasma.html

#template retrovm

#include graphics_defines960x560.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#library user32 user32.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll
#library chipmunk libchipmunk.dll
#define NR_BALLS 40


ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, 0x80); //HIGH_PRIORITY_CLASS
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Retro VM", g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.Graphics_ScreenDIMx, g.Graphics_ScreenDIMy);
sdl3.SDL_SetRenderVSync(renderer, 1);

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = g.Graphics_ScreenLineSize;
int xscrollNeedle = 0;
int scrollTextNeedle = 0;
int whichLineToScroll = 16;
string scrollText = `Smoothscroller written in Ground!                            \
You are very \8f\8f old \8f\8f if you recognize the font.    \
The used template is called "retrovm" and contains a character buffer and charcolor buffer, just like the C64.    \
It also contains a Copper look-a-like function just like the Amiga.                      `;
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

g.[bg_image_p] = msvcrt.calloc(1, SCREEN_WIDTH * SCREEN_HEIGHT * SCREEN_PIXELSIZE);
u32[960,560] bg_image = g.[bg_image_p];

asm data {plasma_p dq 0}
g.[plasma_p] = msvcrt.calloc(1, SCREEN_WIDTH * SCREEN_HEIGHT * SCREEN_PIXELSIZE);
u32[960,560] plasma = g.[plasma_p];
asm data {plasma_palette dd 256 dup(0)}
u32[256] palette = g.plasma_palette;

class ColorRGB {
    int red;
    int green;
    int blue;
    function ToInteger() {
        return 0xff000000 + (65536 * this.red) + (256 * this.green) + this.blue;
    }
}

for (int i = 0; i < 256; i++) {
	ColorRGB color;
    color.red = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 64.0)));
    color.green = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 128.0)));
    color.blue = 128.0 + (127.0 * msvcrt.sin(6.283185307 * (i / 256.0)));
    palette[i] = color.ToInteger();
}

byte[] font256OnDisk = sidelib.LoadImage("image/charset16x16.png");
if (font256OnDisk == null) {
	user32.MessageBox(null, "The font charset16x16.png cannot be found!", "Message", g.MB_OK);
	return;
}
sidelib.ConvertFonts(font256OnDisk, g.[font256_p], g.[font32_p]);
sidelib.FreeImage(font256OnDisk);

g.[colortable_p] = g.colorpalette256;
g.[screentext1_p] = msvcrt.calloc(1, g.GC_Screen_TextSize);
g.[screentext4_p] = msvcrt.calloc(1, g.GC_Screen_TextSize * 4);
g.[font32_charcolor_p] = msvcrt.calloc(1, g.GC_Screen_TextSize);

u32[256] colors = g.[colortable_p];
byte[61,36] screenArray = g.[screentext1_p];
byte[61,36] colorsArray = g.[font32_charcolor_p];

function fillLine(int y, int charValue) {
    for (int x = 0; x < g.GC_Screen_TextColumns; x++) {
        screenArray[x,y] = charValue;
    }
}
// fill the screen with the special "bg_image" character (0xff)
for (int y = 0; y < g.GC_Screen_TextRows; y++) {
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
	for (int y = 0; y < SCREEN_HEIGHT; y++) {
		for (int x = 0; x < SCREEN_WIDTH; x++) {
			u32 pixelColor;

			//pixelColor = plasma[x, y];
			int xyBufferOffset;
			asm {
				mov	rax, [y@PlasmaCalculation]
				mov	rdx, SCREEN_WIDTH*4
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
						 128.0 + (127.0 * msvcrt.sin(msvcrt.sqrt((x - SCREEN_WIDTH / 2.0) * (x - SCREEN_WIDTH / 2.0) + (y - SCREEN_HEIGHT / 2.0) * (y - SCREEN_HEIGHT / 2.0)) / 16.0)) + 
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

int RandomSeed = 123123;
sdl3.SDL_srand(RandomSeed);


ptr ballSurface = sdl3_image.IMG_Load("image/3balls_32.png");
if (ballSurface == null) return;
ptr ballTexture = sdl3.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) return;
sdl3.SDL_DestroySurface(ballSurface);

ptr space = chipmunk.cpSpaceNew();
chipmunk.cpSpaceSetGravity(space, CpVect(0.0, -300.0));

ptr groundShape = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(-1000.0, 332.0), CpVect(2000.0, 332.0), 4);
chipmunk.cpShapeSetFriction(groundShape, 1);
chipmunk.cpSpaceAddShape(space, groundShape);
chipmunk.cpShapeSetElasticity(groundShape, 0.9);

float ballRadius = 16.0;
float ballMass = 1.0;
float ballMoment = chipmunk.cpMomentForCircle(ballMass, 0.0, ballRadius, cpvzero);
int ballToShoot = 0;

ptr[NR_BALLS] ballBodies = [];
ptr[NR_BALLS] ballShapes = [];

CpVect p = CpVect(-50.0, 450.0);

for (int b = 0 ; b < NR_BALLS; b++) {
	ballBodies[b] = chipmunk.cpSpaceAddBody(space, chipmunk.cpBodyNew(ballMass, ballMoment));
	p.x = p.x - 64;
	chipmunk.cpBodySetPosition(ballBodies[b], p);
	ballShapes[b] = chipmunk.cpSpaceAddShape(space, chipmunk.cpCircleShapeNew(ballBodies[b], ballRadius, cpvzero));
	chipmunk.cpShapeSetFriction(ballShapes[b], 1);
	chipmunk.cpShapeSetElasticity(ballShapes[b], 1);
}
float timeStep = 1.0 / 60.0;

CpVect cpvectPos;
CpVect cpvectVel;

f32[4] ballSrcRectVoetbal = [0,0,32,32];
f32[4] ballSrcRectTennisbal = [0,32,32,32];
f32[4] ballSrcRectKogel = [0,64,32,32];
f32[4] ballDestRect = [0,0,32,32];
ptr ballSrc = &ballSrcRectKogel;

for (i in 0 ..< NR_BALLS)
{
	if (i % 3 == 0)
		chipmunk.cpBodySetUserData(ballBodies[i], &ballSrcRectVoetbal);
	if (i % 3 == 1)
		chipmunk.cpBodySetUserData(ballBodies[i], &ballSrcRectTennisbal);
	if (i % 3 == 2)
		chipmunk.cpBodySetUserData(ballBodies[i], &ballSrcRectKogel);
}

#include soundtracker.g
SoundtrackerInit("sound/mod/mlp desire n-tracker.mod", 127);


function IsBallUsable(int ballIndex) : bool {
	chipmunk.cpBodyGetPosition(cpvectPos, ballBodies[ballIndex]);
	return (cpvectPos.x < -20.0 or cpvectPos.x > 980.0);
}


while (StatusRunning)
{
	SoundtrackerUpdate();

	while (sdl3.SDL_PollEvent(&event[0])) {
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
	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;
	loopStartTicks = sdl3.SDL_GetTicks();

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
        if (g.[frameCount] % 3 == 0) {
            RotateChar(0x8f);
        }

		PlasmaCalculation();

		int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
		if (currentTicks < debugBestTicks) {
			debugBestTicks = currentTicks;
		}

		thread1Busy = false;
	}
	while (thread2Busy) { }

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);


    if (g.[frameCount] % 10 == 0) {
		ballToShoot++;
		if (ballToShoot == NR_BALLS)
			ballToShoot = 0;
			
		int usableCounter = 0;
		while (!IsBallUsable(ballToShoot)) {
			ballToShoot++;
			if (ballToShoot == NR_BALLS)
				ballToShoot = 0;
			usableCounter++;
			if (usableCounter == NR_BALLS)
				break;
		}

		if (usableCounter != NR_BALLS) {
			int tmp = sdl3.SDL_rand_r(&RandomSeed, 100);
			p.x = 980.0;
			p.y = 400.0 + tmp;
			chipmunk.cpBodySetPosition(ballBodies[ballToShoot], p);

			int newSpeed = 0;
			newSpeed = sdl3.SDL_rand_r(&RandomSeed, 500);
			newSpeed = -200 - newSpeed;
			p.x = newSpeed;
			p.y = 0.0;
			chipmunk.cpBodySetVelocity(ballBodies[ballToShoot], p);
		}
    }

	chipmunk.cpSpaceStep(space, timeStep);

	for (b = 0; b < NR_BALLS; b++) {
		ptr ballBody = ballBodies[b];
		chipmunk.cpBodyGetPosition(cpvectPos, ballBody);
		chipmunk.cpBodyGetVelocity(cpvectVel, ballBody);
		float angle = chipmunk.cpBodyGetAngle(ballBody);

		ballDestRect[0] = cpvectPos.x;
		ballDestRect[1] = SCREEN_HEIGHT - cpvectPos.y;
		float theAngle = angle * (180.0 / MATH_PI);
		ballSrc = chipmunk.cpBodyGetUserData(ballBody);
		sdl3.SDL_RenderTextureRotated(renderer, ballTexture, ballSrc, &ballDestRect, -theAngle, null, g.SDL_FLIP_NONE);
	}

	sdl3.SDL_RenderPresent(renderer);

	asm { inc [frameCount] }
}

while (thread2Busy) { }

chipmunk.cpSpaceFree(space);

sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_DestroyTexture(ballTexture);
sdl3.SDL_Quit();

msvcrt.free(g.[font32_charcolor_p]);
msvcrt.free(g.[screentext4_p]);
msvcrt.free(g.[screentext1_p]);
msvcrt.free(g.[font256_p]);
msvcrt.free(g.[font32_p]);
msvcrt.free(g.[plasma_p]);
msvcrt.free(g.[bg_image_p]);
SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
