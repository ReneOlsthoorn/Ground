
global main

%include 'Templates/part_equates.asm'
gc_linux equ 1
gc_windows equ 0
%include 'Include/clib_extern.inc'

; *** GENERATED EQUATES CODE ***
;GC_INSERTIONPOINT_EQUATES

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


%define PrintScreenStringDefined 1
PrintScreenString:
;input rax: pointer to string
  push	rsi
  push  rdi
  push  rcx
  mov	rsi, rax        ; par 2 = pointer to buffer
  mov	rcx, rax
  call	StringLength
  mov	rdx, rax        ; par 3 = length of buffer
  mov rax, 1        ; SYS_write
  mov rdi, 1        ; stdout (file descriptor)
  syscall
  pop   rcx
  pop   rdi
  pop   rsi
  ret

ReadChar:
  push	rsi
  push  rdi
  push  rbp             ; fastcall 16-byte stack alignment
  mov	r8, 1
  mov   rax, 0          ; SYS_read
  mov   rdi, 0          ; stdin (fd = 0)
  lea   rsi, [tmpCharSpace]
  mov   rdx, 1          ; read exactly 1 byte
  syscall
  pop	rbp
  pop   rdi
  pop   rsi
  ret

%include 'Templates/part_string_linux.asm'
%include 'Templates/part_utils.asm'
%include 'Templates/part_hardcoded_library_linux.asm'

section .data
Negation_XMM            db 0,0,0,0,0,0,0,80h
                        db 0,0,0,0,0,0,0,80h
Negation_XMM32          db 0,0,0,80h,0,0,0,0
                        db 0,0,0,80h,0,0,0,0
main_rbp                dq 0

currentExeDirChars      db 256 dup(0)
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
cwd_path                db '/proc/self/cwd',0

align 16

; *** GENERATED DATA ***
;GC_INSERTIONPOINT_DATA
; *** END DATA ***
