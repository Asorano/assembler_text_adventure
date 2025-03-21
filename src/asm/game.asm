; A simple text adventure in x64 assembler
default rel

%include "input.inc"
%include "view.inc"
%include "animations.inc"
%include "text.inc"
%include "data.inc"

section .data    
    file_name db FILE_NAME, 0
    decisions_taken dq 0

section .bss
    current_decision resq 1

section .text
    global main
    ; Project
    extern GameDecision, GetActionCount, GetActionTarget, ReadFileWithCallback, ParseGameData
    extern SetupOutput, ClearOutput, ResetCursorPosition, WriteText, WriteChar, WriteNumber, SetTextColor, CalculateTextLength
    ; Windows
    extern Sleep, ExitProcess

; Initial game method which
;   - configures the environment
;   - loads the file
;   - starts the main loop
main:
    call SetupInput
    call SetupOutput

    call ClearOutput
    call ResetCursorPosition

    mov rcx, file_name
    mov rdx, ParseGameData
    call ReadFileWithCallback

    ; Exit if the loading failed
    test rax, rax
    jz _exit

    ; Initialize initial decision
    mov [current_decision], rax

    ; Delay
    mov rcx, 250
    sub rsp, 32
    call Sleep
    add rsp, 32

    call RenderGameIntro

    ; The game loop requires one qword for the action count of the current decision
    ; To keep the stack 16-byte aligned, 16 bytes instead of 8 are allocated
    ; The space is allocated only once instead of everytime
    sub rsp, 16

; The main game loop
;   - Clears the console
;   - Renders the game header
;   - Renders the current decision and its actions
;   - Awaits the player input
;   - Executes the action
game_loop:
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
    mov rcx, [current_decision]
    mov rdx, rax
    call GetActionTarget

    ; End the game if the decision does not exist
    test rax, rax
    jz _invalid_decision

    ; Update the current decision
    mov [current_decision], rax

    ; Increment decisions_taken
    inc word [decisions_taken]

    ; Repeat game loop
    jmp game_loop

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
    jmp game_loop

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
; Exits the process
_exit:
    ; The main function is called and the previous address is put on the stack
    ; That's why 40 bytes must be added to have a proper 16-byte alignment on the stack instead of 32
    sub rsp, 40
    xor ecx, ecx
    call ExitProcess
    add rsp, 40