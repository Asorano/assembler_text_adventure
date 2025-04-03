default rel

%include "data.inc"

%macro PRINT_ERROR 1
    mov rcx, 0x4
    call SetTextColor

    mov rcx, ERR_PARSING_FAILED
    call WriteText

    mov rcx, %1
    call WriteText

    mov rcx, 0x7
    call SetTextColor
%endmacro

section .data
    ERR_HEAP_ALLOC db "Failed to allocate on the heap.", 10, 0
    ERR_PARSING_FAILED db "Story file corrupted:", 10, 0
    ERR_MISSING_METDATA_SEPARATION db "The metadata must be separated from the decisions with at least one empty line!", 10, 0

section .bss
    mock resb DecisionLinkedList

section .text
    global ParseGameData

    extern GetProcessHeap, HeapAlloc, HeapFree, SetTextColor
    extern WriteText, WriteNumber, AllocateNextLineOnHeap, SkipEmptyLines

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

    ; # Arguments 
    ; - [in] pointer to game data string
    ;
    ; # Loop
    ; - Check whether there is a next decision (also for the first one)
    ; - Allocate decision linked list item on the heap
    ; - Assign previous decision pointer to new item
    ; - Store pointer to new item in the stack frame
    ;
    ; - Decision id
    ;   - Parse id
    ;   - Allocate space on heap
    ;   - Assign pointer to current decision
    ;   - Copy id to heap
    ; - Decision text
    ;   - Parse text
    ;   - Allocate space on heap
    ;   - Assign pointer to current decision
    ;   - Copy text to heap
    ; - Parse action loop
    ;   - Parse target id
    ;   - Allocate space on heap
    ;   - Assign pointer to current action target of current decision
    ;   - Parse action text
    ;   - Allocate space on heap
    ;   - Assign pointer to current action text of current decision
    ;   - Jump to next action
    ; - Repeat
    ;
    ; # End
    ; - return pointer to last decision from the stack frame (if there was no decision, the pointer is NULL)
    ;   (The linked list of decisions is reversed)
    ParseGameData:
        ; Prologue
        push rbp
        mov rbp, rsp
        ; Stack frame
        ; - 32 bytes shadow space
        ; -  8 bytes pointer to rawdata         (rsp+32)
        ; -  8 bytes heap handle                (rsp+40)
        ; -  8 bytes pointer to game data       (rsp+48)       
        ; -  8 bytes decision count             (rsp+56)
        sub rsp, 64

        mov qword [rsp+32], rcx ; Save data pointer in stack frame
        mov qword [rsp+48], 0   ; Ensure that the pointer to the linked list is NULL
        mov byte [rsp+56], 0    ; Ensure that the count is zero

        call GetProcessHeap
        mov [rsp+40], rax

        ; Allocate game data structure
        mov rcx, rax
        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, GameData_size
        call HeapAlloc
        mov [rsp+48], rax

        ; Metadata: Title
        mov rcx, [rsp+40]        ; Heap handle
        mov rdx, [rsp+32]   ; Pointer to data
        call AllocateNextLineOnHeap
        mov  r8, [rsp+48]
        mov [r8], rax

        ; Metadata: Title
        mov rcx, [rsp+40]
        ; rdx already contains the pointer to the next line
        call AllocateNextLineOnHeap
        mov  r8, [rsp+48]
        mov [r8 + GameData.author], rax

        ; Empty line
        mov rcx, rdx
        call SkipEmptyLines

        test rax, rax
        jz _err_missing_metadata_separation

        ; mov rcx, rax
        ; call WriteNumber

    ; _parse_decision:
    ;     ; Allocate the next linked list item
    ;     mov rcx, [rsp+32]
    ;     mov rdx, 8                          ; flags (HEAP_ZERO_MEMORY = 8)
    ;     mov r8, DecisionLinkedList_size     ; Size
    ;     call HeapAlloc
        
    ;     ; Check that the 
    ;     test rax, rax
    ;     jz _parse_game_data_heap_alloc_failed

    ;     mov rcx, [rsp+40]                   ; Load pointer to previous item
    ;     mov [rax + DecisionLinkedList.next], rcx

    ;     mov [rsp+40], rax

    ;     inc byte [rsp+48]

    ;     jmp _parse_decision

    ; _parse_game_data_heap_alloc_failed:
    ;     lea rcx, [ERR_HEAP_ALLOC]
    ;     call WriteText
        

        mov rax, [rsp+48] ; Load the address of the last linked list item, can be NULL
    _end_parsing:

        ; Epilogue
        add rsp, 64
        pop rbp
        ret

    _err_missing_metadata_separation:
        PRINT_ERROR ERR_MISSING_METDATA_SEPARATION

        mov rcx, [rsp+48]
        call FreeGameData

        mov rax, 0
        jmp _end_parsing