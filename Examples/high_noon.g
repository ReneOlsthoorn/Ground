
#template sdl3


// DEFINES

#define BORDERSIZE_HORIZONTAL 50
#define BORDERSIZE_VERTICAL 50
#define NR_PLAYERS 2
#define NR_TREES 10
#define FULL_BULLET_SPEED 3.0
#define COWBOY_WIDTH 8
#define COWBOY_HEIGHT 16
#define COWBOY_FRAMES COWBOY_HEIGHT*16
#define WIN_SCORE 10


// GENERIC INCLUDES

#include graphics_defines1280x720.g
#include msvcrt.g
#include sdl3.g
#include kernel32.g
#include user32.g
#include sidelib.g
#include soloud.g


// GENERIC GLOBAL VARIABLES

u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int pitch = SCREEN_LINESIZE;
string gameStatus = "game running";    // "intro screen", "game running", "game over"


// CREATING A WINDOW

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("High Noon", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();


#include high_noon_animation.g
#include high_noon_player.g


// SPECIFIC GLOBAL VARIABLES

Actor[NR_PLAYERS] player = [ ];
Tree[NR_TREES] trees = [ ];
int deathTimeout = 0;			// if there is a death of any player, we need a timeout so the user can enjoy the win moment. Then reset the play. 
ComputerPlayer ai;

function HasTreeHit(int playerX, int playerY) : bool {
	for (i in 0 ..< NR_TREES) {
		if (trees[i].IsHittingPlayer(playerX, playerY))
			return true;
	}
	return false;
}

function ComputerPlayerHasTreeInBulletPath() : bool {
	int p1x = player[0].x;
	int p1y = player[0].y;
	int p2x = player[1].x;
	int p2y = player[1].y;

	for (i in 0 ..< NR_TREES) {
		int tx = trees[i].x;
		int ty = trees[i].y;
		if ((player[1].facingRight and tx >= p2x and tx <= p1x) or (!(player[1].facingRight) and tx <= p2x and tx >= p1x)) {
			if (trees[i].HitHeightWithBullet(tx, player[1].y) > 0)
				return true;
		}
	}
	return false;
}

function NewDuel() {
	// Raise the scores.
	if (player[0].died)
		player[1].score = player[1].score + 1;
	if (player[1].died)
		player[0].score = player[0].score + 1;
	player[0].died = false;
	player[1].died = false;

	bool scoredEnough = (player[0].score >= WIN_SCORE or player[1].score >= WIN_SCORE);
	bool scoreDifferenceEnough = (msvcrt.abs(player[0].score - player[1].score) >= 1);

	if (scoredEnough and scoreDifferenceEnough) {
		gameStatus = "game over";
		return;
	}

	ai.Init();
	ai.timeOut = 60;
	deathTimeout = 0;
	player[0].Init();
	player[0].x = 19.0;
	player[0].y = 22.0;
	player[0].facingRight = true;
	player[1].Init();
	player[1].x = 226.0;
	player[1].y = 140.0;
	player[1].facingRight = false;
	for (i in 0 ..< NR_TREES)
		trees[i].Randomize();
}

function RestartGame() {
	gameStatus = "game running";
	ai.Init();
	player[0].score = 0;
	player[1].score = 0;
	NewDuel();
}

RestartGame();
gameStatus = "intro screen";

f32 fontScale = 2.0;
function writeText(ptr renderer, float x, float y, string text) {
	sdl3.SDL_SetRenderScale(renderer, fontScale, fontScale);
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x+2.0, y, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, x, y, text);
}

function PrintScore() {
	int score1 = player[0].score;
	if (player[1].died)
		score1 = score1 + 1;
	writeText(renderer, 25.0, 10.0, "Blue: " + score1);
	int score2 = player[1].score;
	if (player[0].died)
		score2 = score2 + 1;
	writeText(renderer, 320.0, 10.0, "White: " + score2);
}

function PrintGameOver() {
	if (player[0].score > player[1].score)
		writeText(renderer, 185.0, 150.0, "You Won the High Noon shootout!");
	else
		writeText(renderer, 185.0, 150.0, "You lost the High Noon shootout.");
	writeText(renderer, 185.0, 190.0, "     Press space to restart.");
}

function PrintIntroScreen() {
	writeText(renderer, 120.0, 110.0, "Your 1980 Videopac G7000 was ridiculed by your enemy.");
	writeText(renderer, 140.0, 130.0, " You meet him at High Noon to settle the case.");
	writeText(renderer, 140.0, 150.0, "   First player to reach a score of 10 wins.");
	writeText(renderer, 140.0, 170.0, "       On a draw, the match continues.");
	writeText(renderer, 140.0, 210.0, "           Press [space] to start.");
}


// MAINLOOP

while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
			if (*eventScancode == g.SDL_SCANCODE_SPACE) { 
				if (gameStatus != "game running") { 
					if (gameStatus == "intro screen")
						gameStatus = "game running";
					else
						RestartGame();
				} else {
					player[0].Shoot();
				}
			}
		}
	}

	sdl3.SDL_RenderTexture(renderer, bgTexture, null, null);


	// HUMAN MOVEMENT

	u8* keyState = sdl3.SDL_GetKeyboardState(null);
	bool playerMoved = false;
	float oldP1x = player[0].x;
	float oldP1y = player[0].y;
	if (keyState[g.SDL_SCANCODE_RIGHT]) { player[0].MoveRight(); playerMoved = true; }
	if (keyState[g.SDL_SCANCODE_LEFT])  { player[0].MoveLeft();  playerMoved = true; }
	if (keyState[g.SDL_SCANCODE_UP])    { player[0].MoveUp();    playerMoved = true; }
	if (keyState[g.SDL_SCANCODE_DOWN])  { player[0].MoveDown();  playerMoved = true; }
	if not (playerMoved) {
		if (player[0].action == ACTOR_ACTION_MOVING)
			player[0].action = ACTOR_ACTION_NO_MOVEMENT;
	}
	if (HasTreeHit(player[0].x, player[0].y) or gameStatus != "game running") {		// When hitting a tree, the human player will get stuck.
		player[0].x = oldP1x;
		player[0].y = oldP1y;
	}


	// COMPUTER PLAYER MOVEMENT

	int p1x = player[0].x;
	int p1y = player[0].y;
	int p2x = player[1].x;
	int p2y = player[1].y;
	float oldP2x = p2x;
	float oldP2y = p2y;

	if (gameStatus == "game running") {
	if (ai.otherRouteTimer >= 2) {
		// otherRouteTimer is active after the computer is stuck and now has focus on a new position to be able get loose.
		p1x = ai.otherRouteX;
		p1y = ai.otherRouteY;
		ai.otherRouteTimer = ai.otherRouteTimer - 1;
	} else
		ai.otherRouteTimer = 0;

	bool computerPlayerMoved = false;
	if (ai.timeOut == 0 and deathTimeout == 0) {
		if (p1x < p2x and (p2x-p1x) > 10) {
			if (frameCount % 2 == 0) {
				player[1].MoveLeft();
				computerPlayerMoved = true;
			}
		} else if (p1x > p2x and (p1x-p2x) > 10) {
			player[1].MoveRight();
			computerPlayerMoved = true;
		}
		player[1].facingRight = (p1x > p2x);
		if (p1y < p2y and (p2y-p1y) > 5) {
			player[1].MoveUp();
			computerPlayerMoved = true;
		} else if (p1y > p2y and (p1y-p2y) > 5) {
			player[1].MoveDown();
			computerPlayerMoved = true;
		} else {
			bool hasTreeInFront = ComputerPlayerHasTreeInBulletPath();
			if (!hasTreeInFront and player[0].action != ACTOR_ACTION_DEATH and player[1].action != ACTOR_ACTION_DEATH and ai.otherRouteTimer == 0) {
				player[1].Shoot();
				ai.timeOut = msvcrt.rand() % 120;
			} else if (hasTreeInFront) {
				ai.BeingStuck();
			}
		}
	} else if (deathTimeout == 0)
		ai.timeOut = ai.timeOut - 1;
	
	if not (computerPlayerMoved) {
		//if (player[1].action == ACTOR_ACTION_MOVING)
		//	player[1].SetAction(ACTOR_ACTION_NO_MOVEMENT);
		ai.AddCamping();
	}
	else
		ai.RemoveCamping();

	if (HasTreeHit(player[1].x, player[1].y)) {
		player[1].x = oldP2x;
		if (HasTreeHit(player[1].x, player[1].y)) {
			player[1].y = oldP2y;
			ai.BeingStuck();
		}
	} else
		ai.BeingLoose();

	}

	if (frameCount % 5 == 0) {
		player[0].AnimationTick();
		player[1].AnimationTick();
	}


	// DRAW PLAYERS AND THEIR BULLETS

	f32 scale = 5.0;
	f32 scaleY = 4.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scaleY);

	player[0].RenderPlayer(texturesPlayer1);
	player[0].MoveBullet();
	if (player[0].bullet_flying)
		player[0].RenderBullet();

	player[1].RenderPlayer(texturesPlayer2);
	player[1].MoveBullet();
	if (player[1].bullet_flying)
		player[1].RenderBullet();


	// DRAW TREES AND CALCULATE BULLET COLLISIONS WITH TREES

	for (i in 0 ..< NR_TREES) {
		trees[i].Draw();

		// BULLET COLLISIONS WITH TREES

		if (player[0].bullet_flying and (player[0].bullet_last_hit_tree != i)) {
			int hit = trees[i].HitHeightWithBullet(player[0].bullet_x, player[0].bullet_y);
			player[0].HandleBulletHitOnTree(hit);
		}
		if (player[1].bullet_flying and (player[1].bullet_last_hit_tree != i)) {
			hit = trees[i].HitHeightWithBullet(player[1].bullet_x, player[1].bullet_y);
			player[1].HandleBulletHitOnTree(hit);
		}
	}


	// BULLET COLLISIONS WITH PLAYERS

	if (player[0].bullet_flying) {
		if (player[0].CheckHit(player[0].bullet_x, player[0].bullet_y)) {
			player[0].bullet_flying = false;
			player[0].SetAction(ACTOR_ACTION_BACKFROMSHOOTING);
		}
		if (player[1].CheckHit(player[0].bullet_x, player[0].bullet_y)) {
			player[0].bullet_flying = false;
			player[0].SetAction(ACTOR_ACTION_BACKFROMSHOOTING);
		}
	}
	if (player[1].bullet_flying) {
		if (player[0].CheckHit(player[1].bullet_x, player[1].bullet_y)) {
			player[1].bullet_flying = false;
			player[1].SetAction(ACTOR_ACTION_BACKFROMSHOOTING);
		}
		if (player[1].CheckHit(player[1].bullet_x, player[1].bullet_y)) {
			player[1].bullet_flying = false;
			player[1].SetAction(ACTOR_ACTION_BACKFROMSHOOTING);
		}
	}


	// DEATH TIMEOUT

	if (deathTimeout > 0 and gameStatus == "game running") {
		deathTimeout = deathTimeout - 1;
		if (deathTimeout == 170)
			playHurt();
		if (deathTimeout == 0)
			NewDuel();
	} else {
		if (player[0].action == ACTOR_ACTION_DEATH or player[1].action == ACTOR_ACTION_DEATH)
			deathTimeout = 200;
	}

	if (gameStatus == "intro screen")
		PrintIntroScreen();
	PrintScore();
	if (gameStatus == "game over")
		PrintGameOver();

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}


soloud.Sfxr_destroy(sfxrSelectObject);
soloud.Sfxr_destroy(sfxrObject);
soloud.Sfxr_destroy(dropObject);
soloud.Sfxr_destroy(sfxrHurtObject);
soloud.Soloud_deinit(soloudObject);
soloud.Soloud_destroy(soloudObject);

sdl3.SDL_ShowCursor();
FreeTextures();
sdl3.SDL_DestroyTexture(bgTexture);
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
