
int currentTime = 0;
msvcrt.time64(&currentTime);
msvcrt.srand(currentTime);

int[] moveAnimation = [1,2,3,4,5,6] asm;
int[] shootAnimation = [7,7,8,8] asm;
int[] deathAnimation = [4,4,-4,-4,4,4,-4,-4,4,4,-4,-4,4,4,-4,-4,9,9,9, 10,10,10, 12,12,12] asm;
int[] aftershootAnimation = [8,8,7,7] asm;

byte[COWBOY_FRAMES] frames = [ 
0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b.XXXXXX.,
0b.X.XX.X.,
0bX..XX..X,
0bX..XX..X,
0bX..XX..X,
0b..XXXX..,
0b..XXXX..,
0b.XX..XX.,
0b.X....X.,
0b.X....X.,
0b.X....X.,
0bXX....XX,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b..XXXX..,
0b..XXXX..,
0b..XXX.X.,
0b.X.XX..X,
0bX..XX..X,
0bX..XX...,
0b...X.X..,
0b..X...X.,
0b.X....X.,
0b.X....X.,
0b..X...XX,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b...XX...,
0b..XXXX..,
0b..XXX.X.,
0b.X.XX.X.,
0b.X.XX.X.,
0b...XX...,
0b...X.X..,
0b...X..X.,
0b..XX..X.,
0b..X...X.,
0b......XX,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b...XXX..,
0b..XXXX..,
0b..XXXX..,
0b..XXXX..,
0b.X.XXX..,
0b...XXX..,
0b....XX..,
0b...XXX..,
0b..XXXX..,
0b.....X..,
0b.....XX.,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b..XXXX..,
0b..XXXX..,
0b.XXXXXX.,
0b..XXX.X.,
0b...XX.X.,
0b...XX.X.,
0b...X.X..,
0b...X.X..,
0b...X.XX.,
0b...X....,
0b...XX...,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b..XXXX..,
0b..XXXX..,
0b.X.XX.X.,
0b.X.XX.X.,
0b.X.XX.XX,
0b..XXX...,
0b..X..X..,
0b.X....X.,
0b.X....X.,
0b.X....XX,
0b.XX.....,

0b...XX...,
0b.XXXXXX.,
0b...XX...,
0b...X....,
0b...XX...,
0b..XXXX..,
0b..XXXX..,
0b.X.XX.X.,
0bX..XX..X,
0bX..XX..X,
0b...XX...,
0b..X.X...,
0b.X...X..,
0b.X...X..,
0bX.....X.,
0bXX....XX,

0b..XX....,
0b.XXXXX..,
0b..XX....,
0b..X.....,
0b..XX....,
0b..XXX...,
0b..XXXXX.,
0b.XXX..XX,
0b.XXX....,
0b.XXX....,
0b..XX....,
0b..XX....,
0b.X..X...,
0b.X..X...,
0b.X..XX..,
0b.XX.....,

0b.XX.....,
0bXXXXX...,
0b.XX.....,
0b.X......,
0b.XX...X.,
0b.XXXXXXX,
0bXXXXXXX.,
0bXXX.....,
0bXXX.....,
0bXXX.....,
0bXXX.....,
0b.XXX....,
0b.X.X....,
0b.X..X...,
0b.X..X...,
0b.XX.XX..,

0b.....XX.,
0b...XXXXX,
0b.....XX.,
0bX....XX.,
0bXX.XXXX.,
0b..XXXXX.,
0b...XXXX.,
0b...XX.X.,
0b..XXX.X.,
0b..XXX.XX,
0b..XXXX..,
0b..X..X..,
0b..X..X..,
0b.X..X...,
0bXX.XX...,
0bX.......,

0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b.......X,
0b.....XXX,
0b....XXXX,
0b..XXX...,
0bXXX.....,
0bX.......,

0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b....XXXX,
0b.XXXXXXX,
0bXXXX...X,
0bXXXX....,
0bX.X.....,
0b.X......,
0bX.......,
0b........,

0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b.......X,
0b.....XXX,
0bX...XXXX,
0bXXXXXXXX,
0bXXXXXXXX,

0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0bX.......,
0bXXX.....,
0bXXXX..XX,
0bXXXXXXXX,
0bXXXXX.XX,

0b........,
0b........,
0b........,
0b........,
0b..XXXX..,
0b..XXXX..,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,
0b........,

0b...XX...,
0b...XX...,
0b...XX...,
0b..XXXX..,
0b..XXXX..,
0b..XXXX..,
0b.XXXXXX.,
0b.XXXXXX.,
0b.XXXXXX.,
0bXXXXXXXX,
0bXXXXXXXX,
0b...XX...,
0b...XX...,
0b...XX...,
0b...XX...,
0b...XX...

] asm;


ptr[28] texturesPlayer1 = [ ] asm;  // 28 = (1 no_movement + 6 movement + 2 shooting + 5 dying) * 2 faces
ptr[28] texturesPlayer2 = [ ] asm;  // 28 = (1 no_movement + 6 movement + 2 shooting + 5 dying) * 2 faces
ptr[8] treesTextures = [ ] asm;     // 8 colors

u32[COWBOY_WIDTH, COWBOY_HEIGHT] cowboyPixels = null;
int cowboyPitch = 8;
ptr bulletTexture;

function prepareTexture(int frameNr, bool reverse, ptr destTexture, int pixelColor) {
	ptr tmpTexture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, 8, 16);
	sdl3.SDL_LockTexture(tmpTexture, null, &cowboyPixels, &cowboyPitch);
	for (y in 0..15) {
		for (i in 0..7) {
			int bitInByte = 7-i;
			if (reverse)
				bitInByte = i;
			if (gc.BitValue(frames[y+(frameNr*16)], bitInByte) == 1) {
				cowboyPixels[i,y] = pixelColor;
			} else {
				cowboyPixels[i,y] = 0x00000000;
			}
		}
	}
	sdl3.SDL_UnlockTexture(tmpTexture);
	sdl3.SDL_SetTextureScaleMode(tmpTexture, g.SDL_SCALEMODE_NEAREST);
	*destTexture = tmpTexture;
}

function FreeTextures() {
	for (i in 0..< 28) {
		sdl3.SDL_DestroyTexture(texturesPlayer1[i]);
		sdl3.SDL_DestroyTexture(texturesPlayer2[i]);
	}
	sdl3.SDL_DestroyTexture(bulletTexture);
	for (i in 0 ..< 8) {
		sdl3.SDL_DestroyTexture(treesTextures[i]);
	}
}

for (i in 0 ..< 14) {
	prepareTexture(i, false, &texturesPlayer1[i], 0xff4451FF);
	prepareTexture(i, true, &texturesPlayer1[i+14], 0xff4451FF);
	prepareTexture(i, false, &texturesPlayer2[i], 0xffffffff);
	prepareTexture(i, true, &texturesPlayer2[i+14], 0xffffffff);
}
prepareTexture(14, false, &bulletTexture, 0xffffffff);
prepareTexture(15, false, &treesTextures[0], 0xffFFF442);  // yellow
prepareTexture(15, false, &treesTextures[1], 0xff3AE244);  // green
prepareTexture(15, false, &treesTextures[2], 0xffFF5947);  // light red
prepareTexture(15, false, &treesTextures[3], 0xff48484A);  // grey
prepareTexture(15, false, &treesTextures[4], 0xffFFFFFF);  // white
prepareTexture(15, false, &treesTextures[5], 0xff3AEDFF);  // cyan
prepareTexture(15, false, &treesTextures[6], 0xffFF64FF);  // pink
prepareTexture(15, false, &treesTextures[7], 0xff4653FF);  // blue



// SOUND RELATED

ptr soloudObject = soloud.Soloud_create();
int soloudResult = soloud.Soloud_init(soloudObject);
if (soloudResult != 0) return;
ptr sfxrObject = soloud.Sfxr_create();
int sfxrLoaded = soloud.Sfxr_loadParams(sfxrObject, "sound/sfxr/explosion4.sfs");
if (sfxrLoaded != 0) return;
ptr dropObject = soloud.Sfxr_create();
int dropLoaded = soloud.Sfxr_loadParams(dropObject, "sound/sfxr/hit3.sfs");
if (dropLoaded != 0) return;
ptr sfxrSelectObject = soloud.Sfxr_create();
int sfxrSelectLoaded = soloud.Sfxr_loadParams(sfxrSelectObject, "sound/sfxr/select.sfs");
if (sfxrSelectLoaded != 0) return;
ptr sfxrHurtObject = soloud.Sfxr_create();
int sfxrHurtLoaded = soloud.Sfxr_loadParams(sfxrHurtObject, "sound/sfxr/hurt.sfs");
if (sfxrHurtLoaded != 0) return;

f32 theVolume = 1.0;
soloud.Sfxr_setVolume(sfxrObject, theVolume);
soloud.Sfxr_setVolume(dropObject, theVolume);
soloud.Sfxr_setVolume(sfxrHurtObject, theVolume);
theVolume = 0.5;
soloud.Sfxr_setVolume(sfxrSelectObject, theVolume);
//soloud.Sfxr_setLooping(sfxrHurtObject, 1);   // 1 = true, 0 = false

function playShoot() { soloud.Soloud_play(soloudObject, sfxrObject); }
function playHit() { soloud.Soloud_play(soloudObject, dropObject); }
function playBeep() { soloud.Soloud_play(soloudObject, sfxrSelectObject); }
function playHurt() { soloud.Soloud_play(soloudObject, sfxrHurtObject); }



// BACKGROUND RELATED

ptr bgTexture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_LockTexture(bgTexture, null, &pixels, &pitch);

function PixelColorBackground(int px, int py) : int {
	int startX = px - BORDERSIZE_HORIZONTAL;
	if (startX < 0)
		return 0;
	if (px >= (SCREEN_WIDTH - BORDERSIZE_HORIZONTAL))
		return 0;
	int startY = py - BORDERSIZE_VERTICAL;
	if (startY < 0)
		return 0;
	if (py >= (SCREEN_HEIGHT - BORDERSIZE_VERTICAL))
		return 0;
	return 1;
}

function GenerateBackground() {
	for (y in 0..< SCREEN_HEIGHT) {
		for (x in 0..< SCREEN_WIDTH) {
			int pixelColor = PixelColorBackground(x,y);
			if (pixelColor == 0)
				pixels[x,y] = 0xffC61100;
			if (pixelColor == 1)
				pixels[x,y] = 0xffB7AA00;
		}
	}
}
GenerateBackground();

sdl3.SDL_UnlockTexture(bgTexture);
sdl3.SDL_SetTextureScaleMode(bgTexture, g.SDL_SCALEMODE_NEAREST);

