

AddCombinedStrings:
;INPUT: rcx = ptr to first string
;       rdx = ptr to second string
;       rax = ptr to result string being max. 256 bytes. That is 255 chars and 1 ending zero.
;OUTPUT:rax = ptr to result string
  push	r8 r9 rax
  mov	r8, rax 
  xor	r9, r9
.loopFirst:
  mov	al, [rcx]
  mov	[r8+r9], al
  cmp	al, 0
  je	.loopSecond
  inc	rcx
  inc	r9
  cmp	r9, 255
  jne	.loopFirst
  xor	eax, eax
  mov	[r8+r9], al
  jmp	.exit
.loopSecond:
  mov	al, [rdx]
  mov	[r8+r9], al
  cmp	al, 0
  je	.exit
  inc	rdx
  inc	r9
  cmp	r9, 255
  jne	.loopSecond
  xor	eax, eax
  mov	[r8+r9], al
.exit:
  pop	rax r9 r8
  ret


PrintNumber:
  push	rbp					; win32 16-byte stack alignment
  mov	rbp, rsp
  sub	rsp, 0x10			; the 16 byte alignment forces us to reserve a full 16 bytes for the needed 2 bytes.
  push	rdx r8
  cdq						; sign extend eax into edx. edx:eax = number
  idiv	rcx					; rax = quotient, rdx = remainder
  test	eax, eax			; Is quotient zero?
  je	@F					; yes, don't display it
  call	PrintNumber			; Display the quotient
@@:
  lea	r8d, [edx+'0']
  lea	rax, [rbp - 0x10]
  mov	[rax], r8b
  mov	byte [rax+1], 0		; zero-terminated
if defined PrintScreenString
  call	PrintScreenString	; Display the remainder
end if
  pop	r8 rdx
  mov	rsp, rbp
  pop	rbp
  ret


IntegerToString:
; rax = int value to convert
; rcx = the buffer to store the result
;RESULT: rcx buffer is filled
  push	rcx rdi rbx r14 r15     ; win32 stack 16-byte alignment
  mov	rdi, rcx
  cld
  test	rax, rax
  js	.negative
  xor	r15, r15
  jmp	.not_negative
.negative:
  neg	rax
  mov	r15, 1
.not_negative:
  xor	ebx, ebx        ; clear the ebx, I will use as counter for stack pushes
.push_chars:
  xor	edx, edx        ; clear edx
  mov	ecx, 10         ; ecx is divisor, divide by 10
  div	rcx             ; divide edx by ecx, result in eax remainder in edx
  add	edx, '0'        ; add 0x30 to edx convert int => ascii
  push	rdx             ; push result to stack
  inc	rbx             ; increment my stack push counter
  test	eax, eax        ; is eax 0?
  jnz	.push_chars     ; if eax not 0 repeat
  mov	rcx, rbx
  add	rcx, 1          ; zero-terminated
  test	r15, r15
  jz	.niet_negatief
  add	rcx, 1			; "-" sign
.niet_negatief:
  test	r15, r15
  jz	.no_extra_sign
  mov	al, '-'
  stosb
.no_extra_sign:
  mov	r8, rcx
.pop_chars:
  pop	rax             ; pop result from stack into eax
  stosb                 ; al -> rdi, rdi++
  dec	rbx             ; decrement my stack push counter
  cmp	rbx, 0          ; check if stack push counter is 0
  jg	.pop_chars      ; not 0 repeat
  xor	eax, eax		; store the string terminating zero byte
  stosb
  mov	rax, r8
  pop	r15 r14 rbx rdi rcx
  ret


;the %f only prints 64-bit floats, so convert f32 to f64 before using this function.
;rcx = the buffer to store the result
;RESULT: rcx buffer is filled
FloatToString:
  push  rcx rsi rdi
  mov	rdi, rcx
  movq  rax, xmm0
  invoke msvcrt_sprintf,tmpCharSpace,sprintf_float_template,rax
  lea   rcx, [tmpCharSpace]
  mov   rsi, rcx
  call  StringLength
  inc   rax
  mov	rcx, rax
  cld
  rep	movsb			; copy string
  pop   rdi rsi rcx
  ret


BooleanToString:
  cmp   al, 0
  je   .notFalse
  lea   rax, [bool_true_tostring]
  jmp   .exitBooleanToString
.notFalse:
  lea   rax, [bool_false_tostring]
.exitBooleanToString:
  ret


StringLength:
; rcx = pointer to zero-terminated string
; result in rax
  xor	eax, eax
  cmp	byte [rcx+rax], 0
  je	.exit
.loop:
  inc	eax
  cmp	byte [rcx+rax], 0
  je	.exit
  cmp	eax, 255
  jne	.loop
.exit:
  ret


CopyString:
; rax = source
; rcx = destination
  push	rsi rdi
  mov	rsi, rax
  mov	rdi, rcx
  mov	rcx, 255
.loop:
  lodsb			; al = [rsi], rsi++
  stosb			; [rdi] = al, rdi++
  test	al, al
  jz	.done
  dec	rcx
  jnz	.loop
  mov	al,0
  stosb
.done:
  pop	rdi rsi
  ret

