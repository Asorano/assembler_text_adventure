default rel

section .data
    FIND_DATA_STRUCT_SIZE equ 592

section .text
    extern FindFirstFileA, FindNextFileA, FindClose, CopyMemory

    global GetFileNamesInDirectory, FindFileByPathAndIndex

; Tries to find a file with the search path and the index
; # Arguments:
;   - rcx = [in]  address to search path
;   - rdx = [in]  file index
;   -  r8 = [out] pointer to addres where the file name should be stored 
; # Returns 0 if successful, otherwise > 0
FindFileByPathAndIndex:
    ; Prologue
    ; Stack frame:
    ; -  32 bytes shadow space
    ; -   8 bytes address of search path     (rsp+32)
    ; -   8 bytes file index                 (rsp+40)
    ; -   8 bytes file name output addresss  (rsp+48)
    ; -   8 bytes find handle                (rsp+56)     
    ; - 592 bytes Find file data             (rsp+64)
    ; -   8 bytes result                     (rsp+72)
    ; --------------------------------------------
    ; => 664 bytes
    push rbp
    mov rbp, rsp
    sub rsp, 664

    ; Store arguments in stack frame
    mov [rsp+32], rcx
    mov [rsp+40], rdx
    mov [rsp+48], r8

    ; Find first file
    mov rcx, [rsp+32]           ; Search path
    lea rdx, [rsp+64]           ; Second parameter: find data structure in stack frame
    call FindFirstFileA
    mov [rsp+56], rax           ; Save handle

    ; Check whether a file was found
    cmp rax, -1
    je _find_file_by_path_and_index_file_not_found

_find_file_by_path_and_index_loop:
    cmp qword [rsp+40], 0
    je _find_file_by_path_and_index_load_file_name

    dec qword [rsp+40]
    
    ; Find next file
    mov rcx, [rsp+56]        ; Handle
    lea rdx, [rsp+64]        ; Find data structure
    call FindNextFileA

    test rax, rax
    jnz _find_file_by_path_and_index_loop

    jmp _find_file_by_path_and_index_end

_find_file_by_path_and_index_load_file_name:
    lea rcx, [rsp+64+44]
    mov rdx, [rsp+48]
    mov r8, 256
    call CopyMemory

    mov qword [rsp+72], 0

_find_file_by_path_and_index_end:
    ; Close find handle
    mov rcx, [rsp+56]
    call FindClose

    mov rax, [rsp+72]

    ; Epilogue
    add rsp, 664
    pop rbp
    ret

_find_file_by_path_and_index_file_not_found:
    mov qword [rsp+72], 1
    jmp _find_file_by_path_and_index_end

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

    ; Epiloque
    mov rax, [rsp+56]
    add rsp, 664
    pop rbp
    ret