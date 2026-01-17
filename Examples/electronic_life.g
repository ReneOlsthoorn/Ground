
#template sdl3

#include graphics_defines1280x720.g
#include msvcrt.g
#include kernel32.g
#library user32 user32.dll
#library sdl3 sdl3.dll
#library sidelib GroundSideLibrary.dll
#library mikmod libmikmod-3.dll
#library glm libcglm-0.dll
#library chipmunk libchipmunk.dll


u32[SCREEN_WIDTH, SCREEN_HEIGHT] pixels = null;
bool StatusRunning = true;
int frameCount = 0;
byte[SDL3_EVENT_SIZE] event = [];
u32* eventType = &event[SDL3_EVENT_TYPE_OFFSET];
u32* eventScancode = &event[SDL3_EVENT_SCANCODE_OFFSET];
int screenpitch = SCREEN_LINESIZE;
int scrollTextNeedle = 0;
int waterEffectOffset = 0;
float smileyYRadians = 0.0;
float smileyXRadians = 0.0;
#define ANALYZER_NUM 23
int[ANALYZER_NUM] analyzerLevels = [ ] asm;	// 0 - 108

string scrollText = `Electronic life is back!        The previous version was created in 1990, that is 36 years ago!        That version was created on the Amiga computer. Developed with an Amiga 500.        \
The logo on the top is the unaltered original from the Amiga, so pressing left mousebutton will not do anything now.        \
The demo didn't use a physics engine back then.        Perhaps the 68000 CPU was strong enough to do the calculations, but there was no opensource community offering those kind of libraries.        \
Calculating physics is also not easy. In those times 3D was just taking off.        Transparency was also hard back then. Now it is easy in SDL3.        \
In this version, the textscreen drawing is pretty fast asm code. The CPU has no problem drawing the entire screen. But I did it the right way: only the used lines in the spectrum analyzer are drawn.        \
Notice that the top logo will evolve in time. The logo will be painted life, like in the original version. So stay tuned, because that will be added.                `;


/*   TMP VARIABLES   */
CpVect cpv = CpVect(0.0, 0.0);
int RandomSeed = 123123;
sdl3.SDL_srand(RandomSeed);
int loopStartTicks = 0;
int debugBestTicks = 0xffff;
int	ballToShootIndex = 0;


ptr processHandle = kernel32.GetCurrentProcess();
int oldPriorityClass = kernel32.GetPriorityClass(processHandle);
kernel32.SetPriorityClass(processHandle, 0x80); //HIGH_PRIORITY_CLASS
ptr thread1Handle = kernel32.GetCurrentThread();
int oldThread1Prio = kernel32.GetThreadPriority(thread1Handle);
kernel32.SetThreadPriority(thread1Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.

sdl3.SDL_Init(g.SDL_INIT_VIDEO);
ptr window = sdl3.SDL_CreateWindow("Electronic Life 2026", SCREEN_WIDTH, SCREEN_HEIGHT, 0);
ptr renderer = sdl3.SDL_CreateRenderer(window, "direct3d");
ptr texture = sdl3.SDL_CreateTexture(renderer, g.SDL_PIXELFORMAT_ARGB8888, g.SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH, SCREEN_HEIGHT);
sdl3.SDL_SetTextureScaleMode(texture, g.SDL_SCALEMODE_NEAREST);
sdl3.SDL_SetRenderVSync(renderer, 1);
sdl3.SDL_HideCursor();
sdl3.SDL_SetRenderDrawColor(renderer, 0xff, 0xff, 0xff, 0xff);
sdl3.SDL_SetRenderScale(renderer, 1.0, 1.0);


#include electronic_life_images.g

#define SCREENFONT256FILEPATH "image/charset_protracker_16x16.png"
#include screen.g

#include electronic_life_3d.g


/*   COPY THE BACKGROUND TO THE PIXEL TEXTURE   */
sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
g.[pixels_p] = pixels;
gc.copy(elBackground, g.[pixels_p], SCREEN_LINESIZE*SCREEN_HEIGHT);
sdl3.SDL_UnlockTexture(texture);


/*   SOUND RELATED   */
string soundFile = "sound/mod/bbc never look back.mod";
#include soundtracker.g
SoundtrackerInit(soundFile, 127); //127

#include protracker.g
ProtrackerMod ptMod;
ptMod.Load(soundFile);
ptMod.StartPlay();

string[] NoteMapping = [ "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" ];
string GetNoteResult;
function GetNoteInfo(int note, int sample, int effect) {
	if (note == 0 and sample == 0 and effect == 0) {
		GetNoteResult = "--- 0000"; //"        ";
		return;
	}
	if (note != 0) {
		note = note - 1;
		int octaaf = note / 12;
		int noteWithin = note % 12;
		GetNoteResult = NoteMapping[noteWithin] + (octaaf+1) + " ";
	} else {
		GetNoteResult = "--- ";
	}
	if (sample != 0 or effect != 0) {
		GetNoteResult = GetNoteResult + gc.hex$(sample,1) + gc.hex$(effect,3);
	} else
		GetNoteResult = "0000";
}

function PrintMusicInfo() {
	gc.fill(g.[screentext_p]+((SCREEN_TEXTROWS-10)*SCREEN_TEXTCOLUMNS), 10*SCREEN_TEXTCOLUMNS, ' ');
	int currentPatternNr = ptMod.ActivePatternNr();

	g.[screen_cursor] = SCREEN_TEXTCOLUMNS*35;
	for (i in 0..8) {
		int thisRow = ptMod.activeRowNr + i;
		if (thisRow < 0 or thisRow > 63) {
			g.[screen_cursor] = g.[screen_cursor] + SCREEN_TEXTCOLUMNS;
			continue;
		}
		u32* aRow = ptMod.patternData + (currentPatternNr * 256 * PROTRACKER_NUMCHANNELS) + (thisRow * 4 * PROTRACKER_NUMCHANNELS);
		// u32 channelValue = gc.bswap32(*(aRow+4));  // gc.hex$(channelValue, 8)

		for (v in 0..3) {
			int note = ptMod.GetNote(aRow[v]);
			int sample = ptMod.GetSample(aRow[v]);
			int effect = ptMod.GetEffect(aRow[v]);
			GetNoteInfo(note, sample, effect);

			if (v == 0)
				g.[screen_cursor] = g.[screen_cursor] + 4;
			if (v == 1)
				g.[screen_cursor] = g.[screen_cursor] + 1;
			if (v == 2)
				g.[screen_cursor] = g.[screen_cursor] + 38;
			if (v == 3)
				g.[screen_cursor] = g.[screen_cursor] + 1;
			print(GetNoteResult);
		}
		print("\n");
	}
}

function AddAnalyzerLevelForNote(int note) {
	if (note == 0)
		return;

	note = note - 1;
	int levelNr = (note * ((23 << 10) / 36)) >> 10;

	if (levelNr < 0 or levelNr > 22)
		return;

	analyzerLevels[levelNr] = analyzerLevels[levelNr] + 54;
	if (analyzerLevels[levelNr] > 108)
		analyzerLevels[levelNr] = 108;

	if (levelNr > 0) {
		analyzerLevels[levelNr-1] = analyzerLevels[levelNr-1] + 25;
		if (analyzerLevels[levelNr-1] > 108)
			analyzerLevels[levelNr-1] = 108;
	}
	if (levelNr < 22) {
		analyzerLevels[levelNr+1] = analyzerLevels[levelNr+1] + 25;
		if (analyzerLevels[levelNr+1] > 108)
			analyzerLevels[levelNr+1] = 108;
	}
}


/*   SET FONT COLORS FOR TEXTSCREEN   */
u32* screenColorPalette = g.ScreenColorPalette;
screenColorPalette[6] = 0xff3344ff;
gc.fill(g.[screentext_p], SCREEN_TEXTSIZE, ' ');
gc.fill(g.[screentext_old_p], SCREEN_TEXTSIZE, ' ');
gc.fill(g.[screencolor_p], SCREEN_TEXTSIZE, 0x00);
gc.rectfill(g.[screencolor_p]+4, 17, 45, SCREEN_TEXTCOLUMNS, 0x06);
gc.rectfill(g.[screencolor_p]+59, 17, 45, SCREEN_TEXTCOLUMNS, 0x06);


/*   CHIPMUNK   */
ptr space = chipmunk.cpSpaceNew();
chipmunk.cpSpaceSetGravity(space, CpVect(0.0, -300.0));

ptr staticShape1 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(800.0, 540.0), CpVect(1400.0, 600.0), 4);
chipmunk.cpShapeSetFriction(staticShape1, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape1);
chipmunk.cpShapeSetElasticity(staticShape1, 0.09);

ptr staticShape2 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(600.0, 570.0), CpVect(600.0, 290.0), 16);
chipmunk.cpShapeSetFriction(staticShape2, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape2);
chipmunk.cpShapeSetElasticity(staticShape2, 0.9);

ptr staticShape3 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(600.0, 400.0), CpVect(1000.0, 400.0), 4);
chipmunk.cpShapeSetFriction(staticShape3, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape3);
chipmunk.cpShapeSetElasticity(staticShape3, 0.8);

ptr staticShape4 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(1200.0, 300.0), CpVect(1200.0, 400.0), 4);
chipmunk.cpShapeSetFriction(staticShape4, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape4);
chipmunk.cpShapeSetElasticity(staticShape4, 0.9);

ptr staticShape5 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(480.0, 185.0), CpVect(2000.0, 185.0), 4);
chipmunk.cpShapeSetFriction(staticShape5, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape5);
chipmunk.cpShapeSetElasticity(staticShape5, 0.70);

ptr staticShape6 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(470.0, 480.0), CpVect(470.0, 175.0), 16);
chipmunk.cpShapeSetFriction(staticShape6, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape6);
chipmunk.cpShapeSetElasticity(staticShape6, 0.9);

ptr staticShape7 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(600.0, 500.0), CpVect(480.0, 620.0), 4);
chipmunk.cpShapeSetFriction(staticShape7, 0.0);
chipmunk.cpSpaceAddShape(space, staticShape7);
chipmunk.cpShapeSetElasticity(staticShape7, 0.9);

ptr staticShape8 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(300.0, 570.0), CpVect(600.0, 570.0), 4);
chipmunk.cpShapeSetFriction(staticShape8, 0.9);
chipmunk.cpSpaceAddShape(space, staticShape8);
chipmunk.cpShapeSetElasticity(staticShape8, 0.2);

ptr staticShape9 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(-1000.0, 185.0), CpVect(480.0, 185.0), 4);
chipmunk.cpShapeSetFriction(staticShape9, 0.9);
chipmunk.cpSpaceAddShape(space, staticShape9);
chipmunk.cpShapeSetElasticity(staticShape9, 0.2);

ptr staticShape10 = chipmunk.cpSegmentShapeNew(chipmunk.cpSpaceGetStaticBody(space), CpVect(300.0, 570.0), CpVect(300.0, 1200.0), 4);
chipmunk.cpShapeSetFriction(staticShape10, 0.9);
chipmunk.cpSpaceAddShape(space, staticShape10);
chipmunk.cpShapeSetElasticity(staticShape10, 0.2);


/*   ADD FONT BALLS TO CHIPMUNK SPACE   */
#define NR_BALLS 70
ptr[NR_BALLS] ballBodies = [];
ptr[NR_BALLS] ballShapes = [];

float ballRadius = 17.0;
float ballMass = 1.0;
float ballMoment = chipmunk.cpMomentForCircle(ballMass, 0.0, ballRadius, cpvzero);

cpv.x = -20.0;
for (b in 0 ..< NR_BALLS) {
	ballBodies[b] = chipmunk.cpSpaceAddBody(space, chipmunk.cpBodyNew(ballMass, ballMoment));
	cpv.x = cpv.x - 64;
	cpv.y = 450.0;
	chipmunk.cpBodySetPosition(ballBodies[b], cpv);
	ballShapes[b] = chipmunk.cpSpaceAddShape(space, chipmunk.cpCircleShapeNew(ballBodies[b], ballRadius, cpvzero));
	chipmunk.cpShapeSetFriction(ballShapes[b], 1);
	chipmunk.cpShapeSetElasticity(ballShapes[b], 1);
	chipmunk.cpBodySetUserData(ballBodies[b], 'a');
	chipmunk.cpSpaceRemoveShape(space, ballShapes[b]);
}
float timeStep = 1.0 / 60.0;
CpVect cpvectPos;
CpVect cpvectVel;

function ShouldBallBeHidden(int ballIndex) : bool {
	chipmunk.cpBodyGetPosition(cpvectPos, ballBodies[ballIndex]);
	return (cpvectPos.x < -20.0 or cpvectPos.x > 1300.0 or cpvectPos.y < -20.0 or cpvectPos.y > 740.0);
}
function RemoveAllBallShapes() {
	for (b in 0 ..< NR_BALLS) {
		if (chipmunk.cpShapeGetSpace(ballShapes[b]) == null)
			continue;
		chipmunk.cpSpaceRemoveShape(space, ballShapes[b]);
	}
}


/*   ADD BALLS FOR 3D OBJECT   */
float cubePointRadius = 16.0;
cpv.x = 150.0;
cpv.y = 350.0;
for (b in 0..< CUBE_SIZE)
{
	cubePointBodies[b] = chipmunk.cpSpaceAddBody(space, chipmunk.cpBodyNewKinematic());
	chipmunk.cpBodySetPosition(cubePointBodies[b], cpv);
	cubePointShapes[b] = chipmunk.cpSpaceAddShape(space, chipmunk.cpCircleShapeNew(cubePointBodies[b], cubePointRadius, cpvzero));
	chipmunk.cpShapeSetFriction(cubePointShapes[b], 1);
	chipmunk.cpShapeSetElasticity(cubePointShapes[b], 1);
}


function GetNewScrollLetter() : int {
	u8 c = scrollText[scrollTextNeedle];
	scrollTextNeedle++;
	if (scrollText[scrollTextNeedle] == 0)
		scrollTextNeedle = 0;
	return c;
}



/*   MAINLOOP   */
while (StatusRunning)
{
	while (sdl3.SDL_PollEvent(&event[SDL3_EVENT_TYPE_OFFSET])) {
		if (*eventType == g.SDL_EVENT_QUIT)
			StatusRunning = false;

		if (*eventType == g.SDL_EVENT_KEY_DOWN) {
			if (*eventScancode == g.SDL_SCANCODE_ESCAPE)
				StatusRunning = false;
		}
	}

	loopStartTicks = sdl3.SDL_GetTicks();


	/*   PLAY MUSIC AND RUN OUR MIMIC POSITION SYSTEM   */ 
	SoundtrackerUpdate();
	ptMod.Activate();


	/*   DRAW THE MUSIC NOTES. (WE ONLY DRAW THE VISIBLE AREA)   */
	sdl3.SDL_LockTexture(texture, null, &pixels, &screenpitch);
	g.[pixels_p] = pixels;
	g.[pixels_screen_p] = pixels+(SCREEN_LINESIZE * 4);		// offset
	PrintMusicInfo();
	for (textY in (SCREEN_TEXTROWS-10) ..< (SCREEN_TEXTROWS-1))
		DrawTextLine(textY);
	sdl3.SDL_UnlockTexture(texture);
	sdl3.SDL_RenderTexture(renderer, texture, null, null);


	/*   ADD NEW NOTES TO THE ANALYZER   */
	if (ptMod.isNowActive) {
		AddAnalyzerLevelForNote(ptMod.voice1Note);
		AddAnalyzerLevelForNote(ptMod.voice2Note);
		AddAnalyzerLevelForNote(ptMod.voice3Note);
		AddAnalyzerLevelForNote(ptMod.voice4Note);
	}

	/*   DRAW THE ANALYZER LEVELS   */
	for (i in 0 ..< ANALYZER_NUM) {
		if (analyzerLevels[i] == 0)
			continue;

		int analyzerPos = 108 - analyzerLevels[i];

		levelSrcRect[0] = 0;
		levelSrcRect[1] = analyzerPos;
		levelSrcRect[3] = analyzerLevels[i];

		levelDestRect[0] = 367+(i*24);
		levelDestRect[1] = 600 + analyzerPos;
		levelDestRect[3] = analyzerLevels[i];
		sdl3.SDL_RenderTexture(renderer, levelTexture, &levelSrcRect, &levelDestRect);

		analyzerLevels[i] = analyzerLevels[i] - 2;
	}


	// sdl3.SDL_RenderLine(renderer, 800.0,  SCREEN_HEIGHT_F - 540.0, 1400.0, SCREEN_HEIGHT_F - 600.0);


	RenderCube();


	/*  PUSH A NEW FONT BALL INTO EXISTENCE   */
    if (frameCount % 10 == 0) {
		ballToShootIndex++;
		if (ballToShootIndex == NR_BALLS)
			ballToShootIndex = 0;
			
		int usableCounter = 0;
		while (!ShouldBallBeHidden(ballToShootIndex)) {
			ballToShootIndex++;
			if (ballToShootIndex == NR_BALLS)
				ballToShootIndex = 0;
			usableCounter++;
			if (usableCounter == NR_BALLS)
				break;
		}

		if (usableCounter != NR_BALLS) {
			byte newLetter = GetNewScrollLetter();

			if (newLetter == '<') {
				RemoveAllBallShapes();
				newLetter = GetNewScrollLetter();
			}

			if (newLetter != ' ') {
				if (chipmunk.cpShapeGetSpace(ballShapes[ballToShootIndex]) == null) {
					chipmunk.cpSpaceAddShape(space, ballShapes[ballToShootIndex]);
				}
				chipmunk.cpBodySetUserData(ballBodies[ballToShootIndex], newLetter);
				chipmunk.cpBodySetAngularVelocity(ballBodies[ballToShootIndex], 0.0);
				chipmunk.cpBodySetAngle(ballBodies[ballToShootIndex], 0.0);

				cpv.x = 1280.0;
				cpv.y = 600.0;
				chipmunk.cpBodySetPosition(ballBodies[ballToShootIndex], cpv);

				cpv.x = -250;
				cpv.y = 0.0;
				chipmunk.cpBodySetVelocity(ballBodies[ballToShootIndex], cpv);
			}
		} else {
			RemoveAllBallShapes();
		}
    }


	/*   CHECK FOR FONT BALL REMOVAL AND GIVE IMPULSE   */
	for (b in 0 ..< NR_BALLS)
	{
		ptr theSpace = chipmunk.cpShapeGetSpace(ballShapes[b]);
		if (theSpace == null)
			continue;
		if (ShouldBallBeHidden(b)) {
			chipmunk.cpSpaceRemoveShape(space, ballShapes[b]);
			continue;
		}

		chipmunk.cpBodyGetPosition(cpvectPos, ballBodies[b]);
		cpv.x = 50.0;	// 60.0
		cpv.y = 100.0;	// 120.0
		if ((cpvectPos.x < 550.0 and cpvectPos.x > 530.0) and cpvectPos.y < 250.0) {
			chipmunk.cpBodyApplyImpulseAtLocalPoint(ballBodies[b], cpv, cpvzero);
		}
	}


	/*   EVALUATE ALL CHIPMUNK OBJECTS. AFTER THIS, THE NEW POSITIONS ARE USABLE.   */
	chipmunk.cpSpaceStep(space, timeStep);


	/*   DRAW SMILEY   */
	smileyDestRect[0] = 800 - (sdl3.SDL_sin(smileyXRadians) * 80);
	smileyDestRect[1] = 515 - (sdl3.SDL_sin(smileyYRadians) * 160);
	smileyYRadians = smileyYRadians + 0.04;
	if (smileyYRadians > MATH_PI)
		smileyYRadians = smileyYRadians - MATH_PI;
	smileyXRadians = smileyXRadians + 0.03;
	if (smileyXRadians > MATH_2PI)
		smileyXRadians = smileyXRadians - MATH_2PI;
	sdl3.SDL_RenderTexture(renderer, smileyTexture, null, &smileyDestRect);


	/*   DRAW FONT BALLS ON SCREEN   */
	for (b in 0 ..< NR_BALLS)
	{
		if (chipmunk.cpShapeGetSpace(ballShapes[b]) == null)
			continue;

		ptr ballBody = ballBodies[b];
		chipmunk.cpBodyGetPosition(cpvectPos, ballBody);
		chipmunk.cpBodyGetVelocity(cpvectVel, ballBody);
		float angle = chipmunk.cpBodyGetAngle(ballBody);

		fontDestRect[0] = cpvectPos.x;
		fontDestRect[1] = SCREEN_HEIGHT - cpvectPos.y;

		float theAngle = angle * (180.0 / MATH_PI);
		byte theChar = chipmunk.cpBodyGetUserData(ballBody);

		fontSrcRect[0] = fontXOffsets[theChar];
		fontSrcRect[1] = fontYOffsets[theChar];
		sdl3.SDL_RenderTextureRotated(renderer, ballFontTexture, &fontSrcRect, &fontDestRect, -theAngle, null, g.SDL_FLIP_NONE);
	}


	/*   DRAW ROTATING 3D OBJECT   */
	for (b in (CUBE_SIZE-1)..0)
	{
		ptr cubePointBody = cubePointBodies[b];
		chipmunk.cpBodyGetPosition(cpvectPos, cubePointBody);
		ballDestRect[0] = cpvectPos.x;
		ballDestRect[1] = SCREEN_HEIGHT - cpvectPos.y;
		sdl3.SDL_RenderTextureRotated(renderer, ballTexture, &ballSrcRect, &ballDestRect, 0.0, null, g.SDL_FLIP_NONE);
	}


	/*   DRAW THE MOVING WATER   */
	waterSrcRect[0] = waterEffectOffset;
	sdl3.SDL_RenderTexture(renderer, waterTexture, &waterSrcRect, &waterDestRect);
	waterEffectOffset = waterEffectOffset + 2;
	if (waterEffectOffset == 504)
		waterEffectOffset = 0;


	int currentTicks = sdl3.SDL_GetTicks() - loopStartTicks;
	if (currentTicks < debugBestTicks && currentTicks != 0)
		debugBestTicks = currentTicks;

	sdl3.SDL_RenderPresent(renderer);
	frameCount++;
}

sdl3.SDL_ShowCursor();
chipmunk.cpSpaceFree(space);
DestroyTextures();
sdl3.SDL_DestroyRenderer(renderer);
sdl3.SDL_DestroyWindow(window);
sdl3.SDL_Quit();
FreeScreenBuffers();
ptMod.Free();
SoundtrackerFree();

kernel32.SetThreadPriority(thread1Handle, oldThread1Prio);  // Priority of the thread back to the old value.
kernel32.SetPriorityClass(processHandle, oldPriorityClass);

//string showStr = "Best innerloop time: " + debugBestTicks + "ms";
//user32.MessageBox(null, showStr, "Message", g.MB_OK);

