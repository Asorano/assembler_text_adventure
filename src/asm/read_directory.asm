default rel

section .data
    FIND_DATA_STRUCT_SIZE equ 592

section .text
    extern FindFirstFileA, FindNextFileA, FindClose

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
    ; -  32 bytes shadow space
    ; -   8 bytes address of search path (rsp+32)
    ; -   8 bytes callback address       (rsp+40)
    ; -   8 bytes file handle            (rsp+48)
    ; -   8 bytes file count             (rsp+56)
    ; - 592 bytes Find file data         (rsp+64)
    ; -   8 bytes alignment
    ; ---------------------------------------------
    ; => 656 bytes
    push rbp
    mov rbp, rsp
    sub rsp, 664

    ; Store callback address in stack frame
    mov [rsp+32], rcx
    mov [rsp+40], rdx
    ; Zero-out count
    mov qword [rsp+56], 0

    ; FindFirstFile(search_path, &find_data)
    mov rcx, [rsp+32]
    lea rdx, [rsp+64]         ; Second parameter: find data structure
    call FindFirstFileA
    mov [rsp+48], rax                 ; Save handle
    
    cmp rax, -1                   ; Check for INVALID_HANDLE_VALUE
    je no_files

file_loop:
    ; Call callback
    lea rcx, [rsp+64+44]
    mov rdx, [rsp+56]
    call [rsp+40]

    ; Increment file count
    inc qword [rsp+56]

    mov rcx, [rsp+48]        ; Handle
    lea rdx, [rsp+64]        ; Find data structure
    call FindNextFileA

    test rax, rax
    jnz file_loop

no_files:
    xor rax, rax

done:
    ; Close find handle
    mov rcx, [rsp+48]
    call FindClose

    mov rax, [rsp+56]
    add rsp, 664
    pop rbp
    ret