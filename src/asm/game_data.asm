default rel
BITS 64

struc GameAction
    .linked_decision    resq 1  ; Pointer to linked decision
    .text               resq 1  ; Pointer to text   
endstruc

struc GameDecision 
    .id:        resq 1  ; Pointer to id string
    .text:      resq 1  ; Pointer to text string
    .action_0   resb GameAction_size  ; Pointer to first action
    .action_1   resb GameAction_size  ; Pointer to second action
    .action_2   resb GameAction_size  ; Pointer to third action
    .action_3   resb GameAction_size  ; Pointer to fourth action
endstruc

section .data
    GAME_DECISION_BUFFER_SIZE equ 1048576     ; 1MB
    GAME_TEXT_BUFFER_SIZE equ 1048576     ; 1MB

section .bss
    game_decision_count resw 1
    game_decision_buffer resb GAME_DECISION_BUFFER_SIZE  ; 1MB buffer
    game_text_buffer resb GAME_TEXT_BUFFER_SIZE  ; 1MB buffer

section .text
    global GameAction_size
    global game_decision_count
    global game_decision_buffer
    global game_text_buffer

    global GetGameDecisionByIndex

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
        mov rax, qword 0
        jmp _return_decision_by_index