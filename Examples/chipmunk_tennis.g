
#template sdl3

#include graphics_defines960x560.g
#library sdl3 sdl3.dll SDL3
#library sdl3_image sdl3_image.dll SDL3_image
#library chipmunk libchipmunk.dll chipmunk
#define NR_BALLS 12

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Chipmunk physics engine usage", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
#windows  ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
#linux    ptr renderer = sdl3.SDL_CreateRenderer(window, null);
sdl3.SDL_SetRenderVSync(renderer, 1);

byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
bool StatusRunning = true;
f32[4] ballSrcRectVoetbal = [0,0,32,32];
f32[4] destRect = [];

ptr tennisSurface = sdl3_image.IMG_Load("image/playfield1024.png");
if (tennisSurface == null) { sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_ERROR, "Error", "The file cannot be found!", null); return; }

ptr tenniscourtTexture = sdl3.SDL_CreateTextureFromSurface(renderer, tennisSurface);
if (tenniscourtTexture == null) { sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_ERROR, "Error", "The file cannot be found!", null); return; }
sdl3.SDL_DestroySurface(tennisSurface);

ptr ballSurface = sdl3_image.IMG_Load("image/3balls_32.png");
if (ballSurface == null) { sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_ERROR, "Error", "The file cannot be found!", null); return; }

ptr ballTexture = sdl3.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) { sdl3.SDL_ShowSimpleMessageBox(g.SDL_MESSAGEBOX_ERROR, "Error", "The file cannot be found!", null); return; }
sdl3.SDL_DestroySurface(ballSurface);

CpVect gravity = CpVect(0.0, -300.0);
ptr space = chipmunk.cpSpaceNew();
chipmunk.cpSpaceSetGravity(space, gravity);

ptr staticBody = chipmunk.cpSpaceGetStaticBody(space);
if (staticBody == null)
	return;

/*
ptr groundShape = chipmunk.cpBoxShapeNew(staticBody, 960.0, 10.0, 0.0);
if (groundShape == null)
	return;
chipmunk.cpBodySetPosition(staticBody, CpVect(480.0, 50.0));
chipmunk.cpSpaceAddShape(space, groundShape);
chipmunk.cpSpaceReindexShapesForBody(space, staticBody);
*/

ptr groundShape = chipmunk.cpSegmentShapeNew(staticBody, CpVect(-20.0, 250.0), CpVect(900.0, 0.0), 10.0);
ptr bounceShape = chipmunk.cpSpaceAddShape(space, groundShape);
chipmunk.cpShapeSetFriction(groundShape, 1.0);
chipmunk.cpShapeSetElasticity(groundShape, 0.9);

ptr groundShape2 = chipmunk.cpSegmentShapeNew(staticBody, CpVect(-20.0, 0.0), CpVect(960.0, 250.0), 10.0);
chipmunk.cpShapeSetFriction(groundShape2, 1.0);
chipmunk.cpSpaceAddShape(space, groundShape2);
chipmunk.cpShapeSetElasticity(groundShape2, 0.9);

f64 radius = 16.0;
f64 mass = 1.0;
f64 moment = chipmunk.cpMomentForCircle(mass, 0.0, radius, cpvzero);

ptr[NR_BALLS] ballBodies = [];
ptr[NR_BALLS] ballShapes = [];

CpVect p5 = CpVect(0.0, 450.0);
ptr ballBody = null;
ptr ballShape = null;

for (b in 0 ..< NR_BALLS) {
	ballBody = chipmunk.cpSpaceAddBody(space, chipmunk.cpBodyNew(mass, moment));
	ballBodies[b] = ballBody;
	p5.x = p5.x + 64;
	p5.y = p5.y + 10;
	chipmunk.cpBodySetPosition(ballBody, p5);
	ballShape = chipmunk.cpSpaceAddShape(space, chipmunk.cpCircleShapeNew(ballBodies[b], radius, cpvzero));
	ballShapes[b] = ballShape;
	chipmunk.cpShapeSetFriction(ballShape, 1.0);
	chipmunk.cpShapeSetElasticity(ballShape, 1.0);
}
//CpVect vectVel = CpVect(380.0, 0.0);
//chipmunk.cpBodySetVelocity(ballBodies[2], vectVel);
f64 timeStep = 0.0166666667;

CpVect cpvectPos;
CpVect cpvectVel;
f64 angle;

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

	sdl3.SDL_RenderTexture(renderer, tenniscourtTexture, null, null);
	chipmunk.cpSpaceStep(space, timeStep);

	for (b in 0 ..< NR_BALLS) {
		ballBody = ballBodies[b];
		cpvectPos = chipmunk.cpBodyGetPosition(ballBody);
		cpvectVel = chipmunk.cpBodyGetVelocity(ballBody);
		angle = chipmunk.cpBodyGetAngle(ballBody);

		destRect[0] = cpvectPos.x;
		destRect[1] = SCREEN_HEIGHT - cpvectPos.y;
		destRect[2] = 32;
		destRect[3] = 32;

		f64 theAngle = angle * (180.0 / MATH_PI);
		sdl3.SDL_RenderTextureRotated(renderer, ballTexture, ballSrcRectVoetbal, destRect, -theAngle, null, g.SDL_FLIP_NONE);
	}

	sdl3.SDL_RenderPresent(renderer);
}

chipmunk.cpSpaceFree(space);

sdl3.SDL_DestroyTexture(tenniscourtTexture);
sdl3.SDL_DestroyTexture(ballTexture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
