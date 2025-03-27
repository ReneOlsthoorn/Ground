
dll gdi32 function CreateCompatibleDC(ptr hdc);
dll gdi32 function DeleteDC(ptr hdc);
dll gdi32 function CreateCompatibleBitmap(ptr hdc, int cx, int cy);
dll gdi32 function DeleteObject(ptr obj) : bool;
dll gdi32 function SelectObject(ptr hdc, ptr obj) : ptr;
dll gdi32 function BitBlt(ptr hdc, int x, int y, int cx, int cy, ptr hdcSrc, int x1, int y1, i32 rop) : bool;
dll gdi32 function GetDIBits(ptr hdc, ptr bmp, int start, int cLines, ptr lpvBits, ptr lpbmi, int usage) : int;
dll gdi32 function GetObject(ptr handle, int c, ptr pv) : int;
