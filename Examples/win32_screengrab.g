
#template consoleplus
#include msvcrt.g
#include user32.g
#include gdi32.g

class Bitmap {			//sizeof: 32 bytes
    i32 bmType;
    i32 bmWidth;
    i32 bmHeight;
    i32 bmWidthBytes;
    u16 bmPlanes;
    u16 bmBitsPixel;
    u64 bmBits;
}

class BitmapInfoHeader {	//sizeof: 40 bytes
    u32 biSize;
    i32 biWidth;
    i32 biHeight;
    u16 biPlanes;
    u16 biBitCount;
    u32 biCompression;
    u32 biSizeImage;
    i32 biXPelsPerMeter;
    i32 biYPelsPerMeter;
    u32 biClrUsed;
    u32 biClrImportant;
}

class BitmapFileHeader packed {	//sizeof: 14 bytes
    u16 bfType;
    u32 bfSize;
    u16 bfReserved1;
    u16 bfReserved2;
    u32 bfOffBits;
}


function Screengrab() {
	assert(sizeof(Bitmap) == 32);
	assert(sizeof(BitmapInfoHeader) == 40);
	assert(sizeof(BitmapFileHeader) == 14);

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
