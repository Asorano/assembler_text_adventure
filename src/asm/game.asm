default rel
BITS 64

%include "src/include/output.inc"
%include "src/include/error.inc"
%include "src/include/data.inc"

section .data
    BUFFER_SIZE equ 1048576               ; 1MB

    txt_err_file_handle db "Could not get file handle: ", 0
    txt_err_file_too_large db "File is too large. Maximum is: ", 0
    txt_err_file_parsing db "Failed to parse file", 0
    txt_file_size db "File size: ", 0
    txt_file_parsed db "File parse sucessfully!", 10, 0
    txt_game_data_decision db "Decisions: ", 0

    filename db "./game.bin", 0          ; File name (null-terminated)

    file_handle dq -1                        ; File handle

section .bss
    file_buffer resb BUFFER_SIZE  ; 1MB buffer
    file_size resq 1

section .text
    global main
    extern log_decisions, log_decision ; C
    extern ParseGameData, GetGameDecisionByIndex, game_decision_count, game_decision_buffer, FindGameDecisionById, GetActionCount
    extern ExitProcess, CreateFileA, ReadFile, CloseHandle, GetFileSize, Sleep

main:
    call SetupOutput
    call ReadGameFile

    movzx rcx, word [game_decision_count]
    call WriteNumber

    jmp _exit

ReadGameFile:
    ; Open file using CreateFileA

    mov rcx, filename          ; lpFileName (RCX) -> Pointer to file name
    mov rdx, 0x80000000        ; dwDesiredAccess (RDX) -> GENERIC_WRITE (0x40000000)
    mov r8, 0                  ; dwShareMode (R8) -> 0 (no sharing)
    mov r9, 0                  ; lpSecurityAttributes (R9) -> NULL

    sub rsp, 64                ; Reserve shadow space (32 bytes) + alignment
    mov QWORD [rsp+32], 3      ; 5th parameter - dwCreationDisposition -> OPEN_EXISTING (3)
    mov QWORD [rsp+40], 0   ; 6th parameter - dwFlagsAndAttributes -> FILE_ATTRIBUTE_NORMAL (0x80)
    mov QWORD [rsp+48], 0      ; 7th parameter - hTemplateFile -> NULL

    call CreateFileA           ; Call the function

    mov [file_handle], rax           ; Store the file handle

    add rsp, 64                ; Restore the stack

    cmp rax, -1
    je _create_file_error          

    mov [file_handle], rax                      ; Store file handle

    ; Get and print file size
    mov rcx, rax           ; file handle
    xor rdx, rdx           ; NULL for high part
    sub rsp, 32
    call GetFileSize
    mov [file_size], rax
    add rsp, 32

    ; mov rcx, txt_file_size
    ; call WriteText
    ; mov rcx, [file_size]
    ; call WriteNumber

    ; mov rcx, 10
    ; call WriteChar

    ; Check file size
    cmp qword [file_size], BUFFER_SIZE-1
    ja _file_too_large_error

    ; ; Read file using ReadFile
    mov rcx, [file_handle]                          ; file_handle (file handle)
    lea rdx, [file_buffer]                     ; lpBuffer (buffer)
    mov r8, [file_size]                          ; nNumberOfBytesToRead (1024 bytes)
    mov QWORD r9, 0
    sub rsp, 48                           ; Shadow space
    mov QWORD [rsp+32], 0
    call ReadFile                         ; Call ReadFile
    add rsp, 48                           ; Clean up stack

    ; Close file handle
    sub rsp, 32
    mov rcx, [file_handle]                      ; hObject (file handle)
    call CloseHandle
    add rsp, 32

    lea rcx, [file_buffer]
    mov rdx, [file_size]
    call ParseGameData

    test rax, rax
    jz _parse_file_error
    ret

_exit:
    mov rcx, 0x07
    call SetTextColor

    sub rsp, 0x28
    xor ecx, ecx
    call ExitProcess
    add rsp, 0x28

_parse_file_error:
    mov rcx, 0x04
    call SetTextColor   

    mov rcx, txt_err_file_parsing
    call WriteText

    jmp _exit 

_create_file_error:
    mov rcx, 0x04
    call SetTextColor

    mov rcx, txt_err_file_handle
    call WriteText

    call WriteLastError

    jmp _exit

_file_too_large_error:
    mov rcx, 0x04
    call SetTextColor

    mov rcx, txt_err_file_too_large
    call WriteText

    mov rcx, BUFFER_SIZE
    call WriteNumber

    jmp _exit