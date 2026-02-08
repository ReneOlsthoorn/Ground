
string pixelWindowTitle = "Spiral";     // Inspiration: https://github.com/ivan-guerra/plasma
#include pixelwindow.g

float[SCREEN_WIDTH, SCREEN_HEIGHT] DistanceCache = null;
float[SCREEN_WIDTH, SCREEN_HEIGHT] AngleCache = null;
float time = 0.0;

function Spiral(float dist1, float time1, float angle1) : float {    
    return sdl3.SDL_sin((dist1 / 16.0) + (angle1 * 3.0) + time1);
}

function Init() {
    DistanceCache = msvcrt.calloc(sizeof(float), SCREEN_WIDTH * SCREEN_HEIGHT);
    AngleCache = msvcrt.calloc(sizeof(float), SCREEN_WIDTH * SCREEN_HEIGHT);
    for (y in 0..< SCREEN_HEIGHT) {
        float dy = y - SCREEN_HEIGHT_D2;
        for (x in 0..< SCREEN_WIDTH) {
            float dx = x - SCREEN_WIDTH_D2;
            DistanceCache[x,y] = gc.sqrt(dx*dx + dy*dy);
            AngleCache[x,y] = sdl3.SDL_atan2(dy, dx);
        }
    }
}

function DeInit() {
    msvcrt.free(DistanceCache);
    msvcrt.free(AngleCache);
}

function Update() {
    time = time + 0.15;
    if (time > MATH_2PI)
        time = time - MATH_2PI;

    for (y in 0..< SCREEN_HEIGHT) {
        for (x in 0..< SCREEN_WIDTH) {
            float pixelDistance = DistanceCache[x,y];
            float pixelAngle = AngleCache[x,y];
            float res = Spiral(pixelDistance, time, pixelAngle);
            int pixelColor = 0xff000000;
            if (res > 0.0) {
                int amountPart = ((res * 128.0) + 128.0);
                if (amountPart > 255)
                    amountPart = 255;
                pixelColor = pixelColor + (amountPart << 16) + (amountPart << 8) + amountPart;
            }
            pixels[x,y] = pixelColor;
        }
    }
}
