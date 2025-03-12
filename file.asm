default rel
BITS 64

%include "include/output.inc"
%include "include/error.inc"

section .data
    txt_err_file_handle db "Could not get file handle: ", 0

    filename db "C:\\Development\\Private\\assembler\\game.bin", 0          ; File name (null-terminated)
    buffer db 1024 dup(0)              ; Buffer for file content
    bytesRead dq 0                     ; Stores number of bytes read
    bytesWritten dq 0                     ; Stores number of bytes read
    hFile dq -1                        ; File handle
    fmt db "File Content: %s", 10, 0   ; Format string for printf

section .bss
    game_buffer resb 1048576  ; 1MB buffer

section .text
    global main
    extern ExitProcess, CreateFileA, ReadFile, CloseHandle

main:
    call SetupOutput

    ; Open file using CreateFileA
    sub rsp, 40                ; Reserve shadow space (32 bytes) + alignment

    mov rcx, filename          ; lpFileName (RCX) -> Pointer to file name
    mov rdx, 0x80000000        ; dwDesiredAccess (RDX) -> GENERIC_WRITE (0x40000000)
    mov r8, 0                  ; dwShareMode (R8) -> 0 (no sharing)
    mov r9, 0                  ; lpSecurityAttributes (R9) -> NULL

    mov qword [rsp+32], 3      ; dwCreationDisposition -> CREATE_ALWAYS (2)
    mov qword [rsp+40], 0      ; dwFlagsAndAttributes -> 0 (default)
    mov qword [rsp+48], 0      ; hTemplateFile -> NULL

    call CreateFileA           ; Call the function

    mov [hFile], rax           ; Store the file handle

    add rsp, 40                ; Restore the stack

    cmp rax, -1
    je _create_file_error          

    mov [hFile], rax                      ; Store file handle

    ; ; Read file using ReadFile
    mov rcx, rax                          ; hFile (file handle)
    lea rdx, [buffer]                     ; lpBuffer (buffer)
    mov r8, 1024                          ; nNumberOfBytesToRead (1024 bytes)
    lea r9, [bytesRead]                   ; lpNumberOfBytesRead
    sub rsp, 32                           ; Shadow space
    call ReadFile                         ; Call ReadFile
    add rsp, 32                           ; Clean up stack

    ; ; Close file handle
    ; mov rcx, [hFile]                      ; hObject (file handle)
    ; call CloseHandle

    ; lea rcx, [buffer]
    ; call WriteText

    ; ; mov rcx, rax
    ; ; call WriteNumber

    ; lea rcx, [buffer + 12]
    ; ; add rcx, 40
    ; ; shl rax, 3
    ; ; add rcx, rax 
    ; call WriteText

exit:
    mov rcx, 0x07
    call SetTextColor

    sub rsp, 0x28
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28

_create_file_error:
    mov rcx, 0x04
    call SetTextColor

    mov rcx, txt_err_file_handle
    call WriteText

    call WriteLastError

    jmp exit