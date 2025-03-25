default rel

section .text
    global CopyMemory

    ; Copies the data from pointer rcx to location of pointer rdx with the given length r8
    ; # Arguments:
    ;   - rcx = source pointer
    ;   - rdx = destination pointer 
    ;   -  r8 = length in byte
    CopyMemory:
        push rsi
        push rdi

        ; Prepare registers
        mov rsi, rcx
        mov rdi, rdx
        mov rcx, r8

        ; Clears the direction flag
        ; rdi and rsi will be incremented after string operations like movsb (move single byte)
        cld
        ; Execute movsb until decrementing rcx reaches 0
        rep movsb

        pop rdi
        pop rsi
        ret
