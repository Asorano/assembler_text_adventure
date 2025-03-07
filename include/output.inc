section .data
    newline db 10, 0
    newline_l equ 2

    whitespace db ' ', 0
    whitespace_l equ 2

    NUMBER_OUT_BUFFER_CAPACITY equ 20
    number_output_buffer times NUMBER_OUT_BUFFER_CAPACITY db 0 ; Initialize number output to 0

section .text
    WriteText:
        ; rcx - Pointer to message
        ; rdx - Message length
        mov r8, rdx             ; Move the length of the text
        mov rdx, rcx            ; Move the pointer to the text
        mov rcx, [hConsoleOut]  ; Handle
        lea r9, [rsp-8]         ; Pointer to number of chars written
        push 0                  ; Reserved parameter (must be 0)
        call WriteConsoleA
        pop rax
        ret

    WriteNewLine:
        push rcx
        push rdx
        mov rcx, newline
        mov rdx, newline_l
        call WriteText
        pop rdx
        pop rcx
        ret

    WriteSpace:
        push rcx
        push rdx
        mov rcx, whitespace
        mov rdx, whitespace_l
        call WriteText
        pop rdx
        pop rcx
        ret

    WriteDigit:
        ; rcx - Digit
        add rcx, '0'
        mov [output_buffer], rcx
        mov rcx, output_buffer
        mov rdx, 1
        call WriteText
        ret

    WriteNumber:
        ; rcx = number
        push rcx

        mov rax, rcx                            ; Use rax because rdx is used by the div op later
        mov rbx, 10                             ; Prepare divisor
        mov rdi, number_output_buffer
        add rdi, NUMBER_OUT_BUFFER_CAPACITY-1   ; move rdi to end of buffer

        mov byte [rdi], 0                       ; add string terminate
        dec rdi

    .write_number_check_zero
        ; Check for zero
        test rax, rax
        jnz .write_number_loop

        ; Add zero to buffer and then write it to the console
        mov byte [rdi], '0'
        dec rdi
        jmp .write_number_to_console

    .write_number_loop:
        ; If the number is zero, print it
        test rax, rax
        jz .write_number_to_console

        ; Divide 
        xor rdx, rdx        ; Fast reset to 0, faster than mov
        div rbx

        add dl, '0'         ; Convert to ASCII
        mov [rdi], dl       ; Copy in output buffer
        dec rdi

        jmp .write_number_loop

    .write_number_to_console:

        mov rcx, rdi
        mov rdx, rdi
        mov rax, number_output_buffer
        sub rdx, rax
        call WriteText

        ; Restore caller-safe parameters
        pop rcx

        ret