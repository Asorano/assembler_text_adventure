section .data
    ; STD_INPUT_HANDLE
    handle_console_in dq 06

section .bss
    bytes_read resq 1       ; Store number of bytes read
    input_buffer resb 128   ; Buffer for user input

section .text
    extern GetStdHandle, ReadConsoleA

    SetupInput:
        sub rsp, 0x28
        ; Get handle to standard input (console)
        mov ecx, -10  ; STD_INPUT_HANDLE
        call GetStdHandle
        mov [handle_console_in], rax  ; Store the input handle
        add rsp, 0x28
        ret

    ReadActionIndex:
        ; Reads input from the console
        ; Converts it to a number and verifies that the value is between 0 and 9
        ; rcx => action count
        ; Returns digit in rax
        mov r10, 0
        mov r13, rcx

    _read_digit_loop:
        ; Read the decision from the input
        mov rcx, txt_input_confirm
        call AnimateText

        mov rcx, [handle_console_in]  ; Handle to console input
        mov rdx, input_buffer   ; Pointer to input buffer
        mov r8, 127            ; Max number of bytes to read
        lea r9, [bytes_read]    ; Pointer to store number of bytes read
        sub rsp, 8                 ; Reserved parameter (must be 0)
        call ReadConsoleA
        add rsp, 8

        mov rax, [bytes_read]
        cmp rax, 3
        jne _invalid_digit_input

        ; Convert first character to number
        mov al, [input_buffer]
        sub al, '0'
        cmp al, 0
        je _invalid_digit_input
        cmp rax, r13
        ja _invalid_digit_input

        sub rax, 1

        ret

    _invalid_digit_input:
        ; Check whether the max input tries has been reached.
        ; End the game or repeat the input listening
        mov rcx, err_invalid_input
        call WriteText

        mov rdx, r13
        add rdx, '0'
        mov [input_buffer], rdx
        mov byte [input_buffer + 1], 10
        mov rcx, input_buffer
        mov rdx, 2
        call WriteText

        jmp _read_digit_loop
