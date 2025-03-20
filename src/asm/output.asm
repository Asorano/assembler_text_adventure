default rel
BITS 64

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

    ; Output handle for writing to the console
    handle_console_out dq 0

section .bss
    console_info resb CONSOLE_SCREEN_BUFFER_INFO_size
    cursor_coords resb COORD_size         ; X=5, Y=10 (Little-endian format)

section .text
    global SetupOutput, ResetCursorPosition, ClearOutput, WriteText, WriteBuffer, WriteNumber, WriteChar, SetTextColor, CalculateTextLength, WriteLastError
    extern GetStdHandle, WriteConsoleA, GetConsoleScreenBufferInfo, SetConsoleCursorPosition, FillConsoleOutputCharacterA, SetConsoleWindowInfo, SetConsoleTextAttribute, GetLastError, FormatMessageA

    ; Initializes the handle and screen info for the console output
    SetupOutput:
        ; Get handle to standard output (console)
        sub rsp, 32

        mov ecx, -11  ; STD_OUTPUT_HANDLE
        call GetStdHandle
        mov [handle_console_out], rax

        ; Get the console screen buffer info
        mov rcx, [handle_console_out]
        lea rdx, [console_info]
        call GetConsoleScreenBufferInfo

        add rsp, 32

        ret

    ; Resets the cursor position to the initially stored position
    ResetCursorPosition:
        sub rsp, 32
        mov rcx, [handle_console_out]
        xor rdx, rdx
        call SetConsoleCursorPosition
        add rsp, 32
        ret

    ; Clears the written characters until the initial stored cursor position
    ClearOutput:
        ; Stackframe:
        ; - 32 bytes shadow space
        ; - 8 bytes for 5th parameter
        ; - 8 bytes for out parameter lpNumberOfCharsWritten
        sub rsp, 48

        mov rcx, [handle_console_out]   ; Load console output handle
        mov rdx, ' '
        mov r8d, 10000                  ; Magic number to write enough characters to clear everything
        xor r9d, r9d                    ; dWriteCoord -> 0/0
        ; Pointer to the lpNumberOfCharsWritten in the stack frame
        lea rax, [rsp+40]
        mov [rsp+32], rax               

        call FillConsoleOutputCharacterA

        add rsp, 48
        ret

    ; Calculates the length of a text by searching the index of the first 0
    ; # Arguments:
    ;   - rcx = address of text, text must end with 0
    CalculateTextLength:
        mov rax, 0

    _calc_length_loop:
        ; Loads the next byte
        movzx rdx, byte [rcx]
        cmp rdx, 0
        je _return_length

        inc rax
        inc rcx
        
        jmp _calc_length_loop

    _return_length:
        ret

    ; Writes the text behind an address to the console
    ; # Arguments:
    ;   - rcx = address of text, text must end with 0
    WriteText:
        ; Allocate:
        ;   - 8 bytes for saving rcx
        ;   - 8 bytes for alignment
        ;   - 32 bytes shadow space
        sub rsp, 48

        ; Save rcx at the beginning of the stack frame
        mov [rsp+40], rcx

        ; Calculate the length of the text
        call CalculateTextLength
    
        mov rcx, [handle_console_out]   ; Handle to the console
        mov rdx, [rsp+40]               ; Pop the original rcx with the address into rdx
        mov r8, rax                     ; Move the length of the text
        mov r9, 0                       ; Pointer to number of chars written
        call WriteConsoleA

        add rsp, 48
        ret

    ; Writes the content of the buffer to the console
    ; # Arguments:
    ;   - rcx = address of text
    ;   - rdx = length of the text
    WriteBuffer:
        ; Reserve 32 bytes shadow space + 8 byte for the 5th parameter + 8 bytes alignment
        sub rsp, 48

        mov r8, rdx                     ; Length of text
        mov rdx, rcx                    ; Pointer to text
        mov rcx, [handle_console_out]   ; Handle to the console
        mov r9, 0                       ; Pointer to number of chars written, not required here
        mov qword[rsp+32], qword 0      ; Reserved parameter (must be 0)
        call WriteConsoleA
        
        add rsp, 48
        ret

    ; Writes a single char to the console via the write buffer
    WriteChar:
        ; rcx = char
        sub rsp, 16
        mov [rsp], rcx

        mov rcx, rsp
        mov rdx, 1
        call WriteBuffer

        add rsp, 16
        ret

    ; Writes all digit of an unsigned number to the console
    ; # Arguments:
    ;   - rcx = number to write
    ; # Registers:
    ;   - rdi = current buffer address
    ;   - rbx = divisor
    WriteNumber:
        ; Stackframe:
        ; - 32 bytes shadow space
        ; - 8 bytes for parameters
        ; - 8 bytes for rdi
        ; - 32 bytes for buffer
        sub rsp, 48 + 32

        mov [rsp+40], rdi       ; Preserve rdi. +40 because of 32 bytes shadow space and 8 byte for the 5th parameter

        mov rax, rcx            ; Use rax because rdx is used by the div op later
        mov rbx, 10             ; Prepare divisor

        ; 32 bytes were reserved for the output buffer
        ; Load the end address into rdi
        ; 48 bytes because of the shadow space, the 5th parameter and rdi
        ; 31 bytes because the buffer has 32 bytes length and the last address is required 
        lea rdi, [rsp+48+31]

        mov [rdi], byte 0       ; Null terminator (not needed for WriteConsoleA, but useful)
        dec rdi

        ; Check for zero
        test rax, rax
        jnz .write_number_loop

        ; Special case: print '0'
        mov byte [rdi], '0'
        dec rdi
        jmp .write_number_to_console

    .write_number_loop:
        ; Check whether the current char is a 0
        ; If yes, end the writing
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
        inc rdi           ; Undo last decrement
        mov rcx, rdi      ; Pointer to start of number string
        call WriteText

        ; Restore registers
        add rsp, 48 + 32

        ret

    ; Sets the foreground and background color in the console
    ; # Arguments:
    ;   - rcx = color value 0xBF (Background, Foreground) 
    SetTextColor:
        sub rsp, 32

        mov rdx, rcx
        mov rcx, [handle_console_out]     ; Console handle
        call SetConsoleTextAttribute      ; Change text color

        add rsp, 32
        ret

    ; Writes the last occured error to the console
    WriteLastError:
        ; Set text color to red
        mov rcx, 0x04
        call SetTextColor

        ; Stackframe:
        ; - 32 bytes shadow space
        ; - 24 bytes for arguments
        ; - 256 bytes error buffer
        ; - 8 bytes alignment
        sub rsp, 72 + 256       
        call GetLastError

        mov rcx, 0x00001000      ; FORMAT_MESSAGE_FROM_SYSTEM
        xor rdx, rdx             ; NULL source
        mov r8, rax              ; Error code
        mov r9d, 0               ; Language ID (default)
        lea rax, [rsp+56]
        mov [rsp+32], rax        ; Output buffer (5th parameter)
        mov qword [rsp+40], 256  ; Buffer size (6th parameter)
        mov qword [rsp+48], 0    ; Arguments (7th parameter)
        
        call FormatMessageA

        ; Load the text from the stack and write it
        lea rcx, [rsp+56]
        call WriteText

        ; Reset text color
        mov rcx, 0x07
        call SetTextColor

        ; Restore stack
        add rsp, 72 + 256

        ret