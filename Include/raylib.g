
#define COLOR_WHITE 0xffffffff
#define COLOR_RAYWHITE 0xfff5f5f5
#define COLOR_LIGHTGRAY 0xffc8c8c8
#define SHADER_UNIFORM_FLOAT 0
#define SHADER_UNIFORM_VEC2 1
#define SHADER_UNIFORM_VEC3 2
#define SHADER_UNIFORM_VEC4 3
#define SHADER_UNIFORM_INT 4
#define SHADER_UNIFORM_IVEC2 5
#define SHADER_UNIFORM_IVEC3 6
#define SHADER_UNIFORM_IVEC4 7
#define SHADER_UNIFORM_SAMPLER2D 8


class Vector2 {
	f32 x;
	f32 y;
}


class Shader {
    u32 id;         // Shader program id
    int* locs;      // Shader locations array (RL_MAX_SHADER_LOCATIONS)
}


class Texture2D {
    u32 id;                 // OpenGL texture id
    i32 width;              // Texture base width
    i32 height;             // Texture base height
    i32 mipmaps;            // Mipmap levels, 1 by default
    i32 format;             // Data format (PixelFormat type)
}


dll raylib function InitWindow(int width, int height, string title);
dll raylib function CloseWindow();
dll raylib function WindowShouldClose() : boolean;
dll raylib function BeginDrawing();
dll raylib function EndDrawing();
dll raylib function ClearBackground(u32 color);
dll raylib function DrawText(string text, int posX, int posY, int fontSize, u32 color);
dll raylib function DrawCircleV(u64 center, f32 radius, u32 color);

// Timing-related functions
dll raylib function SetTargetFPS(int fps);  // Set target FPS (maximum)
dll raylib function GetFrameTime() : f32;   // Get time in seconds for last frame drawn (delta time)
dll raylib function GetTime() : float;      // Get elapsed time in seconds since InitWindow()
dll raylib function GetFPS() : int;         // Get current FPS

dll raylib function LoadShaderFromMemory(string vsCode, string fsCode) : Shader;  // result = ptr to Shader
dll raylib function GetShaderLocation(ptr shader, string uniformName) : int;
dll raylib function SetShaderValue(ptr shader, int locIndex, ptr value, int uniformType);
dll raylib function BeginShaderMode(ptr shader);
dll raylib function EndShaderMode();
dll raylib function DrawRectangle(int posX, int posY, int width, int height, u32 color);
dll raylib function UnloadShader(ptr shader);
dll raylib function IsShaderValid(ptr shader) : bool;

dll raylib function rlGetVersion() : int;
dll raylib function LoadTexture(string fileName) : Texture2D;
dll raylib function UnloadTexture(ptr texture);
dll raylib function DrawTexture(ptr texture, int posX, int posY, u32 tint);  

