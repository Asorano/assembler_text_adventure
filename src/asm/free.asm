default rel

%include "data.inc"

section .text
    global FreeGameAction, FreeGameDecision, FreeGameData

    extern GetProcessHeap, HeapAlloc, HeapFree

    ; Frees the memory of an GameAction
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

        mov rcx, rax
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameAction.linked_decision]
        call HeapFree

        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+40]
        mov r8, [r8 + GameAction.text]
        call HeapFree

    _end_free_action:
        add rsp, 48
        pop rbp

    _ret_free_action:
        ret


    FreeGameDecision:
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

        ; Free game data
        mov rcx, r13
        xor rdx, rdx
        mov  r8, r12
        call HeapFree

        ; Epiloque
        add rsp, 32
        pop rbp
        ret
