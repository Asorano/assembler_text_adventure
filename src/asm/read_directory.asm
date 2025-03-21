default rel

section .data
    txt_no_files db "No files found.", 0

section .bss
    find_data resb 592        ; WIN32_FIND_DATA structure (592 bytes)
    

section .text
    extern FindFirstFileA, FindNextFileA, FindClose
    
    global ReadFilesInDirectoryWithCallback

; Gets all files in the passed directory
; # Arguments:
;   - rcx = address to search path
;   - rdx = callback address
; # Returns: found file count
ReadFilesInDirectoryWithCallback:
    push rbp
    mov rbp, rsp
    push rbx

    ; Stack frame:
    ; - 32 bytes shadow space
    ; -  8 bytes callback address       (rsp+32)
    ; -  8 bytes file count             (rsp+40)
    sub rsp, 48
    
    mov [rsp+32], rdx

    ; FindFirstFile(search_path, &find_data)
    lea rdx, [find_data]         ; Second parameter: find data structure
    call FindFirstFileA
    mov rbx, rax                 ; Save handle
    
    cmp rax, -1                   ; Check for INVALID_HANDLE_VALUE
    je no_files

file_loop:
    ; Increment file count
    inc qword [rsp+40]

    ; Call callback
    lea rcx, [find_data+44]
    call [rsp+32]

    mov rcx, rbx                ; Handle
    lea rdx, [find_data]        ; Find data structure
    call FindNextFileA

    test rax, rax
    jnz file_loop

    ; Close find handle
    mov rcx, rbx
    call FindClose
    jmp done

no_files:
    xor rax, rax

done:
    mov rax, [rsp+40]
    add rsp, 48                 ; Restore stack
    pop rbx                     ; Restore rbx
    pop rbp                     ; Restore frame pointer
    ret