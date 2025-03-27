; A simple text adventure in x64 assembler
default rel

%include "view.inc"
%include "text.inc"
%include "data.inc"

section .data    
    decisions_taken dq 0

    test_id db "act_0_turn_light_on", 0

section .bss
    game_data resq 1
    current_decision resq 1

section .text
    global RunGame
    ; Project
    extern GameDecision, GetActionCount, GetActionTarget, ReadFileWithCallback, ParseGameData, game_decision_count
    extern ReadActionIndex, getDecisionById
    extern ClearOutput, ResetCursorPosition, WriteText, WriteChar, WriteNumber, SetTextColor, CalculateTextLength, AnimateText
    ; Windows
    extern Sleep

; Runs the game with the file passed via rcx
;   - configures the environment
;   - loads the file
;   - starts the main loop
RunGame:
    ; Proloque
    push rbp
    mov rbp, rsp
    ; Stack frame:
    ; - 8 bytes alignment
    ; -----------------------
    ; => 8
    sub rsp, 16

    mov [game_data], rcx

    call ClearOutput
    call ResetCursorPosition

    call RenderGameIntro

    call ClearOutput
    call ResetCursorPosition

    mov rcx, [game_data]
    call RenderStoryIntro

    mov rcx, [game_data]
    mov edx, dword [rcx+GameData.decision_count]
    mov [game_decision_count], rdx

    mov rdx, [rcx+GameData.decisions]
    mov [current_decision], rdx

; The main game loop
;   - Clears the console
;   - Renders the game header
;   - Renders the current decision and its actions
;   - Awaits the player input
;   - Executes the action
_run_game_loop:
    call ClearOutput
    call ResetCursorPosition

    call RenderGameHeader

    ; Print the current decision text
    mov rcx, [current_decision]
    mov rcx, [rcx + GameDecision.text]
    call AnimateText

    ; Two line breaks
    mov rcx, 10
    call WriteChar
    mov rcx, 10
    call WriteChar

    ; Get the action count of the decision
    mov rcx, [current_decision]
    call GetActionCount

    ; Store the acount count on the stack
    mov [rsp+8], rax

    ; Check whether action count of current decision is 0
    cmp rax, 0x0
    je _end_game_loop
 
    ; Print the current decision
    mov rcx, [current_decision]
    call WriteActions

    ; Await and read the user input
    mov rcx, [rsp+8]
    call ReadActionIndex                  ; selected digit in rax

    ; Validate the input
    cmp rax, [rsp+8]
    jae _invalid_action

    ; Get the address of the follow up decision based on the action
    mov rcx, [game_data]
    mov rdx, [current_decision]
    mov r8, rax
    call GetActionTarget

    ; End the game if the decision does not exist
    test rax, rax
    jz _invalid_decision

    ; Update the current decision
    mov [current_decision], rax

    ; Increment decisions_taken
    inc word [decisions_taken]

    ; Repeat game loop
    jmp _run_game_loop

; Called at the end of the game loop
_end_game_loop:
    ; Clean up the stack allocation for the game loop
    add rsp, 16
    jmp EndGame

; Called when a decision was not found and ends the game with an error
_invalid_decision:
    mov rcx, err_invalid_decision_id
    call WriteText
    jmp EndGame

; Prints an error with the invalid input
_invalid_action:
    mov rcx, err_invalid_action
    call WriteText
    jmp _run_game_loop

; Prints the action texts of a decision
; # Arguments:
;   - rcx = Address of the decision
; # Registers:
;   - r12 = Current action address (after initialization)
;   - r12 = Current action number (index + 1) 
WriteActions:
    ; Save caller-saved registers (windows calling convetion)
    push r12
    push r13

    ; Initialize registers
    mov r12, rcx                                        ; r12 now contains the address of the decision
    add r12, GameDecision.action_0 + GameAction.text    ; Add the offset to the first action and the offset of the action target address to get the text address 

    ; Initialize action counter
    mov r13, 1

_write_actions_loop:
    ; Check that the max action count was not reached yet
    cmp r13, MAX_ACTION_COUNT
    jae _end_write_actions_loop
    
    ; Check whether the text address of the action is valid
    ; If the address is 0x0, there is no further action
    mov rax, [r12]
    test rax, rax
    jz _end_write_actions_loop

    ; Write action to console
    mov rcx, r12
    mov rdx, r13
    call WriteAction

    ; Update current action address by adding the size of a GameAction
    add r12, GameAction_size
    inc r13
    jmp _write_actions_loop

_end_write_actions_loop:
    ; Write line break
    mov rcx, 10
    call WriteChar

    ; Restore caller-saved registers (windows calling convention)
    pop r13
    pop r12

    ret

; Prints a single action
; # Arguments:
;   - rcx = Address of the action
;   - rdx = Action index
WriteAction:
    push rcx

    ; Write action number
    mov rcx, rdx
    call WriteNumber
    ; Write )
    mov rcx, ')'
    call WriteChar
    ; Write space
    mov rcx, ' '
    call WriteChar
    ; Write action text
    pop rcx
    mov rcx, [rcx]
    call AnimateText
    ; Write line break
    mov rcx, 10
    call WriteChar

    ret

; Renders the game end
EndGame:
    call RenderGameEnd
    ret