; A simple text adventure in x64 assembler

; The game is based on "decisions"
; Each decision consists of:
;   - 8 bytes (dq) pointer_to_text
;   - 4 bytes (dd) length of text
;   - 0..9 -> 8 bytes (dq) action / address of next decision 
;   - dq 0 -> Delimiter

; The game starts with the dc_initial decision.

default rel  ; Enables RIP-relative addressing for 64-bit mode

%include "include/decisions.inc"
%include "include/input.inc"
%include "include/output.inc"
%include "include/view.inc"
%include "include/balancing.inc"
%include "include/content.inc"

section .data
    decisions_taken dq 0
    health dq (INITIAL_HEALTH << 32) | INITIAL_HEALTH

section .bss
    current_decision resq 1

section .text
    global main
    extern Sleep, ExitProcess

main:
    call SetupInput
    call SetupOutput

    ; Initialize initial decision
    mov rsi, dc_initial                         
    mov [current_decision], rsi

main_loop:
    call ClearOutput
    call ResetCursorPosition
    call RenderGameView

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
    inc word [decisions_taken]

    ; mov ecx, 100
    ; call Sleep

    jmp main_loop

_invalid_action:
    mov rcx, err_invalid_action
    mov rdx, err_invalid_action_l
    call WriteText
    jmp main_loop

EndGame:
    sub rsp, 0x28
    ; Print game over text and ends the process
    mov rcx, txt_game_over
    mov rdx, txt_game_over_l
    call WriteText

    ; Exit
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28