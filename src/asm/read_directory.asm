default rel

section .data
    txt_no_files db "No files found.", 0

section .bss
    find_data resb 592        ; WIN32_FIND_DATA structure (592 bytes)
    

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
    ; Stack frame:
    ; - 32 bytes shadow space
    ; -  8 bytes callback address       (rsp+32)
    ; -  8 bytes file count             (rsp+40)
    ; -  8 bytes file handle            (rsp+48)
    sub rsp, 64
    ; Store callback address in stack frame
    mov [rsp+32], rdx
    ; Zero-out count
    mov qword [rsp+40], 0

    ; FindFirstFile(search_path, &find_data)
    lea rdx, [find_data]         ; Second parameter: find data structure
    call FindFirstFileA
    mov [rsp+48], rax                 ; Save handle
    
    cmp rax, -1                   ; Check for INVALID_HANDLE_VALUE
    je no_files

file_loop:
    ; Call callback
    lea rcx, [find_data+44]
    mov rdx, [rsp+40]
    call [rsp+32]

    ; Increment file count
    inc qword [rsp+40]

    mov rcx, [rsp+48]                ; Handle
    lea rdx, [find_data]        ; Find data structure
    call FindNextFileA

    test rax, rax
    jnz file_loop

    ; Close find handle
    mov rcx, [rsp+48]
    call FindClose
    jmp done

no_files:
    xor rax, rax

done:
    mov rax, [rsp+40]
    add rsp, 64
    ret