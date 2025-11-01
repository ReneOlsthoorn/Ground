

f32[4] playerSrcRect = [0,0,8,16];
f32[4] playerDestRect = [10,30,8,16];


class Tree {
	int x;
	int y;
	function Randomize() {
		this.x = 40 + ((msvcrt.rand() % 20) * 8);
		this.y = 20 + ((msvcrt.rand() % 20) * 6);
	}
	function Draw() {
		playerDestRect[0] = this.x;
		playerDestRect[1] = this.y;
		sdl3.SDL_RenderTextureRotated(renderer, treesTextures[i % 8], playerSrcRect, playerDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}
	function HitHeightWithBullet(int bulletX, int bulletY) : int {
		if (bulletX > (this.x - 5) and bulletX < (this.x + 5) and bulletY >= (this.y - 5) and bulletY <= (this.y + 10)) {
			int returnY = bulletY - (this.y - 5);
			returnY = (returnY / 5) + 1;
			return returnY;
		}
		return 0;  // no hit
	}
	function IsHittingPlayer(int playerX, int playerY) : bool {
		return (playerX > (this.x - 5) and playerX < (this.x + 5) and playerY >= (this.y - 9) and playerY <= (this.y + 10));
	}
}


#define ACTOR_ACTION_NO_MOVEMENT 0
#define ACTOR_ACTION_MOVING 1
#define ACTOR_ACTION_SHOOTING 2
#define ACTOR_ACTION_DEATH 3
#define ACTOR_ACTION_BACKFROMSHOOTING 4


class Actor {
	float x;
	float y;

	bool  bullet_flying;
	float bullet_x;
	float bullet_y;
	float bullet_delta_x;
	float bullet_delta_y;
	int   bullet_ricochets;
	int   bullet_last_hit_tree;

	bool visible;
	int frameIndex;			 // public: the picture to display. Is an index within the "frames" array.
	int animationArrayIndex; // private: the index within the animation array. Each action has it's own animation array.
	bool animationDone;
	int action;				// 0 = no movement, 1 = moving, 2 = shooting (unable to move before first ricochet), 3 = death (unable to move)
	bool facingRight;		// if false the player faces left
	bool died;
	int score;


	function DetermineFrameIndex() {
		if (this.action == ACTOR_ACTION_NO_MOVEMENT) {
			this.frameIndex = 0;
		} else if (this.action == ACTOR_ACTION_MOVING) {
			if (this.animationArrayIndex >= countof(moveAnimation))
				this.animationArrayIndex = 0;
			this.frameIndex = moveAnimation[this.animationArrayIndex];
		} else if (this.action == ACTOR_ACTION_SHOOTING) {
			if (this.animationArrayIndex >= countof(shootAnimation)) {
				this.animationArrayIndex = countof(shootAnimation) - 1;
				this.animationDone = true;
			}
			this.frameIndex = shootAnimation[this.animationArrayIndex];
		} else if (this.action == ACTOR_ACTION_DEATH) {
			if (this.animationArrayIndex >= countof(deathAnimation)) {
				this.animationArrayIndex = countof(deathAnimation) - 1;
				this.animationDone = true;
			}
			this.frameIndex = deathAnimation[this.animationArrayIndex];
		} else if (this.action == ACTOR_ACTION_BACKFROMSHOOTING) {
			if (this.animationArrayIndex >= countof(aftershootAnimation)) {
				this.animationDone = true;
				this.action = ACTOR_ACTION_NO_MOVEMENT;  // SetAction cannot be called, because it is not defined yet...
				this.animationArrayIndex = 0;
				this.animationDone = false;
				this.frameIndex = 0;
			} else {
				this.frameIndex = aftershootAnimation[this.animationArrayIndex];
			}
		}
	}

	function SetAction(int theAction) {
		if (this.action == ACTOR_ACTION_DEATH)		// after death no actions
			return;
		if (this.action == theAction)				// the same action cannot reset the animationArrayIndex
			return;
		if (theAction == ACTOR_ACTION_BACKFROMSHOOTING and (this.action == ACTOR_ACTION_NO_MOVEMENT or this.action == ACTOR_ACTION_MOVING))
			return;
		this.action = theAction;
		this.animationArrayIndex = 0;
		this.animationDone = false;
		this.DetermineFrameIndex();
	}

	function BulletFired() {
		this.bullet_flying = true;
		this.bullet_delta_y = 0.0;
		if (this.facingRight) {
			this.bullet_x = this.x + 3.0;
			this.bullet_delta_x = FULL_BULLET_SPEED;
		} else {
			this.bullet_x = this.x - 3.0;
			this.bullet_delta_x = -FULL_BULLET_SPEED;
		}
		playShoot();
		this.bullet_y = this.y;
		this.bullet_ricochets = 0;
		this.bullet_last_hit_tree = -1;
	}

	function AnimationTick() {
		this.animationArrayIndex = this.animationArrayIndex + 1;
		this.DetermineFrameIndex();

		if (this.action == ACTOR_ACTION_SHOOTING and this.animationDone) {
			if (!this.bullet_flying)
				this.BulletFired();
		}
	}

	function GetTexture(ptr *textures) : ptr {
		int result = this.frameIndex;
		bool faceResult = this.facingRight;
		if (result < 0) {
			result = -result;
			faceResult = !faceResult;
		}
		if (faceResult)
			return textures[result];
		else
			return textures[result+14];
	}

	function GetTextureOtherHalf(ptr *textures) {
		int result = this.frameIndex+1;
		if (this.facingRight)
			return textures[result];
		else
			return textures[result+14];
	}

	function ValidateMove() {
		if (this.x >= 10.0 and this.x < 239.0 and this.y > 12.0 and this.y < 152.0)
			return true;
		playBeep();
		return false;
	}

	function MoveRight() {
		if (this.action == ACTOR_ACTION_SHOOTING or this.action == ACTOR_ACTION_DEATH)
			return;
		this.facingRight = true;
		this.x = this.x + 0.5;
		this.SetAction(ACTOR_ACTION_MOVING);
		if not (this.ValidateMove())
			this.x = this.x - 0.5;
	}

	function MoveLeft() {
		if (this.action == ACTOR_ACTION_SHOOTING or this.action == ACTOR_ACTION_DEATH)
			return;
		this.facingRight = false;
		this.x = this.x - 0.5;
		this.SetAction(ACTOR_ACTION_MOVING);
		if not (this.ValidateMove())
			this.x = this.x + 0.5;
	}

	function MoveUp() {
		if (this.action == ACTOR_ACTION_SHOOTING or this.action == ACTOR_ACTION_DEATH)
			return;
		this.y = this.y - 0.5;
		this.SetAction(ACTOR_ACTION_MOVING);
		if not (this.ValidateMove())
			this.y = this.y + 0.5;
	}

	function MoveDown() {
		if (this.action == ACTOR_ACTION_SHOOTING or this.action == ACTOR_ACTION_DEATH)
			return;
		this.y = this.y + 0.5;
		this.SetAction(ACTOR_ACTION_MOVING);
		if not (this.ValidateMove())
			this.y = this.y - 0.5;
	}

	function Shoot() {
		if (this.action == ACTOR_ACTION_DEATH)
			return;
		if not (this.bullet_flying)
			this.SetAction(ACTOR_ACTION_SHOOTING);
	}

	function Init() {
		this.action = ACTOR_ACTION_NO_MOVEMENT;
		this.bullet_flying = false;
		this.bullet_delta_x = 0.0;
		this.bullet_ricochets = 0;
		this.bullet_last_hit_tree = -1;
		this.died = false;
	}

	function MoveBullet() {
		if not (this.bullet_flying)
			return;
		if (this.bullet_x >= 0.0 and this.bullet_x < 240.0) {
			this.bullet_x = this.bullet_x + this.bullet_delta_x;
			this.bullet_y = this.bullet_y + this.bullet_delta_y;
		} else {
			this.bullet_flying = false;
			this.bullet_delta_x = 0.0;
			this.SetAction(ACTOR_ACTION_NO_MOVEMENT);
		}
		if (this.bullet_y < 8.0 or this.bullet_y > 180.0) {
			playHit();
			this.bullet_delta_y = -this.bullet_delta_y;
		}
	}

	function Death() {
		playHurt();
		this.SetAction(ACTOR_ACTION_DEATH);
		this.died = true;
	}

	function CheckHit(int bulletX, int bulletY) : bool {
		int theX = this.x;
		int theY = this.y;
		bool result = false;
		if (bulletX > (theX - 5) and bulletX < (theX + 5) and bulletY >= (theY - 5) and bulletY <= (theY + 10)) {
			this.Death();
			result = true;
		}
		return result;
	}

	function HandleBulletHitOnTree(int hit) {
		if (hit > 0) {
			if (hit == 1) {
				if (this.bullet_delta_x == FULL_BULLET_SPEED)
					this.bullet_delta_x = (this.bullet_delta_x / 1.5);
				else
					this.bullet_delta_x = this.bullet_delta_x;
				this.bullet_delta_y = -1.5;
			} else if (hit == 2) {
				if (this.bullet_delta_x == FULL_BULLET_SPEED)
					this.bullet_delta_x = -(this.bullet_delta_x / 1.5);
				else
					this.bullet_delta_x = -this.bullet_delta_x;
				this.bullet_delta_y = -1.5;
			} else if (hit >= 3) {
				this.bullet_delta_x = -this.bullet_delta_x;
			}
			this.bullet_last_hit_tree = i;
			playHit();
			this.bullet_ricochets = this.bullet_ricochets + 1;
			if (this.bullet_ricochets > 7) {
				this.bullet_flying = false;
			}
			this.SetAction(ACTOR_ACTION_BACKFROMSHOOTING);   // Once a ricochet has occured, the player can move.
		}
	}

	function RenderPlayer(ptr *textures) {
		playerDestRect[0] = this.x;
		playerDestRect[1] = this.y;
		sdl3.SDL_RenderTextureRotated(renderer, this.GetTexture(textures), playerSrcRect, playerDestRect, 0.0, null, g.SDL_FLIP_NONE);
		if (this.frameIndex == 10 or this.frameIndex == 12) {
			if (this.facingRight)
				playerDestRect[0] = this.x + 8.0;
			else
				playerDestRect[0] = this.x - 8.0;
			sdl3.SDL_RenderTextureRotated(renderer, this.GetTextureOtherHalf(textures), playerSrcRect, playerDestRect, 0.0, null, g.SDL_FLIP_NONE);
		}
	}

	function RenderBullet() {
		playerDestRect[0] = this.bullet_x;
		playerDestRect[1] = this.bullet_y;
		sdl3.SDL_RenderTextureRotated(renderer, bulletTexture, playerSrcRect, playerDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}

}



class ComputerPlayer {
	int timeOut;				// the computer player will not move a random time after a shot.
	int stuckCounter;			// how many frames is the computer player stuck in a tree. Take an other route after that.
	int otherRouteTimer;		// the computer player was stuck too long. We no longer aim at the human player, but for a random other position.
	int otherRouteX;			// this is the x for the random other position the computer player focusses on after getting stuck.
	int otherRouteY;
	int looseCounter;
	int campingCounter;

	function Init() {
		this.timeOut = 0;
		this.stuckCounter = 0;
		this.otherRouteTimer = 0;
		this.looseCounter = 0;
		this.campingCounter = 0;
	}

	function AddCamping() {
		this.campingCounter = this.campingCounter + 1;
		if (this.campingCounter > 180) {
			this.otherRouteTimer = 120;
			this.otherRouteX = msvcrt.rand() % 240;
			this.otherRouteY = msvcrt.rand() % 180;
			this.campingCounter = 0;
		}
	}

	function RemoveCamping() {
		this.campingCounter = 0;
	}

	function BeingStuck() {
		this.stuckCounter = this.stuckCounter + 1;
		if (this.stuckCounter > 5) {
			this.otherRouteTimer = 120;
			this.otherRouteX = msvcrt.rand() % 240;
			this.otherRouteY = msvcrt.rand() % 180;
			this.stuckCounter = 0;
		}
	}

	function BeingLoose() {
		if (this.stuckCounter == 0 and this.looseCounter == 0) 
			return;
		if (this.stuckCounter != 0) {
			this.looseCounter = this.looseCounter + 1;
			if (this.looseCounter > 10) {
				this.stuckCounter = 0;		// only reset the stuckCounter when the player is loose for a time.
				this.looseCounter = 0;
			}	
		}
	}
}
