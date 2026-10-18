
;WIN32 calling convention:
;Registers: rax, rbx, rcx, rdx, rsi, rdi, rbp, rsp, r8-r15, ymm0-ymm15(AVX) or xmm0-xmm15(SSE)
;the volatile registers are: rax, rcx, rdx, r8-r11. Other registers must be restored when returning.
;xmm0-xmm5(including) are volatile.
;
;Calling convention:
;parameter1 = rcx/xmm0
;parameter2 = rdx/xmm1
;parameter3 = r8/xmm2
;parameter4 = r9/xmm3
;Bij een mix van integers en floats worden registers overgeslagen. Voorbeeld: func3(int a, double b, int c, float d); ->  a in RCX, b in XMM1, c in R8, d in XMM3
;
;Setting up a local stack for storage of local vars:
;push rbp
;mov rbp, rsp
;sub rsp, 30h        ; 4 qwords space for the 4 parameters. Store them for later use.
;mov [rbp-8h], rcx   ; storage of par1
;mov [rbp-10h], rdx  ; storage of par2
;mov [rbp-18h], r8   ; storage of par3
;mov [rbp-20h], r9   ; storage of par4
;mov rax, [rbp+30h] ; parameter 5
;mov rax, [rbp+38h] ; parameter 6
;etc...
;pop rbp
;ret
;
;Extra:
;32-bit operands generate a 32-bit result, zero-extended to a 64-bit result in the destination general-purpose register.
;Also mov eax, 0 is better than mov rax, 0 because the 32-bit variant is one byte shorter in code.
;rdx is a dangerous register. With a MUL instruction it is modified, because the result is stored in rdx:rax (or edx,eax). It's best to always use rax en rdx for tmp values during coding.


;System V AMD64 ABI, LINUX calling convention:
; parameters rdi, rsi, rdx, rcx, r8, and r9. The seventh and subsequent arguments are passed on the stack.
; The return value is passed in registers rax and rdx.
; volatile registers: rax, rcx, rdx, rsi, rdi, r8-r11, xmm0-xmm15. Caller saved, that is the function calling the function.
; non-volatile registers are rbx, r12-r15, rsp, rbp. These regisers must be saved by the callee, that is the function that is called.


StoreBytes:
; rcx = nr of bytes
; rdx = destination pointer
; al = value to set
  push	rdi
  mov	rdi, rdx
  cld
  rep	stosb		; Notice: a rep stosb is as fast as rep stosq since Haswell (4770). Rep movsb uses 256-bit operations internally.
  pop   rdi
  ret


Utils_SetArray:
	;rcx = nr of bytes
	;rdx = destination pointer
	;r8 = value
    push rdi
	mov rdi, rdx
	mov rax, r8
	cld
	rep stosb
	; please notice: a rep stosb is as fast as rep stosq since Haswell (4770). Rep movsb uses 256-bit operations internally.
	pop rdi
    ret


Utils_CopyArray:
	;rcx = nr of bytes
	;rdx = source pointer
	;r8 = destination pointer
    push rsi
	push rdi
	mov rsi, rdx;
	mov rdi, r8;
	cld
	rep movsb
	; please notice: a rep movsb is as fast as rep movsq since Haswell (4770). Rep movsb uses 256-bit operations internally.
	pop rdi
	pop rsi
    ret
