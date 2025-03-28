default rel
BITS 64

%include "data.inc"

section .text
    ; Global functions
    global GetActionCount, GetActionTarget

    ; Imported functions
    extern strcmp

    ; Returns the address of the decision of the action if available
    ; # Arguments:
    ; - [in]    rcx = pointer to game data
    ; - [in]    rdx = pointer to decision
    ; - [in]     r8 = action index
    ; # Returns:
    ;   - rax = action target decision address or 0x0
    GetActionTarget:
        push rbp
        mov rbp, rsp
        sub rsp, 32
        ; Get the id of the target decision of the action
        ; Add the offset of the first action of an decision to the decision address
        add rdx, GameDecision.action_0
        ; Multiply the size of an action in memory with the action index
        imul r8, GameAction_size
        ; Calculate the address of the id of the linked decision
        add rdx, r8
        mov rdx, [rdx]
        ; Find the decision, result is placed in rax

        call FindGameDecisionById

        add rsp, 32
        pop rbp
        ret

    ; # Arguments:
    ; - [in]    rcx = Pointer to decision
    ; - [out]   rax = action count
    ; # Registers:
    ; - rax = counter
    ; - rdx = action address
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
    ; - [in]    rcx = pointer to game data
    ; - [in]    rdx = pointer to decision id
    ; - [out]   rax = pointer to decision or NULL
    ;
    ; # Registers:
    ; - r12 = decision id (saved)
    ; - r13 = remaining decision loop count
    ; - r14 = current decision buffer address
    FindGameDecisionById:
        ; Prologue
        push rbp
        mov rbp, rsp
        
        push r12
        push r13
        push r14

        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  6 bytes alignment
        ; -------------------
        ; => 40 bytes
        sub rsp, 40

        mov r12, rdx                            ; Move decision id
        movzx r13, word [rcx + GameData.decision_count]   ; Move decision count
        mov r14, [rcx + GameData.decisions]       ; Load first decision address

    _find_decision_loop:
        ; Check that there are remaining decisions in the buffer
        cmp r13, 0
        je _decision_not_found

        ; Compare the searched id and the id of the current decision
        ; Call the c string comparison function
        mov rcx, r12
        mov rdx, [r14]
        call strcmp

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
        ; Epiloque
        add rsp, 40
        pop r14
        pop r13
        pop r12
        pop rbp
        ret