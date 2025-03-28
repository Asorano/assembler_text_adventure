; A simple text adventure in x64 assembler
default rel

%include "data.inc"

section .data    
    err_invalid_action: db "Impossible!", 10, 10, 0
    err_invalid_decision_id: db "A glitch in the space-time continuum has been detected!", 10, "All memories have been erased for safety reasons.", 10, "(The selected action was not properly connected to a decision)", 10, 0
    msg_total_decisions_taken db " decisions survived: ", 0

section .bss
    game_data resq 1
    current_decision resq 1
    decisions_taken resq 0

section .text
    global RunGame
    ; Project
    extern GameDecision, GetActionCount, GetActionTarget, ReadFileWithCallback, ParseGameData, game_decision_count
    extern ReadActionIndex, getDecisionById
    extern ClearOutput, ResetCursorPosition, WriteText, WriteChar, WriteNumber, SetTextColor, CalculateTextLength, AnimateText
    extern RenderStoryIntro, RenderGameIntro, RenderGameHeader, RenderGameEnd, RenderDecision
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

    mov rcx, [decisions_taken]
    call RenderGameHeader

    ; Print the current decision text
    mov rcx, [current_decision]
    call RenderDecision

    ; Get the action count of the decision
    mov rcx, [current_decision]
    call GetActionCount

    ; Store the acount count on the stack
    mov [rsp+8], rax

    ; Check whether action count of current decision is 0
    cmp rax, 0x0
    je _end_game_loop

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
    call RenderGameEnd
    add rsp, 16
    pop rbp
    ret

; Called when a decision was not found and ends the game with an error
_invalid_decision:
    mov rcx, err_invalid_decision_id
    call AnimateText
    jmp _end_game_loop

; Prints an error with the invalid input
_invalid_action:
    mov rcx, err_invalid_action
    call AnimateText
    jmp _run_game_loop