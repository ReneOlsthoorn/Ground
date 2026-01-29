
string pixelWindowTitle = "BBC basic inspired Fern";
#include pixelwindow.g

function Init() {
    float A;
    float B;
    float C;
    float D;
    float E;
    float F;
    float fx = 0.0;
    float fy = 0.0;

    for (i in 1 .. 150000) {
        float r = sdl3.SDL_randf();
        if (r < 0.1) { A=0.0; B=0.0; C=0.0; D=0.16; E=0.0; F=0.0; }
        else if (r > 0.1 and r <= 0.86) { A=0.85; B=0.04; C=-0.04; D=0.85; E=0.0; F=1.6; }
        else if (r > 0.86 and r <= 0.93) { A=0.2; B=-0.26; C=0.23; D=0.22; E=0.0; F=1.6; }
        else if (r > 0.93) { A=-0.15; B=0.28; C=0.26; D=0.24; E=0.0; F=0.44; }

        float newx = (A*fx) + (B*fy) + E;
        float newy = (C*fx) + (D*fy) + F;
        fx = newx;
        fy = newy;
        pixels[600 + (96*fx), 680 - (65*fy)] = 0xff00cc00;
    }
}
