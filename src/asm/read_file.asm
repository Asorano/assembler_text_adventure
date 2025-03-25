default rel
BITS 64

section .data
    txt_err_read_file db "Could not read file: ", 0
    txt_err_read_file_heap db "Could not allocate memory on the heap: ", 0

section .text
    global ReadFileWithCallback

    extern CreateFileA, ReadFile, CloseHandle, GetFileSize, Sleep
    extern GetProcessHeap, HeapAlloc, HeapFree
    extern WriteText, WriteNumber, WriteChar, SetTextColor, WriteLastError

; Reads the content of a file and places the size in rax and the content in the buffer
; # Arguments:
;   - rcx = address to the file name
;   - rdx = callback address for parsing content
;   - r8  = address for callback result (rax), if NULL return value is ignored
; # Callback:
;   - rcx = address of buffer
;   - rdx = length of buffer
ReadFileWithCallback:
    ; Stackframe:
    ; 32 bytes shadow space
    ; 24 bytes additional parameters        -> rsp+32
    ;  8 bytes file handle                  -> rsp+56
    ;  8 bytes address of file name         -> rsp+64
    ;  8 bytes callback address             -> rsp+72
    ;  8 bytes heap handle                  -> rsp+80
    ;  8 bytes heap address                 -> rsp+88
    ;  8 bytes file size                    -> rsp+96
    ;  8 bytes number of bytes read         -> rsp+104
    ;  8 bytes address for callback result  -> rsp+112
    ;  8 bytes alignment
    ; ------------------------------------------------
    ; => 128
    push rbp
    sub rsp, 128

    mov [rsp+64], rcx
    mov [rsp+72], rdx
    mov [rsp+112], r8

    ; Zero-out the bytes read since ReadFile only uses dword
    mov qword [rsp+104], 0

    ; Create file handle
    mov rdx, 0x80000000        ; dwDesiredAccess (RDX) -> GENERIC_READ
    mov r8, 0                  ; dwShareMode (R8) -> 0 (no sharing)
    mov r9, 0                  ; lpSecurityAttributes (R9) -> NULL
    mov QWORD [rsp+32], 3      ; 5th parameter - dwCreationDisposition -> OPEN_EXISTING (3)
    mov QWORD [rsp+40], 0      ; 6th parameter - dwFlagsAndAttributes -> FILE_ATTRIBUTE_NORMAL (0x80)
    mov QWORD [rsp+48], 0      ; 7th parameter - hTemplateFile -> NULL

    call CreateFileA           ; Call the function

    cmp rax, -1
    je _read_file_write_error

    mov [rsp+56], rax           ; Store the file handle

    ; Get and print file size
    mov rcx, rax           ; file handle
    xor rdx, rdx           ; NULL for high part

    ; Get the file size and store it in the stack frame
    call GetFileSize
    inc rax
    mov [rsp+96], rax

    ; Get the heap handle and store it in the stack frame
    call GetProcessHeap
    mov [rsp+80], rax

    ; Allocate the space for the file on the heap
    mov rcx, rax
    mov rdx, 8          ; flags (HEAP_ZERO_MEMORY = 8)
    mov r8, [rsp+96]    ; File size from the stack
    call HeapAlloc

    test rax, rax
    je _read_file_heap_error

    ; Put heap address in the stack frame
    mov [rsp+88], rax

    ; Read file content into heap memory
    mov rcx, [rsp+56]       ; file_handle
    mov rdx, [rsp+88]       ; lpBuffer (buffer address)
    mov r8, [rsp+96]        ; nNumberOfBytesToRead (1024 bytes)
    lea r9, [rsp+104]
    mov QWORD [rsp+32], 0 
    call ReadFile                         ; Call ReadFile

    ; Add null terminator at the end of the heap buffer
    mov rax, [rsp+88]
    add rax, [rsp+104]
    mov byte [rax], 0

    ; Prepare callback
    mov rcx, [rsp+88]
    mov rdx, [rsp+96]
    call [rsp+72]

    ; If the callback result address is not NULL, store the result in it
    mov rcx, [rsp+112]
    cmp rcx, 0
    je _read_file_finalize
    mov [rcx], rax

_read_file_finalize:
    ; Free the heap memory
    mov rcx, [rsp+80]
    mov rdx, 0          ; flags
    mov r8, [rsp+88]    ; heap address
    call HeapFree

    ; Close the handle
    mov rcx, [rsp+56]
    call CloseHandle

    mov qword rax, 1
    jmp _read_file_end

_read_file_heap_error:
    mov rcx, txt_err_read_file_heap
    call WriteText

    xor rax, rax
    jmp _read_file_end

_read_file_write_error:
    mov rcx, txt_err_read_file
    call WriteText

    mov rcx, [rsp+64]
    call WriteText

    mov rcx, 10
    call WriteChar

    call WriteLastError

    xor rax, rax
_read_file_end:
    add rsp, 128
    pop rbp
    ret