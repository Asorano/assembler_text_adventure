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
    ERR_MISSING_SEPARATION_LINE db "The sections (metadata and each decision) must be separated by an empty line!", 10, 0
    ERR_ACTION_PARSING_FAILED db "Failed to parse action. Required format: target_decision_id=", 0x22, "action text", 0x22, 10, 0

section .text
    global ParseGameData, FreeGameData

    extern GetProcessHeap, HeapAlloc, HeapFree, SetTextColor
    extern WriteText, WriteNumber, AllocateNextLineOnHeap, SkipEmptyLines, SubString, FindFirstCharInString
    extern log_game_data, log_decision

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
        ; - r10 -  
        ;
        ; - 32 bytes shadow space
        ; -  8 bytes pointer to rawdata             (rsp+32)
        ; -  8 bytes heap handle                    (rsp+40)
        ; -  8 bytes pointer to game data           (rsp+48)       
        ; -  8 bytes decision count                 (rsp+56)
        ; -  8 bytes pointer to current item        (rsp+64)
        ; -  8 bytes pointer to current line        (rsp+72)
        ; -  8 bytes current line length            (rsp+80)
        ; -  8 bytes index of = in decision header  (rsp+88)
        ; ----------------------------------------------
        ; => 96 bytes
        sub rsp, 96

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

        mov [rsp+32], rdx   ; Save current position in stack frame

        ; =================================================================
        ; Parse decisions
    _parse_decision:
        ; Empty line
        mov rcx, [rsp+32]
        call SkipEmptyLines

        test rax, rax
        jz _finalize_parsing

        mov [rsp+72], rdx

        ; Parse decision with current line
        mov rcx, [rsp+40]
        mov rdx, [rsp+72]
        call ParseDecision

        ; Allocate the next linked list item
        ; mov rcx, [rsp+40]
        ; mov rdx, 8                          ; flags (HEAP_ZERO_MEMORY = 8)
        ; mov r8, LinkedListItem_size     ; Size
        ; call HeapAlloc

        ; test rax, rax
        ; jz _err_heap_alloc

        ; mov rcx, [rsp+64]
        ; mov [rax + LinkedListItem.next], rcx
        ; mov [rsp+64], rax
        
        ; ; Check that it starts with [
        ; mov  cl, byte [rax]
        ; cmp  cl, '['
        ; jne _err_decision_header

        ; ; Check that it ends with "]
        ; add rax, r8     ; Add the length of the line from AllocateNextLineOnHeap to rax to get the last character
        ; dec rax
        ; mov  cl, byte [rax]
        ; cmp  cl, ']'
        ; jne _err_decision_header

        ; dec rax
        ; mov  cl, byte [rax]
        ; cmp  cl, 0x22
        ; jne _err_decision_header

        ; ; Extract position of =
        ; mov rcx, [rsp+72] ; +16 because of the two values pushed
        ; mov rdx, '='
        ; call FindFirstCharInString

        ; ; Check that the = exists
        ; cmp rax, -1
        ; je _err_decision_header

        ; mov [rsp+88], rax

        ; mov rcx, [rsp+72]
        ; add rcx, rax
        ; inc rcx
        ; mov  cl, byte [rcx]
        ; cmp cl, 0x22
        ; jne _err_decision_header



        ; --------------------------------
        ; --- Parse Actions
        ; --------------------------------
        mov rcx, [rsp+40]
        mov rdx, [rsp+32]
        call ParseAction

        cmp rax, -1
        je _err_action_parsing

        ; Increment decision count
        inc byte [rsp+56]

        ; Loop
        jmp _parse_decision
 
        ; =================================================================

    _finalize_parsing:
        ; Set decision count in game data
        mov rdx, [rsp+56]   ; Load decision count
        mov rcx, [rsp + 48]
        mov [rcx + GameData.decision_count], rdx

        mov rdx, [rsp+64]
        mov [rcx + GameData.decisions], rdx

        ; Log decisions
        mov rcx, [rsp+48]
        mov rdx, qword 1
        call log_game_data

    _end_parsing:
        ; Free TEMP data
        ; Free current line
        mov rcx, [rsp+40]
        xor rdx, rdx
        mov r8, [rsp+72]
        call HeapFree

        mov rax, [rsp+48]   ; Load the game data pointer as result

        ; Epilogue
        add rsp, 96
        pop rbp
        ret

    _err_decision_header:
        HANDLE_ERROR ERR_INVALID_DECISION_HEADER

    _err_heap_alloc:
        HANDLE_ERROR ERR_MISSING_SEPARATION_LINE

    _err_missing_separation_line:
        HANDLE_ERROR ERR_HEAP_ALLOC

    _err_action_parsing:
        HANDLE_ERROR ERR_ACTION_PARSING_FAILED

    ; Parses a decision with id, text and actions and returns its heap address 
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to raw data
    ; - [out]   rax = heap pointer to the decision or NULL
    ParseDecision:
        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle                (rsp+32)
        ; -  8 bytes pointer to raw data        (rsp+40)
        ; -  8 bytes pointer to current line    (rsp+48)
        ; -  8 bytes length of the current line (rsp+56)
        ; -  8 bytes index of =                 (rsp+64)
        ; -  8 bytes pointer to decision        (rsp+72)
        ; ------------------------------
        ; => 80 bytes
        sub rsp, 80

        mov [rsp+32], rcx
        mov [rsp+40], rdx

        ; Allocate decision header line
        mov rcx, [rsp+32]
        call AllocateNextLineOnHeap
        mov [rsp+48], rax
        mov [rsp+40], rdx
        mov [rsp+56], r8

        ; Check that the string has at least 7 characters including at least one char for id: [a="b"]
        cmp r8, 0x7
        jl _fail_parse_decision

        ; Check that it starts with [
        mov  cl, byte [rax]
        cmp  cl, '['
        jne _fail_parse_decision

        ; Check that it ends with "]
        add rax, r8     ; Add the length of the line from AllocateNextLineOnHeap to rax to get the last character
        dec rax
        mov  cl, byte [rax]
        cmp  cl, ']'
        jne _fail_parse_decision

        dec rax
        mov  cl, byte [rax]
        cmp  cl, 0x22
        jne _fail_parse_decision

        ; Find index of =
        ; If it does not exist, fail
        mov rcx, [rsp+48]
        mov rdx, '='
        call FindFirstCharInString

        ; Check that the = exists
        cmp rax, -1
        je _fail_parse_decision

        ; Check that there is a " behind =
        mov rcx, [rsp+48]
        add rcx, rax
        inc rcx
        mov cl, byte [rcx]
        cmp cl, 0x22
        jne _fail_parse_decision

        ; Save the index in the stack frame
        mov [rsp+64], rax

        ; The data has been validated and allocated and now the actual GameDecision can be allocated.
        mov rcx, [rsp+32]
        mov rdx, 8                          ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, GameDecision_size     ; Size
        call HeapAlloc

        test rax, rax
        jz _fail_parse_decision

        mov [rsp+72], rax

        ; Extract and set id
        mov rcx, [rsp+32]   ; Heap handle
        mov rdx, [rsp+48]   ; Pointer to current line
        mov  r8, 1          ; Start Index => 1 to skip the [
        mov  r9, [rsp+56]   ; Count => Index of =
        dec  r9             ; Exclude = from the id
        call SubString

        mov rcx, [rsp+72]
        mov [rcx + GameDecision.id], rax

        ; Extract and set text
        mov rcx, [rsp+32]   ; Heap handle
        mov rdx, [rsp+48]   ; Pointer to current line

        ; Start index
        mov  r8, [rsp+64]   ; set the start index to the index of =
        add  r8, qword 2    ; Exclude =" from the text
        ; Count
        mov  r9, [rsp+56]
        sub  r9, r8         ; Substract the index of = from
        sub  r9, qword 2    ; Exclude "] from the text      
        call SubString

        mov rcx, [rsp+72]
        mov [rcx + GameDecision.text], rax

    _end_parse_decision:
        ; Free the header line
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov r8, [rsp+48]
        call HeapFree

        ; Load address of decision which can be NULL
        mov rax, [rsp+72]

        ; Epiloque
        add rsp, 80
        pop rbp
        ret

    _fail_parse_decision:
        mov qword [rsp+64], 0
        jmp _end_parse_decision

    ; Parses a GameAction
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to raw data
    ; - [out]   rax = pointer to heap of parsed action OR NULL if there is none to parse OR -1 if the parsing failed
    ; - [out]   rdx = new pointer to raw data
    ParseAction:
        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle                (rsp+32)
        ; -  8 bytes pointer to raw data        (rsp+40)
        ; -  8 bytes pointer to action on heap  (rsp+48)
        ; -  8 bytes pointer to extracted line  (rsp+56)
        ; -  8 bytes line length                (rsp+64)
        ; -  8 bytes index of = in line         (rsp+72)
        ; ----------------------------------------------
        ; => 80 bytes
        sub rsp, 80

        mov [rsp+32], rcx
        mov [rsp+40], rdx

        ; Allocate line of text
        call AllocateNextLineOnHeap
        mov [rsp+56], rax
        mov [rsp+40], rdx
        mov [rsp+64], r8

        test rax, rax
        jz _fail_parse_action

        ; Check that the line ends with "
        mov rcx, rax
        add rcx,  r8
        dec rcx
        movzx rcx, byte [rcx]
        cmp  cl, 0x22
        jne _fail_parse_action

        ; Check that the line contains a =
        mov rcx, rax
        mov rdx, '='
        call FindFirstCharInString

        cmp rax, -1
        jz _fail_parse_action

        mov [rsp+72], rax

        ; Check that the char after = is "
        mov rcx, [rsp+56]
        add rcx, rax
        inc rcx
        movzx rcx, byte [rcx]
        cmp  cl, 0x22
        jne _fail_parse_action

        mov rcx, [rsp+32]           ; Heap handle
        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, GameAction_size     ; Size
        call HeapAlloc
        ; Check allocation
        test rax, rax
        jz _fail_parse_action
        ; Put the heap address on the stack
        mov [rsp+48], rax           

        ; Extract text
        mov rcx, [rsp+32]           ; Heap handle
        mov rdx, [rsp+56]           ; Pointer to string
        mov  r8, [rsp+72]           ; Index of =
        add  r8, 2                  ; Exclude ="
        mov  r9, [rsp+64]           ; Length of line
        sub  r9, r8
        dec  r9                     ; Exclude " at the end
        call SubString

        ; Set text of action
        mov rcx, [rsp+48]
        mov [rcx + GameAction.text], rax

        ; Extract id
        mov rcx, [rsp+32]           ; Heap handle
        mov rdx, [rsp+56]           ; Pointer to string
        mov  r8, 0                  ; Index of =
        mov  r9, [rsp+72]           ; Length of line
        sub  r9, r8
        call SubString     

        ; Set id of action
        mov rcx, [rsp+48]
        mov [rcx + GameAction.linked_decision], rax 

    _end_parse_action:
        ; Free line memory
        mov rcx, [rsp+32]
        xor rdx, rdx
        mov  r8, [rsp+56]
        call HeapFree
        
        mov rax, [rsp+48]
        mov rdx, [rsp+40]

        ; Epiloque
        add rsp, 80
        pop rbp
        ret

    _fail_parse_action:
        mov qword [rsp+48], -1
        jmp _end_parse_action