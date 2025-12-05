
// Fireworks. Code inspiration from: https://demo-effects.sourceforge.net/

#template sdl3

#define PARTICLES_PER_EXPLOSION 750
#define PARTICLE_PARTS 3
#define NUMBER_OF_PARTICLES PARTICLES_PER_EXPLOSION*PARTICLE_PARTS

#include graphics_defines1280x720.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#library user32 user32.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll

int frameCount = 0;
u32[SCREEN_WIDTH * SCREEN_HEIGHT] pixels = null;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
int pitch = SCREEN_LINESIZE;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int spaceCount = 0;

ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

class ColorARGB {
    byte b;
    byte g;
    byte r;
	byte a;
    function ToSDL3Pixel() : int {
        return 0xff000000 + (this.r << 16) + (this.g << 8) + this.b;
    }
}
ColorARGB[256] colors = [];

class Particle {
	int xpos;
	int ypos;
	int xdir;
	int ydir;
	int colorindex;
	int dead;
}
Particle[NUMBER_OF_PARTICLES] particles = [];

u16* fire = msvcrt.calloc(1, SCREEN_WIDTH * SCREEN_HEIGHT * sizeof(u16));

function init_particle(Particle* particle, int cx, int cy)
{
	float theta = 2.0 * MATH_PI * sdl3.SDL_randf();
	float r = 60.0 * sdl3.SDL_randf();
	float x = cx + r * sdl3.SDL_cos(theta);
	float y = cy + r * sdl3.SDL_sin(theta);
	*particle.xpos = x;
	*particle.ypos = y;
	//*particle.xpos = (SCREEN_WIDTH / 2) - 20 + sdl3.SDL_rand(40);
	//*particle.ypos = (SCREEN_HEIGHT / 2) - 20 + sdl3.SDL_rand(40);
	*particle.xdir = -10 + sdl3.SDL_rand(20);
	*particle.ydir = -17 + sdl3.SDL_rand(19);
	*particle.colorindex = 255;
	*particle.dead = 0;
}


function InitParticles(int part) {
	int cx = sdl3.SDL_rand(SCREEN_WIDTH - 500) + 250;
	int cy = sdl3.SDL_rand(SCREEN_HEIGHT - 600) + 215;
	for (i in 0 ..< PARTICLES_PER_EXPLOSION)
		init_particle(&particles[i+(part*PARTICLES_PER_EXPLOSION)], cx, cy);
}


function Init() {
	int i;

	/* create a suitable fire palette, this is crucial for a good effect */
	/* black to blue, blue to red, red to yellow, yellow to white*/

	for (i in 0 ..< 32)
	{
		/* black to blue, 32 values*/
		colors[i].b = i << 1;

		/* blue to red, 32 values*/
		colors[i + 32].r = i << 3;
		colors[i + 32].b = 64 - (i << 1);

		/*red to yellow, 32 values*/
		colors[i + 64].r = 255;
		colors[i + 64].g = i << 3;

		/* yellow to white, 162 */
		colors[i + 96].r = 255;
		colors[i + 96].g = 255;
		colors[i + 96].b = i << 2;
		colors[i + 128].r = 255;
		colors[i + 128].g = 255;
		colors[i + 128].b = 64 + (i << 2);
		colors[i + 160].r = 255;
		colors[i + 160].g = 255;
		colors[i + 160].b = 128 + (i << 2);
		colors[i + 192].r = 255;
		colors[i + 192].g = 255;
		colors[i + 192].b = 192 + i;
		colors[i + 224].r = 255;
		colors[i + 224].g = 255;
		colors[i + 224].b = 224 + i;
	}
}


function Graphics_Update() {
	int buf;
	int index;
	int temp;
	int tmpColorIndex;

	u8* AsmPar_fire = fire;
	u32* AsmPar_pixels = pixels;
	ptr AsmPar_colors = &colors;

	for (i in 0 ..< NUMBER_OF_PARTICLES)
	{
		if (!particles[i].dead)
		{
			particles[i].xpos = particles[i].xpos + particles[i].xdir;
			particles[i].ypos = particles[i].ypos + particles[i].ydir;

			// Is particle dead?
			if ((particles[i].ypos >= SCREEN_HEIGHT - 3) or (particles[i].colorindex == 0) or (particles[i].xpos <= 1) or (particles[i].xpos >= SCREEN_WIDTH - 3))
			{
				particles[i].dead = 1;
				continue;
			}

			// Gravity takes over
			particles[i].ydir = particles[i].ydir + 1;

			// Particle cools off
			particles[i].colorindex = particles[i].colorindex - 1;

			// Draw particle
			temp = particles[i].ypos * SCREEN_WIDTH + particles[i].xpos;
			tmpColorIndex = particles[i].colorindex;

asm {
  push	r11 r8
  mov	r11, [AsmPar_fire@Graphics_Update]
  mov	rax, [tmpColorIndex@Graphics_Update]
  mov	r8, [temp@Graphics_Update]
  shl	r8, 1	; mult with 2, because FIRE_ELEMENT_SIZE = 2

  mov	[r11+r8], ax
  mov	[r11+r8-FIRE_ELEMENT_SIZE], ax
  mov	[r11+r8+FIRE_ELEMENT_SIZE], ax
  add	r8, GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE
  mov	[r11+r8], ax
  sub	r8, GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE * 2
  mov	[r11+r8], ax

  pop	r8 r11
}
/*
			fire[temp] = particles[i].colorindex;
			fire[temp - 1] = particles[i].colorindex;
			fire[temp + SCREEN_WIDTH] = particles[i].colorindex;
			fire[temp - SCREEN_WIDTH] = particles[i].colorindex;
			fire[temp + 1] = particles[i].colorindex;
*/
		}
	}


	// Fire Effect below is 13ms in Ground, 7ms in C en 2ms in Asm.
	for (i in 0 ..< (SCREEN_HEIGHT-3))
	{
		index = i * SCREEN_WIDTH;

asm {
FIRE_ELEMENT_SIZE = 2
  push	rcx r11 r9 r8
  mov	rcx, GC_SCREEN_WIDTH-3
  mov	r11, [AsmPar_fire@Graphics_Update]	; r11 = fire
  mov	r9, FIRE_ELEMENT_SIZE				; r9 = j
.loopScreenWidth:
  mov	r8, [index@Graphics_Update]
  shl	r8, 1
  add	r8, r9				; r8 = buf

  xor	rax, rax
  mov	ax, [r11+r8]		; rax = temp
  add	ax, [r11+r8+FIRE_ELEMENT_SIZE]
  add	ax, [r11+r8-FIRE_ELEMENT_SIZE]

  add	r8, GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE
  add	ax, [r11+r8+FIRE_ELEMENT_SIZE]
  add	ax, [r11+r8-FIRE_ELEMENT_SIZE]

  add	r8, GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE
  add	ax, [r11+r8]
  add	ax, [r11+r8+FIRE_ELEMENT_SIZE]
  add	ax, [r11+r8-FIRE_ELEMENT_SIZE]

  shr	rax, 3
  sub	rax, 4
  jns	.notNegative
  xor	rax, rax
.notNegative:
  sub	r8, GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE
  mov	[r11+r8], ax

  add	r9, FIRE_ELEMENT_SIZE
  loop	.loopScreenWidth
  pop	r8 r9 r11 rcx
}
/*
		for (int j = 1; j < SCREEN_WIDTH - 2; j++)
		{
			buf = index + j;

			temp = fire[buf];
			temp = temp + fire[buf + 1];
			temp = temp + fire[buf - 1];
			buf = buf + SCREEN_WIDTH;
			temp = temp + fire[buf - 1];
			temp = temp + fire[buf + 1];
			buf = buf + SCREEN_WIDTH;
			temp = temp + fire[buf];
			temp = temp + fire[buf + 1];
			temp = temp + fire[buf - 1];

			temp = temp >> 3;

			if (temp > 4)
				temp = temp - 4;
			else
				temp = 0;

			fire[buf - SCREEN_WIDTH] = temp;
		}
*/
	}

	for (i in (SCREEN_HEIGHT - 1) .. 0)
	{
		temp = i * SCREEN_WIDTH;

asm {
  push	rcx r12 r11 r10 r9 r8
  mov	rcx, GC_SCREEN_WIDTH
  mov	r12, [AsmPar_colors@Graphics_Update]	; r12 = colors
  mov	r11, [AsmPar_fire@Graphics_Update]		; r11 = fire
  mov	r10, [AsmPar_pixels@Graphics_Update]	; r10 = pixels
  mov	r9, (GC_SCREEN_WIDTH * FIRE_ELEMENT_SIZE) - FIRE_ELEMENT_SIZE		; r9 = j
.loopScreenWidth:
  mov	r8, [temp@Graphics_Update]
  shl	r8, 1				; mult with 2, because FIRE_ELEMENT_SIZE = 2
  add	r8, r9				; r8 = temp + j

  xor	rax, rax
  mov	ax, [r11+r8]		; ax = colorIndex = fire[temp + j];
  mov	eax, [r12+rax*4]
  or	eax, 0xff000000;	; set the transparency to full
  mov	[r10+r8*2], eax		; multiply with 2 to transform the "temp+j" to a 4-byte pixel size

  sub	r9, FIRE_ELEMENT_SIZE
  loop	.loopScreenWidth
  pop	r8 r9 r10 r11 r12 rcx
}
/*
		for (j = SCREEN_WIDTH - 1; j >= 0; j--)
		{
			int colorIndex = fire[temp + j];
			u32 color = 0xff000000 + (colors[colorIndex].r << 16) + (colors[colorIndex].g << 8) + colors[colorIndex].b;
			pixels[temp + j] = color;
		}
*/
	}
}


sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Fireworks", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d"); // "direct3d11" is slow with render
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();


function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, 2.0, 2.0);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+0.5, y+0.5, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x58, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function SpaceWrite(int frameTime, string skyWrite) {
	if (frameCount > frameTime and frameCount < (frameTime+250))
		writeText(renderer, 125.0, 200.0, skyWrite);
}

function RenderTexts() {
	//if (spaceCount > 0)
	//	writeText(renderer, 10.0, 10.0, spaceCount);
	SpaceWrite(0,    "          Welcome to the Firework show!          ");
	SpaceWrite(930,  "              Stay Grounded in 2026!             ");
	SpaceWrite(1547, "  Enjoy writing x86-64 before ARM takes over...  ");
	SpaceWrite(2154, "   Handwritten Assembly is always the fastest.   ");
	SpaceWrite(2771, "     The experts know that and I second it.      ");
	SpaceWrite(3380, "    A compiler can never predict your plan.      ");
	SpaceWrite(4000, "    Handwritten Assembly uses precalculations.   ");
	SpaceWrite(4614, "    And store important values in registers.     ");
	SpaceWrite(5222, "      This demo takes 7ms in optimized C.        ");
	SpaceWrite(5834, "In Ground with small portions of inline asm: 2ms.");
	SpaceWrite(7066, "     Why is everybody neglecting assembly?       ");
	SpaceWrite(7677, "    Once in a while a Youtuber discovers it.     ");
	SpaceWrite(8287, "  But programmers do not demand support for it.  ");
	SpaceWrite(8908, "              x86-64 asm is culture.             ");
	SpaceWrite(9843, "         Neglecting culture is a disease.        ");
	SpaceWrite(10441,"x86-64 is not so hard as C++ and it is very clear.");
	SpaceWrite(11057,"      Thanks for reading this far. Regards!      ");
}

#include soundtracker.g
SoundtrackerInit("sound/mod/tip - animotion.mod", 127);

Init();
while (StatusRunning)
{
	SoundtrackerUpdate();
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;
		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
			if (*eventScancode == g.SDL_SCANCODE_SPACE)
				spaceCount = frameCount;
		}
	}

	loopStartTicks = sdl3.SDL_GetTicks();

	if (frameCount >= 300)
		for (i in 0..< PARTICLE_PARTS)
			if (frameCount % 60 == (i*(60 / PARTICLE_PARTS)))
				InitParticles(i);

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;
	Graphics_Update();
	sdl3.SDL_UnlockTexture(texture);

	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderTexture(renderer, texture, null, null);
	RenderTexts();
	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();

msvcrt.free(fire);
SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);
