default rel
BITS 64

%include "include/output.inc"
%include "include/error.inc"

section .data
    BUFFER_SIZE equ 1048576               ; 1MB

    txt_err_file_handle db "Could not get file handle: ", 0
    txt_err_file_too_large db "File is too large. Maximum is: ", 0
    txt_err_file_parsing db "Failed to parse file", 0
    txt_file_size db "File size: ", 0
    txt_file_parsed db "File parse sucessfully!", 10, 0
    txt_game_data_decision db "Decisions: ", 0

    filename db "C:\\Development\\Private\\assembler\\game.bin", 0          ; File name (null-terminated)

    file_handle dq -1                        ; File handle

section .bss
    file_buffer resb BUFFER_SIZE  ; 1MB buffer
    file_size resq 1

section .text
    global main
    extern ParseGameFile
    extern ExitProcess, CreateFileA, ReadFile, CloseHandle, GetFileSize, Sleep

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

    mov [file_handle], rax           ; Store the file handle

    add rsp, 40                ; Restore the stack

    cmp rax, -1
    je _create_file_error          

    mov [file_handle], rax                      ; Store file handle

    ; Get and print file size
    sub rsp, 32
    mov rcx, rax           ; file handle
    xor rdx, rdx           ; NULL for high part
    call GetFileSize
    mov [file_size], rax
    add rsp, 32

    mov rcx, txt_file_size
    call WriteText
    mov rcx, [file_size]
    call WriteNumber

    mov rcx, 10
    call WriteChar

    ; Check file size
    cmp qword [file_size], BUFFER_SIZE-1
    ja _file_too_large_error

    ; ; Read file using ReadFile
    mov rcx, [file_handle]                          ; file_handle (file handle)
    lea rdx, [file_buffer]                     ; lpBuffer (buffer)
    mov r8, [file_size]                          ; nNumberOfBytesToRead (1024 bytes)
    lea r9, [rsp+8]                   ; lpNumberOfBytesRead
    sub rsp, 32                           ; Shadow space
    call ReadFile                         ; Call ReadFile
    add rsp, 32                           ; Clean up stack

    ; ; Close file handle
    sub rsp, 0x28
    mov rcx, [file_handle]                      ; hObject (file handle)
    call CloseHandle
    add rsp, 0x28

    lea rcx, [file_buffer]
    call ParseGameFile

    test rax, rax
    jz _parse_file_error

    push rax

    mov rcx, txt_file_parsed
    call WriteText

    mov rcx, txt_game_data_decision,
    call WriteText

    pop rcx
    call WriteNumber

exit:
    mov rcx, 0x07
    call SetTextColor

    sub rsp, 0x28
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28



StripWhitespace:
    ; rcx = address of buffer
    ; rdx = length
    mov rax, rcx
    mov r9, rcx
    add r9, rdx

_strip_loop:
    cmp rax, r9
    je _end_strip

    movzx r8, byte [rax]
    cmp r8, ' '
    jnz _increment

    mov byte [rax], '_'
_increment:
    inc rax
    jmp _strip_loop

_end_strip:
    ret

_parse_file_error:
    mov rcx, 0x04
    call SetTextColor   

    mov rcx, txt_err_file_parsing
    call WriteText

    jmp exit 

_create_file_error:
    mov rcx, 0x04
    call SetTextColor

    mov rcx, txt_err_file_handle
    call WriteText

    call WriteLastError

    jmp exit

_file_too_large_error:
    mov rcx, 0x04
    call SetTextColor

    mov rcx, txt_err_file_too_large
    call WriteText

    mov rcx, BUFFER_SIZE
    call WriteNumber

    jmp exit