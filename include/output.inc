; Define structures correctly for NASM
section .data
    ; Define the COORD structure (4 bytes in total)
    struc COORD
        .X  resw 1  ; X position (2 bytes)
        .Y  resw 1  ; Y position (2 bytes)
    endstruc

    ; Define the SMALL_RECT structure (8 bytes in total)
    struc SMALL_RECT
        .Left   resw 1  ; 2 bytes
        .Top    resw 1  ; 2 bytes
        .Right  resw 1  ; 2 bytes
        .Bottom resw 1  ; 2 bytes
    endstruc

    ; Define the CONSOLE_SCREEN_BUFFER_INFO structure (22 bytes total)
    struc CONSOLE_SCREEN_BUFFER_INFO
        .dwSize                resw 2   ; Buffer size (COORD, 4 bytes)
        .dwCursorPosition      resw 2   ; Cursor position (COORD, 4 bytes)
        .wAttributes           resw 1   ; Attributes (2 bytes)
        .srWindow              resw 4   ; Window rect (SMALL_RECT, 8 bytes)
        .dwMaximumWindowSize   resw 2   ; Maximum window size (COORD, 4 bytes)
    endstruc

    ; Declare an instance of the structure

    handle_console_out dq 0

    newline db 10, 0
    newline_l equ 2

    whitespace db ' ', 0
    whitespace_l equ 2

    WRITE_BUFFER_CAPACITY equ 256
    write_buffer times WRITE_BUFFER_CAPACITY db 0 ; Initialize number output to 0
    write_buffer_length dq 0

section .bss
    num_chars_written resq 1
    console_info resb CONSOLE_SCREEN_BUFFER_INFO_size  ; Console info structure
    cursor_coords resb COORD_size         ; X=5, Y=10 (Little-endian format)

section .text
    extern GetStdHandle, WriteConsoleA, GetConsoleScreenBufferInfo, SetConsoleCursorPosition, FillConsoleOutputCharacterA, SetConsoleWindowInfo

    SetupOutput:
        sub rsp, 0x28
        ; Get handle to standard output (console)
        mov ecx, -11  ; STD_OUTPUT_HANDLE
        call GetStdHandle
        mov [handle_console_out], rax

        ; Get the console screen buffer info
        mov rcx, [handle_console_out]
        lea rdx, [console_info]
        call GetConsoleScreenBufferInfo

        add rsp, 0x28

        ret

    ResetCursorPosition:
        sub rsp, 0x28
        mov rcx, [handle_console_out]
        xor rdx, rdx
        call SetConsoleCursorPosition
        add rsp, 0x28
        ret

    ClearOutput:
        sub rsp, 0x28

        mov rcx, [handle_console_out]  ; Load console output handle
        mov rdx, ' '
        mov r8d, 10000
        xor r9d, r9d
        lea rax, [num_chars_written]
        mov [rsp+32], rax
        call FillConsoleOutputCharacterA

        add rsp, 0x28
        ret

    FlushOutputBuffer:
        ; rcx = address of text buffer
        mov rax, 0

    _length_loop:
        movzx rdx, byte [rcx]
        test rdx, rdx
        jz _flush

        inc rax
        inc rcx
        
        jmp _length_loop

    _flush:
        mov rcx, rax
        call WriteNumber
        ret

    WriteText:
        ; rcx = address of text
        ; rdx = length of the text
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
        ; rcx = char
        mov [write_buffer], rcx
        mov rcx, write_buffer
        mov rdx, 1
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
