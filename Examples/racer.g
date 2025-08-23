
#template sdl3

#define MAX_PLAYER_SPEED 18.0
#define MAX_PLAYER_SPEED_ON_CLIP 2.0
#define ENEMY_ARRIVAL_SPEED 14.0
#define CURVATURE_MODIFICATION_SPEED 0.00025
#define PLAYER_ACCELERATION 0.07
#define PLAYER_DEACCELERATION 0.03
#define PLAYER_BREAKING 0.15
#define PLAYER_CLIP_HIT_BREAKING 0.20
#define PLAYER_STEERING 0.00008
#define PLAYER_MAX_STEERING 0.003

#include graphics_defines.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g


float[] track = [ 
	2000.0, 0.15,
	3000.0, 0.3,
	4000.0, 0.1,
	6000.0, 0.0,
	8000.0, -0.3 ];   // first value: distance, second: curvature
int trackSize = sizeof(track) / sizeof(float);
int trackPartIndex = 0;   // where we are within the track. Each part consists of 2 values (distance and curvature).
float trackDistance = track[trackSize-2];

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
int frameCount = 0;
bool StatusRunning = true;
int heightOfRoad = (SCREEN_HEIGHT >> 3) * 5;
int restHeight = (SCREEN_HEIGHT >> 3) * 3;
float space_y = 100.0;
float scale_y = 200.0;
int horizon = 20;
float speed = 0.0;
float curvature = 0.15;         // Curvature of the track
float playerDistance = 0.0;
float playerSteering = 0.0;
float playerPosition = 0.0;
float playerPositionDisplay = 0.0;
bool clipHitting = false;      // is the clip now touched?
float clipLeft;
float clipRight;


sdl3.SDL_Init(g.SDL_INIT_VIDEO | g.SDL_INIT_AUDIO);
ptr window = sdl3.SDL_CreateWindow("Racer", g.GC_Screen_DimX, g.GC_Screen_DimY, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, g.GC_Screen_DimX, g.GC_Screen_DimY);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();
#include racer-helper.g


class Actor {
	float distance;
	float x;
	float displayX;
	float speed;
	bool visible;

	function draw() {
		if not (this.visible) return;

		float relDistance = this.distance - playerDistance;

		if (relDistance > 800.0) return;

		float newY = (space_y * scale_y / relDistance) - horizon;
		float fMiddlePoint = 0.5 + ((curvature * relDistance) / 400.0);
		float fPerspective = newY / (SCREEN_HEIGHT_F / 2.0);
		float fRoadWidth = 0.1 + (fPerspective * 0.6);
		float fHalfRoadWidth = fRoadWidth / 2.0;
		int nLeftClip = (fMiddlePoint - fHalfRoadWidth) * SCREEN_WIDTH;
		int nRightClip = (fMiddlePoint + fHalfRoadWidth) * SCREEN_WIDTH;
		int diffClip = (this.x + 0.5) * (nRightClip - nLeftClip);

		float defaultSizeX = 38*2;
		float defaultSizeY = 75*2;

		pointer texturePtr = pl1Texture;

		if (curvature > 0.29) {
			texturePtr = pl3Texture;
			defaultSizeX = 54*2;
			defaultSizeY = 75*2;
		} else if (curvature > 0.09) {
			texturePtr = pl2Texture;
			defaultSizeX = 37*2;
			defaultSizeY = 76*2;
		} else if (curvature < -0.29) {
			texturePtr = pl8Texture;
			defaultSizeX = 53*2;
			defaultSizeY = 75*2;
		} else if (curvature < -0.09) {
			texturePtr = pl7Texture;
			defaultSizeX = 37*2;
			defaultSizeY = 76*2;
		}

		float special = 1.2;
		float sizeY = (defaultSizeY * 56.0) * special / relDistance;
		if (sizeY > defaultSizeY)
			sizeY = defaultSizeY;

		float sizeX = (defaultSizeX * 56.0) * special / relDistance;
		if (sizeX > defaultSizeX)
			sizeX = defaultSizeX;

		this.displayX = nLeftClip + diffClip;
		destRect[0] = this.displayX;
		destRect[1] = restHeight + newY - sizeY;
		destRect[2] = sizeX;
		destRect[3] = sizeY;

		sdl3.SDL_RenderTextureRotated(renderer, texturePtr, null, destRect, 0.0, null, g.SDL_FLIP_NONE);
	}
	function resetDistance() {
		this.distance = playerDistance + 800.0;
	}
	function isHit() : bool {
		if not (this.visible) return false;

		float relDistance = this.distance - playerDistance;
		if (relDistance < 56.0 and (msvcrt.fabs(this.displayX - playerPositionDisplay) < 50.0 ))
			return true;
		return false;
	}
}


Actor actor1;
actor1.visible = false;
actor1.x = -0.3;
actor1.speed = 12.0;
//actor1.distance = 55.9;
//actor1.speed = 0.0;

Actor actor2;
actor2.visible = false;
actor2.x = 0.3;
actor2.speed = 13.0;


function getRoadAngleForPlayer() : float {
	float lookupDistance = playerDistance;
	while (lookupDistance > trackDistance)
		lookupDistance = lookupDistance - trackDistance;

	if (track[trackPartIndex] - lookupDistance > 4000.0)
		trackPartIndex = 0;

	while (track[trackPartIndex] < lookupDistance) {
		trackPartIndex = trackPartIndex + 2;
		if (trackPartIndex >= trackSize)
			trackPartIndex = 0;
	}
	return track[trackPartIndex+1];
}


function UpdatePositions() {
	float targetCurvature = getRoadAngleForPlayer();
	if (curvature != targetCurvature) {
		if (curvature < targetCurvature) {
			curvature = curvature + (CURVATURE_MODIFICATION_SPEED * speed);
			if (curvature > targetCurvature)  curvature = targetCurvature;
		} else if (curvature > targetCurvature) {
			curvature = curvature - (CURVATURE_MODIFICATION_SPEED * speed);
			if (curvature < targetCurvature)  curvature = targetCurvature;
		}
	}
	if (msvcrt.fabs(playerSteering) > 0.0002)
		playerPosition = playerPosition + playerSteering;

	playerPosition = playerPosition - ((curvature * speed) / 1000.0);

	// De player binnen het scherm houden.
	if (playerPosition < -0.49)
		playerPosition = -0.49;
	else if (playerPosition > 0.49)
		playerPosition = 0.49;
	
	// Bepalen of de player op een zijlijn rijdt.
	if (playerPosition < (clipLeft-0.03))
		clipHitting = true;
	else if (playerPosition > (clipRight+0.03))
		clipHitting = true;
	else
		clipHitting = false;

	if (actor1.visible) {
		actor1.distance = actor1.distance + actor1.speed;
		if (actor1.distance < playerDistance)
			actor1.resetDistance();
		if (speed > ENEMY_ARRIVAL_SPEED and actor1.distance > playerDistance + 1000.0)
			actor1.resetDistance();
		if (actor1.isHit())
			speed = 0.0;
	} else if (speed > ENEMY_ARRIVAL_SPEED) {
		actor1.visible = true;
		actor1.resetDistance();
	}
		
	if (actor2.visible) {
		actor2.distance = actor2.distance + actor2.speed;
		if (actor2.distance < playerDistance)
			actor2.resetDistance();
		if (speed > ENEMY_ARRIVAL_SPEED and actor2.distance > playerDistance + 1000.0)
			actor2.resetDistance();
		if (actor2.isHit())
			speed = 0.0;
	} else if (speed > ENEMY_ARRIVAL_SPEED) {
		actor2.visible = true;
		actor2.resetDistance();
	}
}


function DrawScreen() {
	//SDL3_ClearScreenPixels(0xff000000);

	for (y in 0 ..< heightOfRoad) {
		float distance = space_y * scale_y / (y + horizon);

		float fPerspective = y / (SCREEN_HEIGHT_F / 2.0);

		float fRoadWidth = 0.1 + (fPerspective * 0.6);
		float fHalfRoadWidth = fRoadWidth / 2.0;
		float fClipWidth = fRoadWidth * 0.15;
		float fMiddenLijn = fRoadWidth * 0.01;

		float fMiddlePoint = 0.5 + ((curvature * distance) / 400.0);

		int nLeftGrass = (fMiddlePoint - fHalfRoadWidth - fClipWidth) * SCREEN_WIDTH;
		int nLeftClip = (fMiddlePoint - fHalfRoadWidth) * SCREEN_WIDTH;

		int nLeftLijn = (fMiddlePoint - fMiddenLijn) * SCREEN_WIDTH;
		int nRightLijn = (fMiddlePoint + fMiddenLijn) * SCREEN_WIDTH;

		int nRightClip = (fMiddlePoint + fHalfRoadWidth) * SCREEN_WIDTH;
		int nRightGrass = (fMiddlePoint + fHalfRoadWidth + fClipWidth) * SCREEN_WIDTH;

		if (y == heightOfRoad - 40) {
			clipLeft = (fMiddlePoint - fHalfRoadWidth) - 0.5;
			clipRight = (fMiddlePoint + fHalfRoadWidth) - 0.5;
		}

		int nRow = restHeight + y;
		int intDist = distance + playerDistance;
		bool lightGrass = (intDist % 100) > 50;
		bool lightClip = (intDist % 45) > 23;
		bool lightLijn = (intDist % 100) > 75;

		for (x in 0 ..< SCREEN_WIDTH) {
			if (x < nLeftGrass) {
				if (lightGrass)
					pixels[x, nRow] = 0xffa0eb9c;  // light green
				else
					pixels[x, nRow] = 0xff5dc158;  // green
			} else if (x >= nLeftGrass and x < nLeftClip) {
				if (lightClip)
					pixels[x, nRow] = 0xfff1f1f1;  // white
				else
					pixels[x, nRow] = 0xffac4749;  // red
			} else if (x >= nLeftClip and x < nLeftLijn) {
				pixels[x, nRow] = 0xff8f8f8f;      // grey
			} else if (x >= nLeftLijn and x < nRightLijn) {
				if (lightLijn)
					pixels[x, nRow] = 0xffe1e1e1;  // white
				else
					pixels[x, nRow] = 0xff8f8f8f;  // red
			} else if (x >= nRightLijn and x < nRightClip) {
				pixels[x, nRow] = 0xff8f8f8f;      // grey
			} else if (x >= nRightClip and x < nRightGrass) {
				if (lightClip)
					pixels[x, nRow] = 0xfff1f1f1;  // white
				else
					pixels[x, nRow] = 0xffac4749;  // red
			} else if (x >= nRightGrass and x < SCREEN_WIDTH) {
				if (lightGrass)
					pixels[x, nRow] = 0xffa0eb9c;  // light green
				else
					pixels[x, nRow] = 0xff5dc158;  // green
			}
		}
	}
}


function DrawPlayer() {
	playerPositionDisplay = SCREEN_WIDTH_D2_F + (SCREEN_WIDTH_F * playerPosition) - 38.0;
	destRect[0] = playerPositionDisplay;
	destRect[1] = 400.0;

	pointer texturePtr = pl1Texture;
	destRect[2] = 38*2;
	destRect[3] = 75*2;

	float picRange = PLAYER_MAX_STEERING / 3.0;

	if (playerSteering > PLAYER_MAX_STEERING - picRange) {
		texturePtr = pl3Texture;
		destRect[2] = 54*2;
		destRect[3] = 75*2;
	} else if (playerSteering > PLAYER_MAX_STEERING - (2*picRange)) {
		texturePtr = pl2Texture;
		destRect[2] = 37*2;
		destRect[3] = 76*2;
	} else if (playerSteering < -PLAYER_MAX_STEERING + picRange) {
		texturePtr = pl8Texture;
		destRect[2] = 53*2;
		destRect[3] = 75*2;
	} else if (playerSteering < -PLAYER_MAX_STEERING + (2*picRange)) {
		texturePtr = pl7Texture;
		destRect[2] = 37*2;
		destRect[3] = 76*2;
	}

	sdl3.SDL_RenderTextureRotated(renderer, texturePtr, null, destRect, 0.0, null, g.SDL_FLIP_NONE);
}


while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[0])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	if (keyState[g.SDL_SCANCODE_UP]) {
		if (clipHitting) {
			if (speed < MAX_PLAYER_SPEED_ON_CLIP)   speed = speed + PLAYER_ACCELERATION;
		} else if (speed < MAX_PLAYER_SPEED)
			speed = speed + PLAYER_ACCELERATION;
		if (speed > MAX_PLAYER_SPEED)
			speed = MAX_PLAYER_SPEED;
	} else if (keyState[g.SDL_SCANCODE_DOWN]) {
		if (speed > 0.0)  speed = speed - PLAYER_BREAKING;
		if (speed < 0.0)  speed = 0.0;
	} else {
		if (speed > 0.0)  speed = speed - PLAYER_DEACCELERATION;
		if (speed < 0.0)  speed = 0.0;
	}
	if (clipHitting and (speed > MAX_PLAYER_SPEED_ON_CLIP)) {
		if (speed > 0.0)  speed = speed - PLAYER_CLIP_HIT_BREAKING;
		if (speed < 0.0)  speed = 0.0;
	}
	playerDistance = playerDistance + speed;

	if (keyState[g.SDL_SCANCODE_LEFT]) { 
		playerSteering = playerSteering - PLAYER_STEERING;
		if (playerSteering < -PLAYER_MAX_STEERING) playerSteering = -PLAYER_MAX_STEERING;
	} else {
		if (playerSteering < 0.0) {
			playerSteering = playerSteering + PLAYER_STEERING;
			if (playerSteering > 0.0)  playerSteering = 0.0;
		}
	}

	if (keyState[g.SDL_SCANCODE_RIGHT]) {
		playerSteering = playerSteering + PLAYER_STEERING;
		if (playerSteering > PLAYER_MAX_STEERING) playerSteering = PLAYER_MAX_STEERING;
	} else {
		if (playerSteering > PLAYER_STEERING) {
			playerSteering = playerSteering - PLAYER_STEERING;
			if (playerSteering < 0.0)  playerSteering = 0.0;
		}
	}

	destRect[0] = 0;  destRect[1] = 0; destRect[2] = 960; destRect[3] = 210;
	sdl3.SDL_RenderTextureRotated(renderer, backgroundTexture, null, destRect, 0.0, null, g.SDL_FLIP_NONE);

	sdl3.SDL_LockTexture(texture, null, &pixels, &pitch);
	g.[pixels_p] = pixels;

	UpdatePositions();
	DrawScreen();

	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);

	actor1.draw();
	actor2.draw();
	DrawPlayer();

	if (clipHitting)
		writeText(renderer, 10.0, 14.0, "Clipping.");

	//if (speed > ENEMY_ARRIVAL_SPEED)
	//	writeText(renderer, 10.0, 24.0, "Enemies arriving.");

	if (actor1.isHit())
		writeText(renderer, 10.0, 24.0, "Hit!");

	sdl3.SDL_RenderPresent(renderer);

	frameCount++;
}

sdl3.SDL_ShowCursor();
sdl3.SDL_DestroyTexture(pl1Texture);
sdl3.SDL_DestroyTexture(pl2Texture);
sdl3.SDL_DestroyTexture(pl3Texture);
sdl3.SDL_DestroyTexture(pl7Texture);
sdl3.SDL_DestroyTexture(pl8Texture);
sdl3.SDL_DestroyTexture(backgroundTexture);
sdl3.SDL_DestroyTexture(texture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
