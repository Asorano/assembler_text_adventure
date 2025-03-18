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
    MAX_ACTION_COUNT equ 4