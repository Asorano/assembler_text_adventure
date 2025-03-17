section .bss
    error_buffer resb 1024

section .text
    extern GetLastError, FormatMessageA

    WriteLastError:
        mov rcx, 0x04
        call SetTextColor

        call GetLastError

        sub rsp, 64
        
        mov rcx, 0x00001000      ; FORMAT_MESSAGE_FROM_SYSTEM
        xor rdx, rdx             ; NULL source
        mov r8, rax     ; Error code
        mov r9d, 0               ; Language ID (default)
        lea rax, [error_buffer]
        mov [rsp+32], rax        ; Output buffer (5th parameter)
        mov qword [rsp+40], 1024 ; Buffer size (6th parameter)
        mov qword [rsp+48], 0    ; Arguments (7th parameter)
        
        call FormatMessageA
        
        add rsp, 64              ; Restore stack

        lea rcx, [error_buffer]
        call WriteText

        mov rcx, 0x07
        call SetTextColor

        ret