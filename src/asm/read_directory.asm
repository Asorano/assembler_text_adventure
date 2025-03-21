default rel

section .data
    search_path db "stories\\*bin", 0  ; Current directory, all files
    fmt_str db "First bin file: %s", 10, 0
    txt_no_files db "No files found.", 0

section .bss
    find_data resb 592        ; WIN32_FIND_DATA structure (592 bytes)
    

section .text
    extern SetupOutput, WriteText, WriteNumber, printf
    extern FindFirstFileA, FindNextFileA, FindClose

    global ReadFilesInDirectoryWithCallback, RunDev

; Gets all files in the passed directory
; # Arguments:
;   - rcx = address to search path

RunDev:
    call ReadFilesInDirectoryWithCallback
    ret

ReadFilesInDirectoryWithCallback:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 32
    
    ; FindFirstFile(search_path, &find_data)
    lea rcx, [search_path]       ; First parameter: search path
    lea rdx, [find_data]         ; Second parameter: find data structure
    call FindFirstFileA
    mov rbx, rax                 ; Save handle
    
    cmp rax, -1                   ; Check for INVALID_HANDLE_VALUE
    je no_files

    mov rcx, fmt_str              ; Format string
    lea rdx, [find_data + 44]     ; Filename is at offset 44
    call printf

     ; Close find handle
    mov rcx, rbx
    call FindClose
    jmp done   

no_files:
    mov rcx, txt_no_files
    call printf

done:
    add rsp, 32                 ; Restore stack
    pop rbx                     ; Restore rbx
    pop rbp                     ; Restore frame pointer
    xor rax, rax                ; Return 0
    ret