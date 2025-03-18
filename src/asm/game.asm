; A simple text adventure in x64 assembler

; The game is based on "decisions"
; Each decision consists of:
;   - 8 bytes (dq) pointer_to_text
;   - 0..9 -> 8 bytes (dq) action / address of next decision 
;   - dq 0 -> Delimiter

; The game starts with the dc_initial decision.

default rel  ; Enables RIP-relative addressing for 64-bit mode

%include "src/include/input.inc"
%include "src/include/output.inc"
%include "src/include/view.inc"
%include "src/include/animations.inc"
%include "src/include/content.inc"
%include "data.inc"

section .data    
    INITIAL_HEALTH equ 100
    health dq (INITIAL_HEALTH << 32) | INITIAL_HEALTH

    decisions_taken dq 0

    txt_read_file db "Loading file...", 10, 0
    txt_file_loaded db "Game data loaded!", 10, 0

section .bss
    current_decision resq 1

section .text
    global main
    ; Project
    extern ReadGameDataFile, game_decision_count, GameDecision, GetActionCount, GetActionTarget
    ; Windows
    extern Sleep, ExitProcess

main:
    call SetupInput
    call SetupOutput

    call ClearOutput
    call ResetCursorPosition

    mov rcx, txt_read_file
    call AnimateText
    call ReadGameDataFile

    test rax, rax
    jz _exit

    mov [current_decision], rax

    mov rcx, txt_file_loaded
    call AnimateText

    mov rcx, 250
    sub rsp, 32
    call Sleep
    add rsp, 32

    call RenderGameIntro

main_loop:
    call ClearOutput
    call ResetCursorPosition

    call RenderGameHeader

    ; Print the current decision text
    mov rcx, [current_decision]
    mov rcx, [rcx + GameDecision.text]
    call AnimateText

    mov rcx, 10
    call WriteChar
    mov rcx, 10
    call WriteChar

    ; Get the action count of the decision
    mov rcx, [current_decision]
    call GetActionCount

    cmp rax, 0x0                    ; Check whether action count of current decision is 0
    je EndGame

    push rax                        ; push action count on stack

    mov rcx, [current_decision]
    call WriteActions

    mov rcx, [rsp+8]
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
    call WriteText
    jmp main_loop

EndGame:
    call RenderGameEnd

_exit:
    ; Exit the process
    sub rsp, 0x28
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28

WriteActions:
    ; Arguments:
    ; - rcx = Address of the decision
    push r12
    push r13

    mov r12, rcx
    add r12, GameDecision.action_0 + GameAction.text

    mov r13, 1

_write_actions_loop:
    mov rax, [r12]
    test rax, rax
    jz _end_write_actions_loop

    mov rcx, r12
    mov rdx, r13
    call WriteAction

    add r12, GameDecision_size
    inc r13
    jmp _write_actions_loop

_end_write_actions_loop:
    mov rcx, 10
    call WriteChar

    pop r13
    pop r12
    ret

WriteAction:
    ; Arguments:
    ; - rcx = Address of the action
    ; - rdx = Action index
    push rcx

    mov rcx, rdx
    call WriteNumber

    mov rcx, ')'
    call WriteChar

    mov rcx, ' '
    call WriteChar
    
    pop rcx
    mov rcx, [rcx]
    call AnimateText

    mov rcx, 10
    call WriteChar

    ret