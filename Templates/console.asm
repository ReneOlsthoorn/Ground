format pe64 console
entry start
stack 80000h, 80000h      ; reserve 512k stack virtual space, allocate 512k at startup. So 512k stack is available.

include 'fasm2/include/win64a.inc'
include 'Templates/part_equates.asm'
gc_linux equ 0
gc_windows equ 1

; *** GENERATED EQUATES CODE ***
;GC_INSERTIONPOINT_EQUATES

section '.text' code readable executable
start:
  push	rbp
  mov	rbp, rsp
  mov   [main_rbp], rbp

  mov   rcx, STD_OUTPUT_HANDLE
  sub   rsp, 0x20
  call  [kernel32_GetStdHandle]
  add   rsp, 0x20
  mov	[GetStdHandle_outputhandle], rax

  mov   rcx, STD_INPUT_HANDLE
  sub   rsp, 0x20
  call  [kernel32_GetStdHandle]
  add   rsp, 0x20
  mov	[GetStdHandle_inputhandle], rax

  sub   rsp, 0x20
  call  [kernel32_GetProcessHeap]
  add   rsp, 0x20
  mov	[processHeapHandle], rax

  xor   rcx, rcx                    ; hModule = NULL
  mov   rdx, currentExeDirChars     ; lpFilename
  mov   r8, 256                     ; nSize
  sub   rsp, 0x20
  call  [kernel32_GetModuleFileNameA]
  add   rsp, 0x20
  mov	rcx, currentExeDirChars
  call	StringLength    ; rax stringlength
  mov   r8, currentExeDirChars
  mov   rcx, rax
.currentExeDirloop:
  mov   al, byte [r8+rcx]
  cmp   al, '\'
  je    .currentExeDirExitloop
  cmp   al, '/'
  je    .currentExeDirExitloop
  mov   byte [r8+rcx], 0
  dec   rcx
  jnz   .currentExeDirloop
  mov   byte [r8], 0
.currentExeDirExitloop:
  mov   byte [r8+rcx], 0


; *** GENERATED MAIN CODE ***
;GC_INSERTIONPOINT_MAIN
; *** END MAIN CODE ***

assert_exitpoint:
  mov	rsp, rbp
  mov   rcx, 0
  sub   rsp, 0x20
  call  [kernel32_ExitProcess]
  add   rsp, 0x20
  pop	rbp
  ret


; *** GENERATED PROCEDURES (GROUND FUNCTIONS AND CLASSES) ***
;GC_INSERTIONPOINT_PROCEDURES
; *** END PROCEDURES ***


PrintScreenString:
;input rax: pointer to string
  push	r8
  push  r9
  push  rcx       ; fastcall 16-byte stack alignment
  mov	r8, rax
  mov	rcx, rax
  call	StringLength

  sub   rsp, 0x30
  mov   rcx, [GetStdHandle_outputhandle] ; hFile
  mov   rdx, r8                          ; lpBuffer
  mov	r8, rax                          ; nNumberOfBytesToWrite
  lea   r9, [ResultBytesWritten]         ; lpNumberOfBytesWritten
  mov   qword [rsp+0x20], 0              ; lpOverlapped = NULL
  call  [kernel32_WriteFile]
  add   rsp, 0x30

  pop   rcx
  pop   r9
  pop   r8
  ret

ReadChar:
  push	rbp             ; fastcall 16-byte stack alignment
  sub   rsp, 0x30
  mov   rcx, [GetStdHandle_inputhandle] ; hFile
  lea	rdx, [tmpCharSpace]
  mov   r8, 1                           ; nNumberOfBytesToRead
  lea   r9, [ResultBytesRead]           ; lpNumberOfBytesRead
  mov   qword [rsp+0x20], 0             ; lpOverlapped = NULL
  call  [kernel32_ReadFile]
  add   rsp, 0x30
  pop	rbp
  ret

include 'Templates/part_string.asm'
include 'Templates/part_utils.asm'
include 'Templates/part_hardcoded_library.asm'



section '.idata' import data readable writeable
  library kernel32,'kernel32.dll', \
;GC_INSERTIONPOINT_LIBRARIES
          msvcrt, 'msvcrt.dll'

  include 'Include/kernel32_api.inc'
  include 'Include/msvcrt_api.inc'
;GC_INSERTIONPOINT_LIBRARY_API_INCLUDES



section '.data' data readable writeable
Negation_XMM            db 0,0,0,0,0,0,0,80h
                        db 0,0,0,0,0,0,0,80h
Negation_XMM32          db 0,0,0,80h,0,0,0,0
                        db 0,0,0,80h,0,0,0,0
main_rbp                dq 0
processHeapHandle		dq 0
GetStdHandle_outputhandle dq 0
GetStdHandle_inputhandle  dq 0

currentExeDirChars      db 256 dup(0)
cwdChars                db 256 dup(0)
tmpCharSpace            db 256 dup(0)

align 8

ResultBytesWritten      dq 0
ResultBytesRead         dq 0
scanf_int_result        dq 0
scanf_int_read          db '%d',0
scanf_string_read       db '%s',0
sprintf_float_template  db '%.10f',0 
readalltext_openmode    db 'rb',0
bool_true_tostring      db 'true',0
bool_false_tostring     db 'false',0
carriage_return_bytes	db 13,10,0
assert_errormessage	    db 13,10,'*** ASSERT ERROR ***',13,10,13,10,0

align 16

; *** GENERATED DATA ***
;GC_INSERTIONPOINT_DATA
; *** END DATA ***
