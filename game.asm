; A simple text adventure in x64 assembler

default rel  ; Enables RIP-relative addressing for 64-bit mode

section .data
    ; Common
    newline db 10, 0
    newline_l db 2
    max_input_tries db 3

    ; Texts
    err_invalid_input: db "You need to enter a value between 1 and 9!", 10, 0
    err_invalid_input_l equ $ - err_invalid_input

    err_too_many_invalid_input: db "While thinking about your decision, the time passed by and you turned into a mummy.", 10, 0
    err_too_many_invalid_input_l equ $ - err_too_many_invalid_input

    err_invalid_action: db "Impossible!", 10, 10, 0
    err_invalid_action_l equ $ - err_invalid_action

    txt_game_over db 10, "***************************", 10, "******** GAME OVER ********", 10, "***************************", 10, 10, "Thank you for playing! Better luck next time!", 10, 0
    txt_game_over_l equ $ - txt_game_over

    txt_input_confirm db "Your decision is: ", 0
    txt_input_confirm_l equ $ - txt_input_confirm

    txt_decision_taken db "---------------------------------------------------------------------------", 10, 0
    txt_decision_taken_l equ $ - txt_decision_taken

    ; Decisions
    dc_initial:
        dq txt_dc_initial
        dd txt_dc_initial_l
        dq dc_stage1_light_on
        dq dc_game_end
        dq 0

    txt_dc_initial:
        db  "You are in a dark room. What do you do?", 10, "   1) Turn on the light", 10, "   2) Exit the game. Too creepy here.", 10, 10, 0
    txt_dc_initial_l equ $ - txt_dc_initial

    dc_stage1_light_on:
        dq txt_dc_stage1_light_on
        dd txt_dc_stage1_light_on_l
        dq dc_initial
        dq 0

    txt_dc_stage1_light_on db "The light turns on. You see a carnage in front of you. A massacre. A whole pile of corpse.", 10, "   1) Turn the light off", 10, 10, 0
    txt_dc_stage1_light_on_l equ $ - txt_dc_stage1_light_on

    dc_game_end:
        dq txt_dc_game_end
        dd txt_dc_game_end_l
        dq 0

    txt_dc_game_end db "The dream is over! Head back to reality.", 10, 0
    txt_dc_game_end_l equ $ - txt_dc_game_end

    ;dc_area_0_turn_on_light:

    hConsoleOut dq 0
    hConsoleIn dq 0
    previous_cursor_y db 5   ; Example Y position (you may want to store it dynamically)
    previous_cursor_x db 0   ; X position (start of the line)

section .bss
    input_buffer resb 128   ; Buffer for user input
    current_decision resq 1
    bytes_read resq 1       ; Store number of bytes read

section .text
    global main
    extern GetStdHandle, WriteConsoleA, ReadConsoleA, ExitProcess

main:
    sub rsp, 40  ; Ensure stack is 16-byte aligned

    ; Get handle to standard input (console)
    mov ecx, -10  ; STD_INPUT_HANDLE
    call GetStdHandle
    mov [hConsoleIn], rax  ; Store the input handle

    ; Get handle to standard output (console)
    mov ecx, -11  ; STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [hConsoleOut], rax

    ; Initial current_decision with the initial decision
    mov rsi, dc_initial
    mov [current_decision], rsi

main_loop:
    ; Print the current decision text
    mov rcx, [current_decision]
    mov rdx, [rcx + 8]
    mov rcx, [rcx]
    call WriteText

    ; Get the action count of the decision
    mov rcx, [current_decision]
    call GetActionCount

    cmp rax, 0x0
    je EndGame

    push rax                        ; push action count on stack

    ; Read the decision from the input
    mov rcx, txt_input_confirm
    mov rdx, txt_input_confirm_l
    call WriteText

    call ReadDigit                  ; selected digit in rax

    pop rdx

    cmp rax, rdx
    jae _invalid_action

    mov rcx, [current_decision]
    mov rdx, rax
    call GetActionTarget
    mov [current_decision], rax

    mov rcx, txt_decision_taken
    mov rdx, txt_decision_taken_l
    call WriteText

    jmp main_loop

_invalid_action:
    mov rcx, err_invalid_action
    mov rdx, err_invalid_action_l
    call WriteText
    jmp main_loop

GetActionTarget:
    ; rcx => decision address
    ; rdx => action index
    ; rax = returns action target decision address
    shl rdx, 3  ; multiply by 8 since an action address is 8 bytes
    add rcx, 12
    add rcx, rdx
    mov rax, [rcx]
    ret

GetActionCount:
    ; rcx => decision address
    mov rax, 0
    add rcx, 12     ; Jump to the first possible action

_action_counter_loop:
    mov rdx, [rcx]  ; Load the
    cmp rdx, 0
    je _action_return

    inc rax
    add rcx, 8
    jmp _action_counter_loop

_action_return
    ret

ReadDigit:
    ; Reads input from the console
    ; Converts it to a number and verifies that the value is between 0 and 9
    ; Returns digit in rax

    mov r10, 0

_read_digit_loop:
    mov rcx, [hConsoleIn]  ; Handle to console input
    mov rdx, input_buffer   ; Pointer to input buffer
    mov r8, 127            ; Max number of bytes to read
    lea r9, [bytes_read]    ; Pointer to store number of bytes read
    push 0                 ; Reserved parameter (must be 0)
    call ReadConsoleA
    pop rax

    mov rax, [bytes_read]
    cmp rax, 3
    jne _invalid_digit_input

    ; Convert first character to number
    mov al, [input_buffer]
    sub al, '0'
    cmp al, 9
    ja _invalid_digit_input
    cmp al, 0
    je _invalid_digit_input

    sub rax, 1
    ret

_invalid_digit_input:
    ; Check whether the max input tries has been reached.
    ; End the game or repeat the input listening

    mov al, [max_input_tries]
    inc r12
    cmp r12, rax
    je _too_many_inputs

    mov rcx, err_invalid_input
    mov rdx, err_invalid_input_l
    call WriteText

    jmp _read_digit_loop

_too_many_inputs:
    ; Print the error message and end the game
    mov rcx, err_too_many_invalid_input
    mov rdx, err_too_many_invalid_input_l
    call WriteText

    jmp EndGame

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

EndGame:
    ; Print game over text and ends the process
    mov rcx, txt_game_over
    mov rdx, txt_game_over_l
    call WriteText

    ; Exit
    xor ecx, ecx
    call ExitProcess