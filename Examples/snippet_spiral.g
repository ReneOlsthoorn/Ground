
string pixelWindowTitle = "Spiral";        // Inspiration: https://github.com/ivan-guerra/plasma
#include pixelwindow.g

float[SCREEN_WIDTH, SCREEN_HEIGHT] DistanceCache = null;
float[SCREEN_WIDTH, SCREEN_HEIGHT] AngleCache = null;
float time = 0.0;

function Init() {
    DistanceCache = msvcrt.calloc(sizeof(float), SCREEN_WIDTH * SCREEN_HEIGHT);
    AngleCache = msvcrt.calloc(sizeof(float), SCREEN_WIDTH * SCREEN_HEIGHT);
    for (y in 0..< SCREEN_HEIGHT) {
        float dy = y - SCREEN_HEIGHT_D2;
        for (x in 0..< SCREEN_WIDTH) {
            float dx = x - SCREEN_WIDTH_D2;
            DistanceCache[x,y] = gc.sqrt(dx*dx + dy*dy) * 0.05;
            AngleCache[x,y] = sdl3.SDL_atan2(dy, dx) * 3.0;
        }
    }

    ptr thread2Handle = GC_CreateThread(Thread2);
    kernel32.SetThreadPriority(thread2Handle, g.kernel32_THREAD_PRIORITY_TIME_CRITICAL);  // Realtime priority gives us the best chance for 60hz screenrefresh.
}

function DeInit() {
    msvcrt.free(DistanceCache);
    msvcrt.free(AngleCache);

    WaitForThread2();

    //string showStr = "Best innerloop time: " + debugBestTicks + "ms";
    //user32.MessageBox(null, showStr, "Message", g.MB_OK);
    //6ms on Ryzen 7 5700G 3.8 Ghz
}

function DrawPortion(int y) {
    u32* pixelPtr = pixels+(y*SCREEN_LINESIZE);

    for (x in 0..< SCREEN_WIDTH) {
        float pixelDistance = DistanceCache[x,y];
        float pixelAngle = AngleCache[x,y];
        int sinValue = (sdl3.SDL_sin(pixelDistance + pixelAngle + time)) * 128.0;

        /*
        int amountPart = sinValue + 128;
        if (amountPart > 255)
            amountPart = 255;
        if (amountPart < 0)
            amountPart = 0;
        pixels[x,y] = 0xff000000 + (amountPart << 16) + (amountPart << 8) + amountPart;
        */
asm {
  push  rdi rdx
  mov   rdi, [pixelPtr@DrawPortion]
  mov   rax, [sinValue@DrawPortion]
  add   rax, 128
  cmp   rax, 255
  jle   .ceiling255
  mov   rax, 255
.ceiling255:
  cmp   rax, 128
  jge   .ceiling0
  mov   rax, 0
.ceiling0:
  mov   edx, eax
  shl   edx, 8
  or    eax, edx
  shl   edx, 8
  or    eax, edx
  or    eax, 0xff000000
  mov   [rdi], eax
  pop   rdx rdi
}
        pixelPtr = pixelPtr + 4;
    }
}

function Thread2() {
	while (StatusRunning) {
		if (thread2Busy) {
            for (y in SCREEN_HEIGHT_D2 ..< SCREEN_HEIGHT)
                DrawPortion(y);
			thread2Busy = false;
		}
	}
}

function Update() {
    time = time + 0.15;
    if (time > MATH_2PI)
        time = time - MATH_2PI;

	thread1Busy = StatusRunning;
	thread2Busy = StatusRunning;

	if (thread1Busy) {
        for (y in 0 ..< SCREEN_HEIGHT_D2)
            DrawPortion(y);
		thread1Busy = false;
	}

    WaitForThread2();
}
