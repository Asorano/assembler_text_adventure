default rel

%include "data.inc"

%macro FREE_DECISION_ACTION 1
        mov r8, [rsp+40]
        mov rcx, [r8 + GameDecision.action_%1]
        call FreeGameAction
%endmacro

section .text
    global FreeGameAction, FreeGameDecision, FreeGameData

    extern GetProcessHeap, HeapAlloc, HeapFree

    ; Frees the memory of a GameAction
    ; # Arguments
    ; - [in]    rcx = pointer to action
    FreeGameAction:
        test rcx, rcx
        jz _ret_free_action

        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle        (rsp+32)
        ; -  8 bytes pointer to action  (rsp+40)
        ; --------------------------------------
        ; => 48 bytes
        sub rsp, 48
        mov [rsp+40], rcx

        call GetProcessHeap
        mov [rsp+32], rax

        ; Free linked decision id
        mov rcx, rax
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameAction.linked_decision]
        call HeapFree

        ; Free text
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameAction.text]
        call HeapFree

        ; Free action
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+40]
        call HeapFree

        ; Epiloque
        add rsp, 48
        pop rbp

    _ret_free_action:
        ret

    ; Frees the memory of a GameDecision
    ; # Arguments
    ; - [in]    rcx = pointer to action
    FreeGameDecision:
        test rcx, rcx
        jz _ret_free_decision

        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle            (rsp+32)
        ; -  8 bytes pointer to decision    (rsp+40)
        ; --------------------------------------
        ; => 48 bytes
        sub rsp, 48
        mov [rsp+40], rcx

        call GetProcessHeap
        mov [rsp+32], rax

        ; Free id
        mov rcx, rax
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameDecision.id]
        call HeapFree

        ; Free text
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameDecision.text]
        call HeapFree

        ; Free actions
        FREE_DECISION_ACTION 0
        FREE_DECISION_ACTION 1
        FREE_DECISION_ACTION 2
        FREE_DECISION_ACTION 3

        ; Free decision
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+40]
        call HeapFree

        ; Epiloque
        add rsp, 48
        pop rbp

    _ret_free_decision:
        ret



    ; Frees the decisions and metadata and the game data struct from the heap
    ; # Arguments
    ; - [in]    rcx = pointer to game data struct
    FreeGameData:
        ; Prologue
        push rbp
        mov rbp, rsp
        ; Stack frame
        ; - 32 bytes shadow space
        ; -----------------------
        ; => 32 bytes
        sub rsp, 32

        mov r12, rcx

        call GetProcessHeap
        mov r13, rax

        ; Free title
        mov rcx, r13
        xor rdx, rdx
        mov r8, [r12 + GameData.title]
        call HeapFree

        ; Free author
        mov rcx, r13
        xor rdx, rdx
        mov r8, [r12 + GameData.author]
        call HeapFree

        ; TODO: Free linked list

        ; Free game data
        mov rcx, r13
        xor rdx, rdx
        mov  r8, r12
        call HeapFree

        ; Epiloque
        add rsp, 32
        pop rbp
        ret
