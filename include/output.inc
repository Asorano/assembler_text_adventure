section .data
    handle_console_out dq 0
    cursor_coords dq 0x0005000A         ; X=5, Y=10 (Little-endian format)

    newline db 10, 0
    newline_l equ 2

    whitespace db ' ', 0
    whitespace_l equ 2

    WRITE_BUFFER_CAPACITY equ 20
    write_buffer times WRITE_BUFFER_CAPACITY db 0 ; Initialize number output to 0

section .bss
    num_chars_written resq 1

section .text
    extern GetStdHandle, WriteConsoleA, GetConsoleScreenBufferInfo, SetConsoleCursorPosition, FillConsoleOutputCharacterA

    SetupOutput:
        sub rsp, 0x28
        ; Get handle to standard output (console)
        mov ecx, -11  ; STD_OUTPUT_HANDLE
        call GetStdHandle
        add rsp, 0x28
        mov [handle_console_out], rax
        ret

    SetCursorPosition:
        sub rsp, 0x28
        mov rcx, [handle_console_out]
        mov edx, 0x0 
        call SetConsoleCursorPosition
        add rsp, 0x28
        ret

    ClearOutput:
        mov rcx, ' '
        mov rdx, 2000
        call WriteCharMultipleTimes

    WriteCharMultipleTimes:
        sub rsp, 0x28

        mov r8d, edx                    ; Number of characters to write (2000)
        movzx rdx, byte cl ; cCharacter ('*')
        mov rcx, [handle_console_out]  ; Load console output handle

        xor r9d, r9d                     ; Start at position (0, 0)
        lea rax, [num_chars_written]
        mov [rsp+32], rax
        call FillConsoleOutputCharacterA ; Call the API to fill the console
        add rsp, 0x28
        ret

    WriteText:
        sub rsp, 0x28

        mov r8, rdx             ; Move the length of the text
        mov rdx, rcx            ; Move the pointer to the text
        mov rcx, [handle_console_out]  ; Handle to the console
        lea r9, [rsp-8]         ; Pointer to number of chars written
        push 0                  ; Reserved parameter (must be 0)
        call WriteConsoleA
        pop rcx
        
        add rsp, 0x28

        ret


    WriteChar:
        mov [write_buffer], rcx
        mov rcx, write_buffer
        mov rdx, 2
        call WriteText
        ret

    WriteNumber:
        ; rcx = number
        push rdi   ; Preserve rdi

        mov rax, rcx                     ; Use rax because rdx is used by the div op later
        mov rbx, 10                      ; Prepare divisor
        mov rdi, write_buffer
        add rdi, WRITE_BUFFER_CAPACITY-1 ; Move to end of buffer

        mov byte [rdi], 0                 ; Null terminator (not needed for WriteConsoleA, but useful)
        dec rdi

        ; Check for zero
        test rax, rax
        jnz .write_number_loop

        ; Special case: print '0'
        mov byte [rdi], '0'
        dec rdi
        jmp .write_number_to_console

    .write_number_loop:
        test rax, rax
        jz .write_number_to_console

        xor rdx, rdx   ; Reset rdx for division
        div rbx        ; rax = rax / 10, rdx = rax % 10

        add dl, '0'    ; Convert remainder to ASCII
        mov [rdi], dl  ; Store digit in buffer
        dec rdi

        jmp .write_number_loop

    .write_number_to_console:
        ; Move rdi to the start of the number string
        inc rdi  ; Undo last decrement

        ; Correct length calculation
        mov rcx, rdi                      ; Pointer to start of number string
        mov rdx, write_buffer
        add rdx, WRITE_BUFFER_CAPACITY-1  ; End of buffer
        sub rdx, rcx                      ; Length = (end - start)

        call WriteText

        ; Restore registers
        pop rdi

        ret
