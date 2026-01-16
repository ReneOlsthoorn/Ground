

f32[4] waterSrcRect = [0,0, 482, 95];
f32[4] waterDestRect = [0,460, 482, 95];
ptr waterSurface = sdl3.SDL_LoadPNG("image/water.png");
if (waterSurface == null) return;
ptr waterTexture = sdl3.SDL_CreateTextureFromSurface(renderer, waterSurface);
if (waterTexture == null) return;
sdl3.SDL_SetTextureScaleMode(waterTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(waterSurface);


u32* elBackground = sidelib.LoadImage("image/el_background.png");
if (elBackground == null) return;
sidelib.FlipRedAndGreenInImage(elBackground, SCREEN_WIDTH, SCREEN_HEIGHT);


f32[4] smileyDestRect = [600,460, 44, 44];
ptr smileySurface = sdl3.SDL_LoadPNG("image/el_smiley.png");
if (smileySurface == null) return;
ptr smileyTexture = sdl3.SDL_CreateTextureFromSurface(renderer, smileySurface);
if (smileyTexture == null) return;
sdl3.SDL_SetTextureScaleMode(smileyTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(smileySurface);


f32[4] levelSrcRect = [0, 0, 18, 108];
f32[4] levelDestRect = [0, 0, 18, 108];
ptr levelSurface = sdl3.SDL_LoadPNG("image/analyzer_level.png");
if (levelSurface == null) return;
ptr levelTexture = sdl3.SDL_CreateTextureFromSurface(renderer, levelSurface);
if (levelTexture == null) return;
sdl3.SDL_SetTextureScaleMode(levelTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(levelSurface);


f32[4] ballSrcRect = [0,64,32,32];
f32[4] ballDestRect = [0,0,32,32];
ptr ballSurface = sdl3.SDL_LoadPNG("image/3balls_32.png");
if (ballSurface == null) return;
ptr ballTexture = sdl3.SDL_CreateTextureFromSurface(renderer, ballSurface);
if (ballTexture == null) return;
sdl3.SDL_SetTextureScaleMode(ballTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(ballSurface);


f32[4] fontSrcRect = [0,0,40,41];
f32[4] fontDestRect = [0,0,40,41];
ptr fontSurface = sdl3.SDL_LoadPNG("image/thefont_rgba_outline.png");
if (fontSurface == null) return;
ptr ballFontTexture = sdl3.SDL_CreateTextureFromSurface(renderer, fontSurface);
if (ballFontTexture == null) return;
sdl3.SDL_SetTextureScaleMode(ballFontTexture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_DestroySurface(fontSurface);


int* fontXOffsets = msvcrt.calloc(sizeof(int), 256);
int* fontYOffsets = msvcrt.calloc(sizeof(int), 256);

function setupFontOffsetsLine(string fontString, int offsetY) {
	for (i in 0..7) {
		fontXOffsets[fontString[i]] = i * 40;
		fontYOffsets[fontString[i]] = offsetY;
	}
}

setupFontOffsetsLine("abcdefgh", 0);
setupFontOffsetsLine("ijklmnop", 1*41);
setupFontOffsetsLine("qrstuvwx", 2*41);
setupFontOffsetsLine(`yz!"#$'(`, 3*41);
setupFontOffsetsLine(").+,-/01", 4*41);
setupFontOffsetsLine("23456789", 5*41);
setupFontOffsetsLine(";>=<? !@", 6*41);

setupFontOffsetsLine("ABCDEFGH", 0);
setupFontOffsetsLine("IJKLMNOP", 1*41);
setupFontOffsetsLine("QRSTUVWX", 2*41);
setupFontOffsetsLine(`YZ!"#$'(`, 3*41);


function DestroyTextures() {
	sdl3.SDL_DestroyTexture(ballFontTexture);
	sdl3.SDL_DestroyTexture(ballTexture);
	sdl3.SDL_DestroyTexture(texture);
	sdl3.SDL_DestroyTexture(waterTexture);
	sdl3.SDL_DestroyTexture(smileyTexture);
	sdl3.SDL_DestroyTexture(levelTexture);

	msvcrt.free(fontXOffsets);
	msvcrt.free(fontYOffsets);

	sidelib.FreeImage(elBackground);
}
