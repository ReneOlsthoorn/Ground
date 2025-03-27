
#template win32console
#include msvcrt.g
#include user32.g
#include gdi32.g

class Bitmap {
    i32 bmType;       // dd 4
    i32 bmWidth;      // dd 8
    i32 bmHeight;     // dd 12
    i32 bmWidthBytes; // dd 16
    u16 bmPlanes;     // dw 18
    u16 bmBitsPixel;  // dw 20
    u16 _fill1;       // dw 22
    u16 _fill2;       // dw 24
    u64 bmBits;       // dq 32
}

class BitmapInfoHeader {
    u32 biSize;			// dd 4
    i32 biWidth;		// dd 8
    i32 biHeight;		// dd 12
    u16 biPlanes;		// dw 14
    u16 biBitCount;		// dw 16
    u32 biCompression;	// dd 20
    u32 biSizeImage;	// dd 24
    i32 biXPelsPerMeter; //dd 28
    i32 biYPelsPerMeter; //dd 32
    u32 biClrUsed;		// dd 36
    u32 biClrImportant;	// dd 40
}

class BitmapFileHeader {
    u16 bfType;			// dw 2
    u32 bfSize;			// dd 6
    u16 bfReserved1;    // dw 8
    u16 bfReserved2;    // dw 10
    u32 bfOffBits;      // dd 14
}


function Screengrab() {
	ptr screenDC = user32.GetDC(NULL);             // Get the Device Contect for the entire screen.
	msvcrt.printf("screenDC: %p \r\n", screenDC);

	ptr memoryDC = gdi32.CreateCompatibleDC(screenDC);
	msvcrt.printf("memoryDC: %p \r\n", memoryDC);

    int width = user32.GetSystemMetrics(g.SM_CXSCREEN);
    int height = user32.GetSystemMetrics(g.SM_CYSCREEN);
	println("Width: " + width);
	println("Height: " + height);

    ptr hBitmap = gdi32.CreateCompatibleBitmap(screenDC, width, height);
	msvcrt.printf("hBitmap: %p \r\n", hBitmap);

    gdi32.SelectObject(memoryDC, hBitmap);
    gdi32.BitBlt(memoryDC, 0, 0, width, height, screenDC, 0, 0, g.SRCCOPY);

    Bitmap bmp;
	zero(bmp);
    gdi32.GetObject(hBitmap, sizeof(Bitmap), bmp);
	println("Bitmap bmWidth:" + bmp.bmWidth);

	int bmpSize = width*height*4;
	byte[] bmpData = msvcrt.calloc(1, bmpSize);

	BitmapInfoHeader bi;
	zero(bi);
	bi.biSize = sizeof(BitmapInfoHeader);
	bi.biWidth = bmp.bmWidth;
	bi.biHeight = -bmp.bmHeight;   // Negative to flip the bitmap vertically.
	bi.biPlanes = 1;
	bi.biBitCount = 32;
	bi.biCompression = g.BI_RGB;

	//println("bi.biHeight: " + bi.biHeight);
	msvcrt.printf("bi.biHeight: %i \r\n", bi.biHeight);

	int DIB_RGB_COLORS = 0;
	gdi32.GetDIBits(memoryDC, hBitmap, 0, bmp.bmHeight, bmpData, bi, DIB_RGB_COLORS);
	
	BitmapFileHeader bfh;
	zero(bfh);
	bfh.bfType = 0x4D42;  // 'BM'
	bfh.bfSize = sizeof(BitmapFileHeader) + sizeof(BitmapInfoHeader) + bmpSize;
	bfh.bfOffBits = sizeof(BitmapFileHeader) + sizeof(BitmapInfoHeader);
	
	string bmpFilename = "screengrab.bmp";
	int tmpFile = msvcrt.fopen(bmpFilename, "wb");
	msvcrt.fwrite(bfh, sizeof(BitmapFileHeader), 1, tmpFile);
	msvcrt.fwrite(bi, sizeof(BitmapInfoHeader), 1, tmpFile);
	msvcrt.fwrite(bmpData, bmpSize, 1, tmpFile);
	msvcrt.fclose(tmpFile);
	
	msvcrt.free(bmpData);
    
    gdi32.DeleteObject(hBitmap);
	gdi32.DeleteDC(memoryDC);
	user32.ReleaseDC(NULL, screenDC);

	println("klaar!");
}

Screengrab();
