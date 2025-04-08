struc GameAction
    .linked_decision    resq 1  ; Pointer to linked decision
    .text               resq 1  ; Pointer to text   
endstruc

struc GameDecision 
    .id:        resq 1  ; Pointer to id string
    .text:      resq 1  ; Pointer to text string
    .action_0   resq 1  ; Pointer to first action
    .action_1   resq 1  ; Pointer to second action
    .action_2   resq 1  ; Pointer to third action
    .action_3   resq 1  ; Pointer to fourth action
endstruc

struc GameData
    .title              resq 1  ; Pointer to title text
    .author             resq 1  ; Pointer to autor
    .decision_count     resq 1  ; Int
    .decisions          resq 1  ; Pointer to first decision
endstruc

section .data
    MAX_ACTION_COUNT equ 4