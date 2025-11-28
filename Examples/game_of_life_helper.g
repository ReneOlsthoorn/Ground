

function writeText(ptr renderer, float x, float y, string text) {
	f32 scale = 1.0;
	sdl3.SDL_SetRenderScale(renderer, scale, scale);
	f32 theX = x;
	f32 theY = y;
	sdl3.SDL_SetRenderDrawColor(renderer, 0x00, 0x00, 0x00, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX+2.0, theY, text);
	sdl3.SDL_SetRenderDrawColor(renderer, 0xe0, 0xe0, 0xe0, 0xff);
	sdl3.SDL_RenderDebugText(renderer, theX, theY, text);
}

function FillGridElementPixels(pointer p, u32 color) asm {
  push	rdi
  mov   rdi, [p@FillGridElementPixels]
  mov   rax, [color@FillGridElementPixels]
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_SCREEN_PIXELSIZE
  inc   rcx
  cmp	rcx, GC_GRID_ELEMENT_PIXELS
  jne	.loop
  pop	rdi
}


function FillGridElementBody(pointer p, u32 fgColor, u32 bgColor) asm {
  push	rdi
  mov   rdi, [p@FillGridElementBody]
  mov   rax, [fgColor@FillGridElementBody]
  mov   rdx, [bgColor@FillGridElementBody]
  mov	[rdi], edx
  add	rdi, GC_SCREEN_PIXELSIZE
  mov   rcx, 0
.loop:
  mov   [rdi], eax
  add	rdi, GC_SCREEN_PIXELSIZE
  inc   rcx
  cmp	rcx, GC_GRID_ELEMENT_PIXELS_KERN
  jne	.loop
  mov	[rdi], edx
  pop	rdi
}


function ScreenPointerForXY(int x, int y) : ptr {	
	ptr result = g.[pixels_p] + ((y*SCREEN_WIDTH)+x)*SCREEN_PIXELSIZE;
	return result;
}


function DrawGridElement(int x, int y, byte shape) {
	u32 fgColor = fgColorList[shape];
	u32 bgColor = bgColorList[shape];

	pointer p = &pixels[x * GRID_ELEMENT_PIXELS, y * GRID_ELEMENT_PIXELS + GRID_POSY_OFFSET];
	int offsetToNextLine = SCREEN_WIDTH << 2;

	FillGridElementPixels(p, bgColor);
	p = p + offsetToNextLine;
	for (i in 0..< GRID_ELEMENT_PIXELS_KERN) {
		FillGridElementBody(p, fgColor, bgColor);
		p = p + offsetToNextLine;
	}
	if (y != GRID_ELEMENTS_Y-1)
	   FillGridElementPixels(p, bgColor);
}


function FillHorizontal(int y, int nrLines, u32 color) {
	u32* p = ScreenPointerForXY(0, y);
	for (i in 0..< (SCREEN_WIDTH * nrLines)) { p[i] = color; }
}


function DrawBoard() {
	//FillHorizontal(0, 4, fgColorList[0]);
	for (y in 0 ..< GRID_ELEMENTS_Y) {
		for (x in 0 ..< GRID_ELEMENTS_X) {
			DrawGridElement(x,y, board[x,y]);
		}
	}
	//FillHorizontal(SCREEN_HEIGHT-4, 1, bgColorList[0]);
	//FillHorizontal(SCREEN_HEIGHT-3, 3, fgColorList[0]);
}


function copyLine(ptr dest, string src) {
	ptr src_p = &src;
asm {
  mov	rdx, [src_p@copyLine]
  mov	r8, [dest@copyLine]
.loop:
  mov	al, [rdx]
  test	al, al
  jz	.exitloop
  cmp	al, '.'
  jne	.notempty
  mov	al, 0
  jmp	.setfield
.notempty:
  mov	al, 1
.setfield:
  mov	byte [r8], al
  inc	r8
  inc	rdx
  jmp	.loop
.exitloop:
}
}


function copyLineR(ptr dest, string src) {
	ptr src_p = &src;
asm {
  mov	rdx, [src_p@copyLineR]
  mov	r8, [dest@copyLineR]
.loop:
  mov	al, [rdx]
  test	al, al
  jz	.exitloop
  cmp	al, '.'
  jne	.notempty
  mov	al, 0
  jmp	.setfield
.notempty:
  mov	al, 1
.setfield:
  mov	byte [r8], al
  dec	r8
  inc	rdx
  jmp	.loop
.exitloop:
}
}

