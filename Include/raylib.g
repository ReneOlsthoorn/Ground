
#define COLOR_BLACK 0xff000000
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

#define CONFIG_FLAG_VSYNC_HINT          0x00000040    // Set to try enabling V-Sync on GPU
#define CONFIG_FLAG_FULLSCREEN_MODE     0x00000002    // Set to run program in fullscreen
#define CONFIG_FLAG_WINDOW_RESIZABLE    0x00000004    // Set to allow resizable window
#define CONFIG_FLAG_WINDOW_UNDECORATED  0x00000008    // Set to disable window decoration (frame and buttons)
#define CONFIG_FLAG_WINDOW_HIDDEN       0x00000080    // Set to hide window
#define CONFIG_FLAG_WINDOW_MINIMIZED    0x00000200    // Set to minimize window (iconify)
#define CONFIG_FLAG_WINDOW_MAXIMIZED    0x00000400    // Set to maximize window (expanded to monitor)
#define CONFIG_FLAG_WINDOW_UNFOCUSED    0x00000800    // Set to window non focused
#define CONFIG_FLAG_WINDOW_TOPMOST      0x00001000    // Set to window always on top
#define CONFIG_FLAG_WINDOW_ALWAYS_RUN   0x00000100    // Set to allow windows running while minimized
#define CONFIG_FLAG_WINDOW_TRANSPARENT  0x00000010    // Set to allow transparent framebuffer
#define CONFIG_FLAG_WINDOW_HIGHDPI      0x00002000    // Set to support HighDPI
#define CONFIG_FLAG_WINDOW_MOUSE_PASSTHROUGH 0x00004000  // Set to support mouse passthrough, only supported when FLAG_WINDOW_UNDECORATED
#define CONFIG_FLAG_BORDERLESS_WINDOWED_MODE 0x00008000  // Set to run program in borderless windowed mode
#define CONFIG_FLAG_MSAA_4X_HINT        0x00000020    // Set to try enabling MSAA 4X
#define CONFIG_FLAG_INTERLACED_HINT     0x00010000    // Set to try enabling interlaced video format (for V3D)


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

dll raylib function LoadShaderFromMemory(string vsCode, string fsCode) : Shader;
dll raylib function GetShaderLocation(ptr shader, string uniformName) : int;
dll raylib function SetShaderValue(ptr shader, int locIndex, ptr value, int uniformType);
dll raylib function SetShaderValueTexture(ptr shader, int locIndex, ptr texture);
dll raylib function BeginShaderMode(ptr shader);
dll raylib function EndShaderMode();
dll raylib function DrawRectangle(int posX, int posY, int width, int height, u32 color);
dll raylib function UnloadShader(ptr shader);
dll raylib function IsShaderValid(ptr shader) : bool;

dll raylib function rlGetVersion() : int;
dll raylib function LoadTexture(string fileName) : Texture2D;
dll raylib function UnloadTexture(ptr texture);
dll raylib function DrawTexture(ptr texture, int posX, int posY, u32 tint);
dll raylib function DrawTexturePro(ptr texture, ptr rectangleSrc, ptr rectangleDest, ptr vectorOrigin, float rotation, u32 tint);
dll raylib function GetMousePosition() : Vector2;

dll raylib function GetCurrentMonitor() : int;
dll raylib function GetMonitorWidth(int monitor) : int;
dll raylib function GetMonitorHeight(int monitor) : int;
dll raylib function SetConfigFlags(u64 flags);

dll raylib function GetScreenWidth() : int;
dll raylib function GetScreenHeight() : int;

dll raylib function SetWindowState(u64 flags);

dll raylib function ShowCursor();
dll raylib function HideCursor();
dll raylib function IsCursorHidden() : bool;
dll raylib function IsWindowReady() : bool;

