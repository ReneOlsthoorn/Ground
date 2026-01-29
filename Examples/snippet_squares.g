
string pixelWindowTitle = "BBC basic inspired Squares";
#include pixelwindow.g

function Init() {
    for (x in 0..< SCREEN_WIDTH) {
        for (y in 0..< SCREEN_HEIGHT) {
            int b = (x ^ y) & 0xff;
            pixels[x,y] = 0xff000000 + (b << 16) + ((b >> 1) << 8) + (0xff - b);
        }
    }
}
