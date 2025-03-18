default rel
BITS 64

%include "data.inc"

section .data
    GAME_DECISION_BUFFER_SIZE equ 1048576     ; 1MB
    GAME_TEXT_BUFFER_SIZE equ 1048576     ; 1MB

section .bss
    game_decision_count resw 1
    game_decision_buffer resb GAME_DECISION_BUFFER_SIZE  ; 1MB buffer
    game_text_buffer resb GAME_TEXT_BUFFER_SIZE  ; 1MB buffer

section .text
    ; Global data
    global game_decision_count
    global game_decision_buffer
    global game_text_buffer

    ; Global functions
    global GetGameDecisionByIndex, FindGameDecisionById, GetActionCount, GetActionTarget

    ; Imported functions
    extern strcmp, WriteText, WriteChar

    GetActionTarget:
        ; rcx => decision address
        ; rdx => action index
        ; rax = returns action target decision address

        ; Get the id of the target decision of the action
        add rcx, GameDecision.action_0
        imul rdx, GameAction_size
        add rcx, rdx

        call FindGameDecisionById
        ret

    GetGameDecisionByIndex:
        ; rcx = decision index

        ; Check that the index is at least 0
        cmp rcx, 0
        jl _invalid_decision_index

        movzx rax, word [game_decision_count]

        cmp rax, rcx
        jle _invalid_decision_index

        mov rax, GameDecision_size
        imul rax, rcx
        lea rcx, [game_decision_buffer]
        add rax, qword rcx

    _return_decision_by_index:
        ret

    _invalid_decision_index:
        xor rax, rax
        jmp _return_decision_by_index

    GetActionCount:
        ; Arguments:
        ; - rcx = decision address
        ;
        ; Registers:
        ; - rax = counter
        ; - rdx = action address

        add rcx, GameDecision.action_0
        xor rax, rax

    _get_action_count_loop:
        cmp rax, MAX_ACTION_COUNT
        jge _return_action_count

        mov rdx, [rcx]
        test rdx, rdx
        jz _return_action_count

        inc rax

        add rcx, GameAction_size
        jmp _get_action_count_loop

    _return_action_count:
        ret

    FindGameDecisionById:
        ; Arguments:
        ; - rcx = decision id
        ;
        ; Registers:
        ; - r12 = decision id (saved)
        ; - r13 = remaining decision loop count
        ; - r14 = current decision buffer address
        ;
        ; Returns in rax:
        ;   = 0 => decision not found
        ;   > 0 => address of decision
        ;
        ; Iterates over the decision buffer and tries to find a decision which has the passed decision id

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

        ; Call the c string comparison function
        push rbp
        sub rsp, 32
        mov rcx, [r14]
        call WriteText

        mov rcx, 10
        call WriteChar

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
        pop r14
        pop r13
        pop r12
        ret