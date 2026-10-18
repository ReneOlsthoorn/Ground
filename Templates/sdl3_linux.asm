
global main

%include 'Include/sdl3_nasm.inc'
%include 'Templates/part_equates.asm'
gc_linux equ 1
gc_windows equ 0

; *** GENERATED EQUATES CODE ***
;GC_INSERTIONPOINT_EQUATES

%include 'Include/sdl3_extern.inc'
%include 'Include/sdl3_image_extern.inc'
%include 'Include/sdl3_mixer_extern.inc'
%include 'Include/clib_extern.inc'

section .text
default rel
main:
  push	rbp
  mov	rbp, rsp
  mov   [main_rbp], rbp
   
  mov   rax, 89                 ; SYS_readlink
  mov   rdi, cwd_path           ; "/proc/self/cwd"
  mov   rsi, currentExeDirChars           ; buffer
  mov   rdx, 256                ; size
  syscall                       ; returns length in rax  

; *** GENERATED MAIN CODE ***
;GC_INSERTIONPOINT_MAIN
; *** END MAIN CODE ***

assert_exitpoint:
  mov   rsp, rbp
  xor   rdi, rdi                ; exit code 0
  mov   rax, 60                 ; sys_exit
  syscall
  pop   rbp
  ret


; *** GENERATED PROCEDURES (GROUND FUNCTIONS AND CLASSES) ***
;GC_INSERTIONPOINT_PROCEDURES
; *** END PROCEDURES ***


%include 'Templates/part_string_linux.asm'
%include 'Templates/part_utils.asm'
%include 'Templates/part_hardcoded_library_linux.asm'

PlotSprite:
;rcx = source
;rdx = destination pixels
;r8  = width
;r9  = height
  push	rsi
  push  rdi
  push  r10
  push  r15
  push  r14
  mov	r15, [pixels_p]
  mov	rsi, rcx
  mov	rdi, rdx
  mov	r10d, r8d
  shl	r10d, 2
  mov	rdx, GC_SCREEN_WIDTH
  shl	edx, 2
.newLine:
  mov	ecx, 0
.tmp:
  mov	eax, [rsi+rcx*4]
  cmp	eax, 0h
  je	.skip
  lea	r14, [rdi+rcx*4]
  cmp	r14, r15
  jl	.skip
  mov	[r14], eax
.skip:
  add	ecx, 1
  cmp	ecx, r8d
  jnz	.tmp
  add	rsi, r10
  add	rdi, rdx
  dec	r9d
  jnz	.newLine
  pop	r14
  pop   r15
  pop   r10
  pop   rdi
  pop   rsi
  ret


%define source@_f_PlotSprite rbp+G_PARAMETER1
%define destination@_f_PlotSprite rbp+G_PARAMETER2
%define width@_f_PlotSprite rbp+G_PARAMETER3
%define height@_f_PlotSprite rbp+G_PARAMETER4
_f_PlotSprite:
;rcx = source
;rdx = destination pixels
;r8  = width
;r9  = height
  push  rbp
  mov   rbp, rsp
  mov   rcx, qword [source@_f_PlotSprite]
  mov   rdx, qword [destination@_f_PlotSprite]
  mov   r8, qword [width@_f_PlotSprite]
  mov   r9, qword [height@_f_PlotSprite]
  push	rsi
  push  rdi
  push  r10
  push  r15
  push  r14
  mov	r15, [pixels_p]
  mov	rsi, rcx
  mov	rdi, rdx
  mov	r10d, r8d
  shl	r10d, 2
  mov	rdx, GC_SCREEN_WIDTH
  shl	edx, 2
.newLine:
  mov	ecx, 0
.tmp:
  mov	eax, [rsi+rcx*4]
  cmp	eax, 0h
  je	.skip
  lea	r14, [rdi+rcx*4]
  cmp	r14, r15
  jl	.skip
  mov	[r14], eax
.skip:
  add	ecx, 1
  cmp	ecx, r8d
  jnz	.tmp
  add	rsi, r10
  add	rdi, rdx
  dec	r9d
  jnz	.newLine
  pop	r14
  pop   r15
  pop   r10
  pop   rdi
  pop   rsi
  mov   rsp, rbp
  pop   rbp
  retn  G_STACKSPACE_4_PARAM


%define source@_f_PlotSheetSprite rbp+G_PARAMETER1
%define destination@_f_PlotSheetSprite rbp+G_PARAMETER2
%define width@_f_PlotSheetSprite rbp+G_PARAMETER3
%define height@_f_PlotSheetSprite rbp+G_PARAMETER4
%define sheetwidth@_f_PlotSheetSprite rbp+G_PARAMETER5
_f_PlotSheetSprite:
;rcx = source
;rdx = destination pixels
;r8  = width
;r9  = height
;r13 = sheetwidth
  push  rbp
  mov   rbp, rsp
  mov   rcx, qword [source@_f_PlotSheetSprite]
  mov   rdx, qword [destination@_f_PlotSheetSprite]
  mov   r8, qword [width@_f_PlotSheetSprite]
  mov   r9, qword [height@_f_PlotSheetSprite]
  push	rsi
  push  rdi
  push  r10
  push  r15
  push  r14
  push  r13
  mov   r13, qword [sheetwidth@_f_PlotSheetSprite]
  shl	r13d, 2

  mov	r15, [pixels_p]
  mov	rsi, rcx
  mov	rdi, rdx
  mov	r10d, r8d
  shl	r10d, 2
  mov	rdx, GC_SCREEN_WIDTH
  shl	edx, 2
.newLine:
  mov	ecx, 0
.tmp2:
  mov	eax, [rsi+rcx*4]
  cmp	eax, 0h
  je	.skip
  lea	r14, [rdi+rcx*4]
  cmp	r14, r15
  jl	.skip
  mov	[r14], eax
.skip:
  add	ecx, 1
  cmp	ecx, r8d
  jnz	.tmp2
  add	rsi, r13
  add	rdi, rdx
  dec	r9d
  jnz	.newLine
  pop	r13
  pop   r14
  pop   r15
  pop   r10
  pop   rdi
  pop   rsi
  mov   rsp, rbp
  pop   rbp
  retn  G_STACKSPACE_5_PARAM

%define color@_f_GC_ClearScreenPixels rbp+G_PARAMETER1
_f_GC_ClearScreenPixels:
  push  rbp
  mov   rbp, rsp
  mov	rcx, GC_SCREEN_WIDTH * GC_SCREEN_HEIGHT
  mov	rdx, [pixels_p]
  mov	rax, qword [color@_f_GC_ClearScreenPixels]
  push	rdi
  mov	rdi, rdx
  cld
  rep	stosd
  pop   rdi
  mov   rsp, rbp
  pop   rbp
  retn  G_STACKSPACE_1_PARAM


section .data
Negation_XMM            db 0,0,0,0,0,0,0,80h
                        db 0,0,0,0,0,0,0,80h
Negation_XMM32          db 0,0,0,80h,0,0,0,0
                        db 0,0,0,80h,0,0,0,0
main_rbp                dq 0
processHeapHandle		dq 0
currentExeDirChars      db 256 dup(0)
tmpCharSpace            db 256 dup(0)	; needed for some hardcoded_library functions

align 8
ResultBytesWritten      dq 0
ResultBytesRead         dq 0
LockObject64            dq 0
pixels_p				dq 0

scanf_int_result        dq 0
scanf_int_read          db '%d',0
scanf_string_read       db '%s',0
sprintf_float_template  db '%.10f',0 
readalltext_openmode    db 'rb',0
bool_true_tostring      db 'true',0
bool_false_tostring     db 'false',0
carriage_return_bytes	db 13,10,0
assert_errormessage	    db 13,10,'*** ASSERT ERROR ***',13,10,13,10,0
cwd_path                db '/proc/self/cwd',0

align 16

; *** GENERATED DATA ***
;GC_INSERTIONPOINT_DATA
; *** END DATA ***
