//Bob example.

#template sdl2

#include msvcrt.g
#include sdl2.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include chipmunk.g


ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl2.SDL_Init(g.SDL_INIT_EVERYTHING);
ptr window = sdl2.SDL_CreateWindow("Chipmunk physics engine usage", g.SDL_WINDOWPOS_UNDEFINED, g.SDL_WINDOWPOS_UNDEFINED, g.GC_Screen_DimX, g.GC_Screen_DimY, g.SDL_WINDOW_SHOWN);
ptr renderer = sdl2.SDL_CreateRenderer(window, -1, g.SDL_RENDERER_ACCELERATED or g.SDL_RENDERER_PRESENTVSYNC);

byte[56] event = [];
u32* eventType = &event[0];
bool StatusRunning = true;
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
asm data {frameCount dq 0}
u32[4] destRect = [];

ptr tennisSurface = sdl2_image.IMG_Load("de_tennisbaan.jpg");
if (tennisSurface == null) {
	user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK);
	return;
}
ptr tenniscourtTexture = sdl2.SDL_CreateTextureFromSurface(renderer, tennisSurface);
if (tenniscourtTexture == null) {
	user32.MessageBox(null, "tenniscourtTexture not available!", "Message", g.MB_OK);
	return;
}
sdl2.SDL_FreeSurface(tennisSurface);

ptr ballSurface = sdl2_image.IMG_Load("tennisbal_32x32.png");
if (ballSurface == null) {
	user32.MessageBox(null, "The file cannot be found!", "Message", g.MB_OK);
	return;
}

ptr ballTexture = sdl2.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) {
	user32.MessageBox(null, "ballTexture not available!", "Message", g.MB_OK);
	return;
}
sdl2.SDL_FreeSurface(ballSurface);

class CpVect {
	float x;
	float y;
}
CpVect cpvzero = CpVect(0.0, 0.0);

ptr space = chipmunk.cpSpaceNew();
chipmunk.cpSpaceSetGravity(space, CpVect(0.0, -300.0));

ptr groundShape = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(-20.0, 250.0), CpVect(900.0, 0.0), 10);
chipmunk.cpShapeSetFriction(groundShape, 1);
chipmunk.cpSpaceAddShape(space, groundShape);
chipmunk.cpShapeSetElasticity(groundShape, 0.9);

ptr groundShape2 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(-20.0, 0.0), CpVect(960.0, 250.0), 10);
chipmunk.cpShapeSetFriction(groundShape2, 1);
chipmunk.cpSpaceAddShape(space, groundShape2);
chipmunk.cpShapeSetElasticity(groundShape2, 0.9);

float radius = 16.0;
float mass = 1.0;
float moment = chipmunk.cpMomentForCircle(mass, 0.0, radius, cpvzero);

ptr[4] ballBodies = [];
ptr[4] ballShapes = [];

CpVect p5 = CpVect(0.0, 450.0);

for (int b = 0 ; b < 12; b++) {
	ballBodies[b] = chipmunk.cpSpaceAddBody(space, chipmunk.cpBodyNew(mass, moment));
	p5.x = p5.x + 64;
	p5.y = p5.y + 10;
	chipmunk.cpBodySetPosition(ballBodies[b], p5);
	ballShapes[b] = chipmunk.cpSpaceAddShape(space, chipmunk.cpCircleShapeNew(ballBodies[b], radius, cpvzero));
	chipmunk.cpShapeSetFriction(ballShapes[b], 1);
	chipmunk.cpShapeSetElasticity(ballShapes[b], 1);
}
float timeStep = 1.0 / 60.0;

CpVect cpvectPos;
CpVect cpvectVel;
float angle;

while (StatusRunning)
{
	while (sdl2.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_QUIT) {
			StatusRunning = false;
		}
	}

	loopStartTicks = sdl2.SDL_GetTicks();
	sdl2.SDL_RenderCopy(renderer, tenniscourtTexture, null, null);

	chipmunk.cpSpaceStep(space, timeStep);

	for (b = 0; b < 12; b++) {
		chipmunk.cpBodyGetPosition(cpvectPos, ballBodies[b]);
		chipmunk.cpBodyGetVelocity(cpvectVel, ballBodies[b]);
		angle = chipmunk.cpBodyGetAngle(ballBodies[b]);

		destRect[0] = cpvectPos.x;
		destRect[1] = 560 - cpvectPos.y;
		destRect[2] = 32;
		destRect[3] = 32;

		float theAngle = angle * (180.0 / 3.141592);
		sdl2.SDL_RenderCopyEx(renderer, ballTexture, null, destRect, -theAngle, null, g.SDL_FLIP_NONE);
	}

	int currentTicks = sdl2.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0) {
		debugBestTicks = currentTicks;
	}

	sdl2.SDL_RenderPresent(renderer);
	asm { inc [frameCount] }
}

chipmunk.cpSpaceFree(space);

sdl2.SDL_DestroyTexture(tenniscourtTexture);
sdl2.SDL_DestroyRenderer(renderer);
sdl2.SDL_DestroyWindow(window);
sdl2.SDL_Quit();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.

string showStr = "Best innerloop time: " + debugBestTicks + "ms";
user32.MessageBox(null, showStr, "Message", g.MB_OK);
