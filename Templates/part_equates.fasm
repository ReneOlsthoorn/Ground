
; Below are the offsets on the stack in a Ground generated function. Relative to rbp+.
G_PARAMETER_THIS equ 16
G_PARAMETER_LEXPARENT equ 24
G_PARAMETER1 equ 32
G_PARAMETER2 equ 40
G_PARAMETER3 equ 48
G_PARAMETER4 equ 56
G_PARAMETER5 equ 64
G_PARAMETER6 equ 72

; Below is the amount of stackspace that needs to be cleaned after a Ground generated function.
G_STACKSPACE_0_PARAM equ 16
G_STACKSPACE_1_PARAM equ 32
G_STACKSPACE_2_PARAM equ 32
G_STACKSPACE_3_PARAM equ 48
G_STACKSPACE_4_PARAM equ 48
G_STACKSPACE_5_PARAM equ 64
G_STACKSPACE_6_PARAM equ 64
; no parameters pushes 16 bytes on the stack: the lexical parent frame on the stack, and the class instance (which is null in case of a normal function)
; 1 parameter will result in 32 bytes on the stack. 1=lexical parent, 2=class instance, 3=parameter1, 4=fastcall filler
