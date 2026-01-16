

#define SCREEN_TEXTCOLUMNS 80
#define SCREEN_TEXTROWS 45
#define SCREEN_TEXTSIZE SCREEN_TEXTCOLUMNS*SCREEN_TEXTROWS
#define FONT_HEIGHT 16
#define FONT_WIDTH_BYTES 2

asm data {
align 8
font32_p  dq 0
font256_p  dq 0
screentext_p  dq 0
screentext_old_p  dq 0
screencolor_p dq 0
screen_cursor dq 0
pixels_screen_p dq 0

ScreenColorPalette:
    dd 0xff000000	; #000000  First 16 colors are C-64 colors.   ;0xffe0e0e0, 0xff808080
	dd 0xfff1f1f1	; #ffffff  white
	dd 0xffac4749	; #993322  red
	dd 0xff78d5d0	; #66ddee  cyan
	dd 0xffac49c1	; #aa3399  purple
	dd 0xff5dc158	; #55bb22  green
	dd 0xff4044cb	; #1133aa  blue   6
	dd 0xffe1e063	; #ffee55  yellow
	dd 0xffaf6821	; #995511  brown
	dd 0xff7E5500	; #663300  dark brown
	dd 0xffd67d7f	; #dd6655  pink  a
	dd 0xff686868	; #444444  dark grey
	dd 0xff8f8f8f	; #777777  grey
	dd 0xffa0eb9c	; #aaff77  light gren
	dd 0xff8898ff	; #5577ff  light blue
	dd 0xffb9b9b9	; #bbbbbb  light grey
}


byte[] font32_p_original = msvcrt.calloc(1, 256 * 32);
byte[] font256_p_original = msvcrt.calloc(1, 256 * 256);
g.[font32_p] = font32_p_original;
g.[font256_p] = font256_p_original;
g.[screentext_p] = msvcrt.calloc(1, SCREEN_TEXTSIZE);
g.[screentext_old_p] = msvcrt.calloc(1, SCREEN_TEXTSIZE);
g.[screencolor_p] = msvcrt.calloc(1, SCREEN_TEXTSIZE);

//When using this include, you must define SCREENFONT256FILEPATH like this:
//#define SCREENFONT256FILEPATH "image/charset16x16.png"
byte[] font256OnDisk = sidelib.LoadImage(SCREENFONT256FILEPATH);
if (font256OnDisk == null) { user32.MessageBox(null, "The font charset16x16.png cannot be found!", "Message", g.MB_OK); return; }
sidelib.ConvertFonts(font256OnDisk, g.[font256_p], g.[font32_p]);
sidelib.FreeImage(font256OnDisk);


function FreeScreenBuffers() {
	msvcrt.free(g.[font256_p]);
	msvcrt.free(g.[font32_p]);
	msvcrt.free(g.[screentext_p]);
	msvcrt.free(g.[screentext_old_p]);
	msvcrt.free(g.[screencolor_p]);
}


asm procedures {
PrintScreenString:
  push	r8 r9 r10 r11 rdx
  mov	r8, rax		; rax = string ptr
  mov	r11, 0		; result string length
  mov	r9, 0	
  mov	r10, [screentext_p]
  add	r10, [screen_cursor]
.loopChar:
  xor	eax, eax
  mov	al, [r8+r9]
  cmp	al, 0
  jz	.end
  cmp	al, 0x0d
  je	.nextChar
  cmp	al, 0x0a
  jne	.notReturn
  mov	rax, [screen_cursor]
  xor	edx, edx
  mov	r11, GC_SCREEN_TEXTCOLUMNS
  div	r11
  mov	r11, GC_SCREEN_TEXTCOLUMNS
  sub	r11, rdx
  jmp	.nextChar
.notReturn:
  mov	[r10+r9], al
  inc	r11
.nextChar:  
  inc	r9
  jmp	.loopChar
.end:
  mov	r8, [screen_cursor]
  add	r8, r11
  mov	[screen_cursor], r8
  pop	rdx r11 r10 r9 r8
  ret

PrintScreenColorString:
  push	r8 r9 r10 r11 r12 r13 r14 rdx
  mov	r13, r8
  mov	r8, rax		; rax = string ptr
  mov	r11, 0		; result string length
  mov	r9, 0	
  mov	r10, [screentext_p]
  add	r10, [screen_cursor]
  mov	r14, [screentext_old_p]
  add	r14, [screen_cursor]
  mov	r12, [screencolor_p]
  add	r12, [screen_cursor]
.loopChar:
  xor	eax, eax
  mov	al, [r8+r9]
  cmp	al, 0
  jz	.end
  cmp	al, 0x0d
  je	.nextChar
  cmp	al, 0x0a
  jne	.notReturn
  mov	rax, [screen_cursor]
  xor	edx, edx
  mov	r11, GC_SCREEN_TEXTCOLUMNS
  div	r11
  mov	r11, GC_SCREEN_TEXTCOLUMNS
  sub	r11, rdx
  jmp	.nextChar
.notReturn:
  mov	[r10+r9], al
  mov	byte [r14+r9], 0
  mov	[r12+r9], r13b
  inc	r11
.nextChar:  
  inc	r9
  jmp	.loopChar
.end:
  mov	r8, [screen_cursor]
  add	r8, r11
  mov	[screen_cursor], r8
  pop	rdx r14 r13 r12 r11 r10 r9 r8
  ret
}


function DrawTextLine(int lineNr) asm {
  push	rsi rdi r8 r9 r10 r11 r12 r13 r14 r15 rcx
  mov	rcx, [lineNr@DrawTextLine]

  mov	rax, rcx
  imul	rax, GC_SCREEN_TEXTCOLUMNS
  mov	rsi, [screentext_p]
  add	rsi, rax
  mov	r13, [screentext_old_p]
  add	r13, rax
  mov	r14, [screencolor_p]
  add	r14, rax

  mov	rax, rcx
  imul	rax, GC_FONT_HEIGHT * GC_SCREEN_LINESIZE
  mov	rdi, [pixels_screen_p]
  add	rdi, rax

  mov	rcx, 0
.column_loop:


  xor	eax, eax
  mov	al, [r14]
  and	al, 0fh
  mov	r15, ScreenColorPalette
  mov	r11d, [r15+rax*4]	; r11d = color of pixel

  xor	eax, eax
  mov	al, [r14]
  and	al, 0f0h
  shr	al, 4
  mov	r12d, [r15+rax*4]	; r12d = color of no-pixel


  mov	r8, [font32_p]

  xor	eax, eax
  mov	al, [rsi]			; rsi = screentext1

  xor	edx, edx
  mov	dl, [r13]			; r13 = screentext1_old

  cmp	al, dl
  je	.next_column
  mov	[r13], al			; store the different character in the screentext1_old

  shl	rax, 5				; each character is 32 bytes
  add	r8, rax

  mov	rdx, rdi

  mov	r9, 0
.char_row_loop:
  mov	r10, 0
  xor	eax, eax
  mov	ax, [r8]			; all bits of the line in ax
.char_loop:
  shl	ax, 1
  jc	.bitSet
  mov	[rdi+r10*4], r12d
  jmp	.next_char_pixel
.bitSet:
  mov	[rdi+r10*4], r11d
.next_char_pixel:
  inc	r10
  cmp	r10, 16
  jne	.char_loop

  add	rdi, GC_SCREEN_LINESIZE
  add	r8, 2
  inc	r9
  cmp	r9, 16
  jne	.char_row_loop

  mov	rdi, rdx

.next_column:
  add	rdi, 16 * 4
  inc	rsi
  inc	r13
  inc	r14
  inc	rcx
  cmp	rcx, GC_SCREEN_TEXTCOLUMNS
  jne	.column_loop

  pop	rcx r15 r14 r13 r12 r11 r10 r9 r8 rdi rsi
}

function ScreenDrawTextLines() {
	for (textY in 0 ..< SCREEN_TEXTROWS)
		DrawTextLine(textY);
}
