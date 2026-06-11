
#define COLOR_BLANK 0x00000000
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

#define PIXELFORMAT_UNCOMPRESSED_GRAYSCALE     1  // 8 bit per pixel (no alpha)
#define PIXELFORMAT_UNCOMPRESSED_GRAY_ALPHA    2  // 8*2 bpp (2 channels)
#define PIXELFORMAT_UNCOMPRESSED_R5G6B5        3  // 16 bpp
#define PIXELFORMAT_UNCOMPRESSED_R8G8B8        4  // 24 bpp
#define PIXELFORMAT_UNCOMPRESSED_R5G5B5A1      5  // 16 bpp (1 bit alpha)
#define PIXELFORMAT_UNCOMPRESSED_R4G4B4A4      6  // 16 bpp (4 bit alpha)
#define PIXELFORMAT_UNCOMPRESSED_R8G8B8A8      7  // 32 bpp
#define PIXELFORMAT_UNCOMPRESSED_R32           8  // 32 bpp (1 channel - float)
#define PIXELFORMAT_UNCOMPRESSED_R32G32B32     9  // 32*3 bpp (3 channels - float)
#define PIXELFORMAT_UNCOMPRESSED_R32G32B32A32 10  // 32*4 bpp (4 channels - float)
#define PIXELFORMAT_UNCOMPRESSED_R16          11  // 16 bpp (1 channel - half float)
#define PIXELFORMAT_UNCOMPRESSED_R16G16B16    12  // 16*3 bpp (3 channels - half float)
#define PIXELFORMAT_UNCOMPRESSED_R16G16B16A16 13  // 16*4 bpp (4 channels - half float)
#define PIXELFORMAT_COMPRESSED_DXT1_RGB       14  // 4 bpp (no alpha)
#define PIXELFORMAT_COMPRESSED_DXT1_RGBA      15  // 4 bpp (1 bit alpha)
#define PIXELFORMAT_COMPRESSED_DXT3_RGBA      16  // 8 bpp
#define PIXELFORMAT_COMPRESSED_DXT5_RGBA      17  // 8 bpp
#define PIXELFORMAT_COMPRESSED_ETC1_RGB       18  // 4 bpp
#define PIXELFORMAT_COMPRESSED_ETC2_RGB       19  // 4 bpp
#define PIXELFORMAT_COMPRESSED_ETC2_EAC_RGBA  20  // 8 bpp
#define PIXELFORMAT_COMPRESSED_PVRT_RGB       21  // 4 bpp
#define PIXELFORMAT_COMPRESSED_PVRT_RGBA      22  // 4 bpp
#define PIXELFORMAT_COMPRESSED_ASTC_4x4_RGBA  23  // 8 bpp
#define PIXELFORMAT_COMPRESSED_ASTC_8x8_RGBA  24  // 2 bpp


class raylib_Vector2 {
	f32 x;
	f32 y;
}


class raylib_Shader {
    u32 id;         // Shader program id
    int* locs;      // Shader locations array (RL_MAX_SHADER_LOCATIONS)
}


class raylib_Texture2D {
    u32 id;                 // OpenGL texture id
    i32 width;              // Texture base width
    i32 height;             // Texture base height
    i32 mipmaps;            // Mipmap levels, 1 by default
    i32 format;             // Data format (PixelFormat type)
}


class raylib_RenderTexture {
    u32 id;                       // OpenGL framebuffer object id
    u32 texture_id;               // OpenGL texture id
    i32 texture_width;            // Texture base width
    i32 texture_height;           // Texture base height
    i32 texture_mipmaps;          // Mipmap levels, 1 by default
    i32 texture_format;           // Data format (PixelFormat type)
    u32 depth_id;                 // OpenGL texture id
    i32 depth_width;              // Texture base width
    i32 depth_height;             // Texture base height
    i32 depth_mipmaps;            // Mipmap levels, 1 by default
    i32 depth_format;             // Data format (PixelFormat type)
}


class raylib_Color {
    u8 r;        // Color red value
    u8 g;        // Color green value
    u8 b;        // Color blue value
    u8 a;        // Color alpha value
}


class raylib_Image {
    ptr data;               // Image raw data
    i32 width;              // Image base width
    i32 height;             // Image base height
    i32 mipmaps;            // Mipmap levels, 1 by default
    i32 format;             // Data format (PixelFormat type)
}


class raylib_Rectangle {
    f32 x;                // Rectangle top-left corner position x
    f32 y;                // Rectangle top-left corner position y
    f32 width;            // Rectangle width
    f32 height;           // Rectangle height
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

dll raylib function LoadShaderFromMemory(string vsCode, string fsCode) : raylib_Shader;
dll raylib function GetShaderLocation(ptr shader, string uniformName) : int;
dll raylib function SetShaderValue(ptr shader, int locIndex, ptr value, int uniformType);
dll raylib function SetShaderValueV(ptr shader, int locIndex, ptr value, int uniformType, int count);
dll raylib function SetShaderValueTexture(ptr shader, int locIndex, ptr texture);
dll raylib function BeginShaderMode(ptr shader);
dll raylib function EndShaderMode();
dll raylib function DrawRectangle(int posX, int posY, int width, int height, u32 color);
dll raylib function UnloadShader(ptr shader);
dll raylib function IsShaderValid(ptr shader) : bool;

dll raylib function rlGetVersion() : int;
dll raylib function LoadTexture(string fileName) : raylib_Texture2D;
dll raylib function UnloadTexture(ptr texture2d);
dll raylib function DrawTexture(ptr texture2d, int posX, int posY, u32 tint);
dll raylib function DrawTexturePro(ptr texture2d, ptr rectangleSrc, ptr rectangleDest, ptr vectorOrigin, float rotation, u32 tint);
dll raylib function DrawTextureRec(ptr texture2d, ptr rectangleSrc, ptr vectorPosition, u32 tint);
dll raylib function GetMousePosition() : raylib_Vector2;

dll raylib function GetCurrentMonitor() : int;
dll raylib function GetMonitorWidth(int monitor) : int;
dll raylib function GetMonitorHeight(int monitor) : int;
dll raylib function SetConfigFlags(u64 flags);

dll raylib function GetScreenWidth() : int;
dll raylib function GetScreenHeight() : int;

dll raylib function SetWindowState(u64 flags);
dll raylib function SetWindowSize(int width, int height);
dll raylib function IsWindowFullscreen() : bool;

dll raylib function ShowCursor();
dll raylib function HideCursor();
dll raylib function IsCursorHidden() : bool;
dll raylib function IsWindowReady() : bool;

dll raylib function ToggleFullscreen();
dll raylib function UpdateTexture(ptr texture, ptr pixels);
dll raylib function LoadTextureFromImage(ptr image) : raylib_Texture2D;
dll raylib function LoadRenderTexture(int width, int height) : raylib_RenderTexture;

dll raylib function BeginTextureMode(ptr target);
dll raylib function EndTextureMode();
dll raylib function GetRandomValue(i32 min, i32 max) : u32;
dll raylib function ColorFromHSV(f32 hue, f32 saturation, f32 value) : u32;

dll raylib function GetKeyPressed() : u32;
dll raylib function GetCharPressed() : u32;

dll raylib function DrawFPS(int posX, int posY);
dll raylib function ClearWindowState(u32 flags);
