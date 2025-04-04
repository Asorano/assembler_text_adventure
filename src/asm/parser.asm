default rel

%include "data.inc"

%macro HANDLE_ERROR 1
    ; Print the error
    mov rcx, 0x4
    call SetTextColor

    mov rcx, ERR_PARSING_FAILED
    call WriteText

    mov rcx, %1
    call WriteText

    mov rcx, 0x7
    call SetTextColor

    ; Free game data
    mov rcx, [rsp+48]
    call FreeGameData

    ; Set result
    mov qword [rsp+48], 0
    jmp _end_parsing
%endmacro

section .data
    ERR_HEAP_ALLOC db "Failed to allocate on the heap.", 10, 0
    ERR_PARSING_FAILED db "Story file corrupted:", 10, 0
    ERR_INVALID_DECISION_HEADER db "Invalid decision header. Required is: [decision_id=", 0x22, "text", 0x22, "]", 10, 0
    ERR_MISSING_METDATA_SEPARATION db "The metadata must be separated from the decisions with at least one empty line!", 10, 0

section .bss
    mock resb DecisionLinkedList

section .text
    global ParseGameData, FreeGameData

    extern GetProcessHeap, HeapAlloc, HeapFree, SetTextColor
    extern WriteText, WriteNumber, AllocateNextLineOnHeap, SkipEmptyLines, SubString, FindFirstCharInString

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
        ; -  8 bytes pointer to current item    (rsp+64)
        ; -  8 bytes pointer to current line    (rsp+72)
        ; ----------------------------------------------
        ; => 80 bytes
        sub rsp, 80

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

        mov [rsp+32], rdx   ; Save current position in stack frame

        ; Parse decisions
    _parse_decision:
        ; Allocate the next linked list item
        mov rcx, [rsp+40]
        mov rdx, 8                          ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, DecisionLinkedList_size     ; Size
        call HeapAlloc

        test rax, rax
        jz _err_heap_alloc

        mov rcx, [rsp+64]
        mov [rax + DecisionLinkedList.next], rcx
        mov [rsp+64], rax

        ; Allocate decision header line
        mov rcx, [rsp+40]
        mov rdx, [rsp+32]
        call AllocateNextLineOnHeap
        mov [rsp+72], rax
        
        ; Check that it starts with [
        mov  cl, byte [rax]
        cmp  cl, '['
        jne _err_decision_header

        ; Check that it ends with "]
        add rax, r8     ; Add the length of the line from AllocateNextLineOnHeap to rax to get the last character
        mov  cl, byte [rax]
        cmp  cl, ']'
        jne _err_decision_header

        dec rax
        mov  cl, byte [rax]
        cmp  cl, 0x22
        jne _err_decision_header

        ; Extract position of =
        mov rcx, [rsp+72]
        mov rdx, '='
        call FindFirstCharInString

        ; Check that the = exists
        cmp rax, -1
        je _err_decision_header

        mov rcx, [rsp+72]
        add rcx, rax
        inc rcx
        mov  cl, byte [rcx]
        cmp cl, 0x22
        jne _err_decision_header

        ; Check that the char behind = is "
        dec rax     ; Decrement because the [ must be ignored

        mov rcx, [rsp+40]
        mov rdx, [rsp+72]
        mov  r8, 1
        mov  r9, rax
        call SubString

        mov rcx, [rsp+64]
        mov [rcx + DecisionLinkedList.decision + GameDecision.id], rax

        ; Increment decision count
        inc byte [rsp+56]

    ;     jmp _parse_decision

    ; _parse_game_data_heap_alloc_failed:
    ;     lea rcx, [ERR_HEAP_ALLOC]
    ;     call WriteText
        
        ; Set decision count in game data
        mov rdx, [rsp+56]   ; Load decision count
        mov rcx, [rsp + 48]
        mov [rcx + GameData.decision_count], rdx

        mov rdx, [rsp+64]
        mov [rcx + GameData.decisions], rdx

    _end_parsing:
        ; Free TEMP data
        ; Free current line
        mov rcx, [rsp+40]
        xor rdx, rdx
        mov r8, [rsp+72]
        call HeapFree

        mov rax, [rsp+48]   ; Load the game data pointer as result

        ; Epilogue
        add rsp, 80
        pop rbp
        ret

    _err_decision_header:
        HANDLE_ERROR ERR_INVALID_DECISION_HEADER

    _err_heap_alloc:
        HANDLE_ERROR ERR_MISSING_METDATA_SEPARATION

    _err_missing_metadata_separation:
        HANDLE_ERROR ERR_HEAP_ALLOC