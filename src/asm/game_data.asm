default rel
BITS 64

%include "data.inc"

; Currently the content of the file and the runtime data are stored in 1MB buffers
section .data
    ; Size of the buffer for the runtime data
    GAME_DECISION_BUFFER_SIZE equ 1048576   ; 1MB
    ; Size of the buffer for the file content
    GAME_TEXT_BUFFER_SIZE equ 1048576       ; 1MB

section .bss
    ; Total decision count as word
    game_decision_count resw 1
    ; Buffer for runtime data
    game_decision_buffer resb GAME_DECISION_BUFFER_SIZE  ; 1MB buffer
    ; Buffer for file content
    game_text_buffer resb GAME_TEXT_BUFFER_SIZE  ; 1MB buffer

section .text
    ; Global data
    global game_decision_count
    global game_decision_buffer
    global game_text_buffer

    ; Global functions
    global GetGameDecisionByIndex, FindGameDecisionById, GetActionCount, GetActionTarget

    ; Imported functions
    extern strcmp

    ; Returns the address of the decision of the action if available
    ; # Arguments:
    ;   - rcx => decision address
    ;   - rdx => action index
    ; # Returns:
    ;   - rax = action target decision address or 0x0
    GetActionTarget:
        ; Get the id of the target decision of the action
        ; Add the offset of the first action of an decision to the decision address
        add rcx, GameDecision.action_0
        ; Multiply the size of an action in memory with the action index
        imul rdx, GameAction_size
        ; Calculate the address of the id of the linked decision
        add rcx, rdx
        ; Find the decision, result is placed in rax
        call FindGameDecisionById
        ret

    ; Returns the address of a decision by index in the buffer
    ; # Arguments:
    ;   - rcx = decision index
    GetGameDecisionByIndex:
        ; Check that the index is at least 0
        cmp rcx, 0
        jl _invalid_decision_index

        ; Load the total decision count
        movzx rax, word [game_decision_count]

        ; Verify that the index is lower than the max count
        cmp rax, rcx
        jle _invalid_decision_index

        ; Use the size of a whole decision struct and multiply it with the index
        mov rax, GameDecision_size
        imul rax, rcx
        ; Load the start address of the buffer
        lea rcx, [game_decision_buffer]
        ; Add the total offset
        add rax, qword rcx
        ret

    ; If the index is invalid, set rax to null and return
    _invalid_decision_index:
        xor rax, rax
        ret

    ; # Arguments:
    ;   - rcx = decision address
    ; # Registers:
    ;   - rax = counter
    ;   - rdx = action address
    GetActionCount:
        ; Add the offset of the first action to the decision address
        add rcx, GameDecision.action_0
        ; Set rax to 0
        xor rax, rax

    _get_action_count_loop:
        ; Check that the index is below the max action count
        cmp rax, MAX_ACTION_COUNT
        jge _return_action_count

        ; Check whether the target decision address of the current address is not 0x0
        mov rdx, [rcx]
        test rdx, rdx
        jz _return_action_count

        ; Increment the counter
        inc rax

        ; Add the offset to the next action
        add rcx, GameAction_size
        jmp _get_action_count_loop

    _return_action_count:
        ret

    ; Iterates over the decision buffer and tries to find a decision which has the passed decision id
    ; # Arguments:
    ;   - rcx = decision id
    ;
    ; # Registers:
    ;   - r12 = decision id (saved)
    ;   - r13 = remaining decision loop count
    ;   - r14 = current decision buffer address
    ;
    ; Returns in rax:
    ;   = 0 => decision not found
    ;   > 0 => address of decision
    ;
    FindGameDecisionById:
        ; Save caller-saved registers
        push r12
        push r13
        push r14

        mov r12, rcx                            ; Move decision id
        movzx r13, word [game_decision_count]   ; Move decision count
        lea r14, [game_decision_buffer]         ; Lead first decision address

    _find_decision_loop:
        ; Check that there are remaining decisions in the buffer
        cmp r13, 0
        je _decision_not_found

        ; Compare the searched id and the id of the current decision
        ; Call the c string comparison function
        push rbp
        sub rsp, 32
        mov rcx, [r12]
        mov rdx, [r14]
        call strcmp
        add rsp, 32
        pop rbp

        ; Check compare result. If 0, the decision has been found
        cmp rax, 0
        je _end_decision_search

        ; Prepare the registers for the next decision in the buffer
        dec qword r13
        add r14, GameDecision_size
        jmp _find_decision_loop

    ; End the search sucessfully
    _end_decision_search:
        mov rax, r14
        jmp _end_search
    ; End the search without a found decision
    _decision_not_found:
        xor rax, rax
        
    _end_search:
        ; Restore caller-saved registers
        pop r14
        pop r13
        pop r12
        ret