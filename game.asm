; A simple text adventure in x64 assembler

; The game is based on "decisions"
; Each decision consists of:
;   - 8 bytes (dq) pointer_to_text
;   - 4 bytes (dd) length of text
;   - 0..9 -> 8 bytes (dq) action / address of next decision 
;   - dq 0 -> Delimiter

; The game starts with the dc_initial decision.

default rel  ; Enables RIP-relative addressing for 64-bit mode

section .data

    %include "include/balancing.inc"
    %include "include/content.inc"

    ;dc_area_0_turn_on_light:

    ; Runtime data
    hConsoleIn dq 06

section .bss
    input_buffer resb 128   ; Buffer for user input
    current_decision dq 0
    bytes_read resq 1       ; Store number of bytes read
    current_health dw INITIAL_HEALTH
    decisions_taken resw 1

section .text
    global main
    extern ReadConsoleA, ExitProcess

    %include "include/decisions.inc"
    %include "include/input.inc"
    %include "include/output.inc"
    %include "include/view.inc"

main:
    sub rsp, 40  ; Ensure stack is 16-byte aligned

    ; Get handle to standard input (console)
    mov ecx, -10  ; STD_INPUT_HANDLE
    call GetStdHandle
    mov [hConsoleIn], rax  ; Store the input handle

    call SetupWrite

    mov rsi, dc_initial                         ; Initial current_decision with the initial decision
    mov [current_decision], rsi

    mov word [current_health], INITIAL_HEALTH   ; Initialize health

main_loop:
    call WritePlayerStats

    ; Print the current decision text
    mov rcx, [current_decision]
    mov rdx, [rcx + 8]
    mov rcx, [rcx]
    call WriteText

    ; Get the action count of the decision
    mov rcx, [current_decision]
    call GetActionCount

    cmp rax, 0x0                    ; Check whether action count of current decision is 0
    je EndGame

    push rax                        ; push action count on stack

    mov rcx, rax
    call ReadActionIndex                  ; selected digit in rax

    pop rdx


    cmp rax, rdx
    jae _invalid_action

    mov rcx, [current_decision]
    mov rdx, rax
    call GetActionTarget
    mov [current_decision], rax

    ; Increment decisions_taken
    mov rax, [decisions_taken]
    inc rax
    mov [decisions_taken], rax

    ; Write decision taken
    mov rcx, txt_decision_taken
    mov rdx, txt_decision_taken_l
    call WriteText

    jmp main_loop

_invalid_action:
    mov rcx, err_invalid_action
    mov rdx, err_invalid_action_l
    call WriteText
    jmp main_loop

EndGame:
    ; Print game over text and ends the process
    mov rcx, txt_game_over
    mov rdx, txt_game_over_l
    call WriteText

    ; Exit
    xor ecx, ecx
    call ExitProcess