; A simple text adventure in x64 assembler
default rel

%include "src/include/input.inc"
%include "src/include/output.inc"
%include "src/include/view.inc"
%include "src/include/animations.inc"
%include "src/include/content.inc"
%include "data.inc"

section .data    
    decisions_taken dq 0

section .bss
    current_decision resq 1

section .text
    global main
    ; Project
    extern ReadGameDataFile, GameDecision, GetActionCount, GetActionTarget
    ; Windows
    extern Sleep, ExitProcess

main:
    call SetupInput
    call SetupOutput

    call ClearOutput
    call ResetCursorPosition

    call ReadGameDataFile

    test rax, rax
    jz _exit

    mov [current_decision], rax

    mov rcx, 250
    sub rsp, 32
    call Sleep
    add rsp, 32

    call RenderGameIntro

    sub rsp, 16
game_loop:
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

    mov [rsp+8], rax

    cmp rax, 0x0                    ; Check whether action count of current decision is 0
    je _end_game_loop
 
    mov rcx, [current_decision]
    call WriteActions

    mov rcx, [rsp+8]
    call ReadActionIndex                  ; selected digit in rax

    cmp rax, [rsp+8]
    jae _invalid_action

    mov rcx, [current_decision]
    mov rdx, rax
    call GetActionTarget
    mov [current_decision], rax

    ; Increment decisions_taken
    inc word [decisions_taken]

    jmp game_loop

_end_game_loop:
    add rsp, 16
    jmp EndGame

_invalid_action:
    mov rcx, err_invalid_action
    call WriteText
    jmp game_loop

WriteActions:
    ; Arguments:
    ; - rcx = Address of the decision
    push r12
    push r13

    mov r12, rcx
    add r12, GameDecision.action_0 + GameAction.text

    mov r13, 1

_write_actions_loop:
    cmp r13, MAX_ACTION_COUNT
    jae _end_write_actions_loop
    
    mov rax, [r12]
    test rax, rax
    jz _end_write_actions_loop

    mov rcx, r12
    mov rdx, r13
    call WriteAction

    add r12, GameAction_size
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

EndGame:
    call RenderGameEnd

_exit:
    ; Exit the process
    sub rsp, 0x28
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28