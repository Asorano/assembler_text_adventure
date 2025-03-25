default rel

section .data
    ; STD_INPUT_HANDLE
    handle_console_in dq 06

    err_invalid_input: db "You need to enter a value between 1 and ", 0
    txt_input_confirm db "Your decision is: ", 0


section .bss
    bytes_read resq 1       ; Store number of bytes read
    input_buffer resb 128   ; Buffer for user input

section .text
    extern GetStdHandle, ReadConsoleA
    extern AnimateText, WriteText, WriteBuffer
    global SetupInput, ReadActionIndex, ReadNumber

    SetupInput:
        push rbp
        mov rbp, rsp
        sub rsp, 40
        ; Get handle to standard input (console)
        mov ecx, -10  ; STD_INPUT_HANDLE
        call GetStdHandle
        mov [handle_console_in], rax  ; Store the input handle

        add rsp, 40
        pop rbp
        ret

    ; Reads the input from stdin and tries to parse it into a number
    ; # Parameters:
    ; - [out] - rax = parsed number
    ReadNumber:
        ; Prologue
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  4 bytes input bytes read   (rsp+32)
        ; - 32 bytes input buffer       (rsp+)
        ; -  4 bytes alignment
        ; -----------------------------
        ; => 72 bytes
        push rbp
        sub rsp, 72

        mov rcx, [handle_console_in]    ; Input handle
        lea rdx, [rsp+40]               ; Address of buffer
        mov r8, 32                      ; Max bytes to read
        lea r9, [rsp+32]
        call ReadConsoleA

        cmp dword [rsp+32], 0
        jz _read_number_no_input

        ; The string now contains the input plus CR/LF
        ; Decrement size by one and replace the CR with a 0
        sub dword [rsp+32], 2
        lea rcx, [rsp+40]
        mov eax, DWORD [rsp+32]
        add rcx, rax
        mov [rcx], byte 0

        lea rcx, [rsp+40]
        call ParseNumberInput

    _read_number_end:
        ; Epilogue
        add rsp, 72
        pop rbp
        ret

    _read_number_no_input:
        mov rax, -1
        jmp _read_number_end


    ; Tries to parse a string to a number
    ; # Parameters:
    ; - [in]    rcx = address of the text buffer terminated by 0
    ; - [out]   rax = parsed number
    ParseNumberInput:
        push rsi
        lea rsi, [rcx]

        xor rax, rax
        xor rdx, rdx
        xor rcx, rcx

    _parse_number_loop:
        mov dl, byte [rsi]
        test dl, dl
        jz _parse_number_end

        ; Check whether the current byte is less than ASCII 0
        cmp dl, '0'
        jl _parse_number_invalid_input

        ; Check whether the current byte is greater than ASCII 9
        cmp dl, '9'
        jg _parse_number_invalid_input

        sub dl, '0'     ; Convert the current ASCII byte to a number
        imul rax, 10    ; Multiply current number by 10
        add rax, rdx    ; Add the current byte to the number

        inc rsi
        jmp _parse_number_loop

    _parse_number_invalid_input:
        mov rax, -1

    _parse_number_end:
        pop rsi
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
