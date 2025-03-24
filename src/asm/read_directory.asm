default rel

section .data
    FIND_DATA_STRUCT_SIZE equ 592

section .text
    extern FindFirstFileA, FindNextFileA, FindClose, GetProcessHeap, HeapAlloc, HeapFree

    global GetFileNamesInDirectory

; Gets all names of the files fitting to the passed directory filter
; Call the passed callback (rdx) for every file name
; Returns the count of found files in rax
;
; E.g.: "stories\\*.story", 0
;
; # Arguments:
;   - rcx = address to search path
;   - rdx = callback address
;       - rcx => File name
;       - rdx => File index
; # Returns: found file count
GetFileNamesInDirectory:
    ; Prologue:
    ; Stack frame:
    ; - 32 bytes shadow space
    ; -  8 bytes address of search path (rsp+32)
    ; -  8 bytes heap handle            (rsp+40)
    ; -  8 bytes heap address for file  (rsp+48)
    ; -  8 bytes callback address       (rsp+56)
    ; -  8 bytes file count             (rsp+64)
    ; -  8 bytes file handle            (rsp+72)

    push rbp
    mov rbp, rsp
    sub rsp, 88

    ; Store callback address in stack frame
    mov [rsp+48], rdx
    ; Zero-out count
    mov qword [rsp+56], 0

    ; Get the heap handle and store it in the stack frame
    call GetProcessHeap
    mov [rsp+32], rax

    ; Allocate the space for the file data
    mov rcx, rax
    mov rdx, 8                          ; flags (HEAP_ZERO_MEMORY = 8)
    mov r8, FIND_DATA_STRUCT_SIZE       ; File size from the stack
    call HeapAlloc
    mov [rsp+40], rax

    ; FindFirstFile(search_path, &find_data)
    mov rdx, [rsp+40]         ; Second parameter: find data structure
    call FindFirstFileA
    mov [rsp+64], rax                 ; Save handle
    
    cmp rax, -1                   ; Check for INVALID_HANDLE_VALUE
    je no_files

file_loop:
    ; Call callback
    mov rcx, [rsp+40]
    mov rcx, [rcx+44]
    mov rdx, [rsp+56]
    call [rsp+48]

    ; Increment file count
    inc qword [rsp+56]

    mov rcx, [rsp+64]                ; Handle
    lea rdx, [rsp+40]        ; Find data structure
    call FindNextFileA

    test rax, rax
    jnz file_loop

    ; Close find handle
    mov rcx, [rsp+64]
    call FindClose
    jmp done

no_files:
    xor rax, rax

done:
    ; Free space on heap
    mov rcx, [rsp+32]
    mov rdx, 0          ; flags
    mov r8, [rsp+40]    ; heap address
    call HeapFree

    mov rax, [rsp+56]
    add rsp, 88
    pop rbp
    ret