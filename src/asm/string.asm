section .text
    extern CopyMemory, WriteNumber, WriteChar
    extern HeapAlloc
    global AllocateNextLineOnHeap, CalculateNextLineLength, SkipEmptyLines

    ; Allocates the next line of a string on the heap
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to data
    ; - [in]    
    ; - [out]   rax = heap pointer to line
    ; - [out]   rdx = pointer to next line
    AllocateNextLineOnHeap:
        ; Prologue
        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle                (rsp+32)
        ; -  8 bytes pointer to current line    (rsp+40)
        ; -  8 bytes line length                (rsp+48)
        ; -  8 bytes pointer to next line       (rsp+56)
        ; -  8 bytes heap pointer               (rsp+64)
        ; -  8 bytes alignment
        ; ----------------------------------------------
        ; => 80
        sub rsp, 80
        mov [rsp+32], rcx
        mov [rsp+40], rdx

        mov rcx, rdx
        call CalculateNextLineLength
        mov [rsp+48], rax           ; Store text length
        mov [rsp+56], rdx           ; Store pointer to next line

        ; Allocate length 
        mov rcx, [rsp+32]
        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, rax                 
        inc r8                      ; Add 1 byte for 0 terminator
        call HeapAlloc
        mov [rsp+64], rax           ; Store heap pointer

        ; Copy string to heap
        ; Since the memory is zeroed, the last char is automatically 0
        mov rcx, [rsp+40]
        mov rdx, rax
        mov  r8, [rsp+48]
        call CopyMemory

        mov rax, [rsp+64]
        mov rdx, [rsp+56]
        ; Epiloque
        add rsp, 80
        pop rbp
        ret

    ; Skips all empty lines in the string
    ; # Arguments:
    ; - [in]    rcx = pointer to string
    ; - [out]   rdx = pointer to next line
    ; - [out]   rax = skipped line count
    SkipEmptyLines:
        push rbp
        mov rbp, rsp

        xor rax, rax
        xor r10, r10

    _loop_skip_empty_lines:
        mov r10b, [rcx]

        cmp r10b, 0x0D
        jne _end_skip_empty_lines

        add rcx, 2  ; Add two because of CR and LF
        inc rax
        jmp _loop_skip_empty_lines
        
    _end_skip_empty_lines:
        pop rbp
        ret

    ; Calculates the length of the text until the next CRLF
    ; # Arguments
    ; - [in]    rcx = pointer to data
    ; - [out]   rax = length without CRLF
    ; - [out]   rdx = pointer to next line
    CalculateNextLineLength:
        xor rax, rax
        xor r8, r8

    _calculate_next_line_length_loop:
        mov r8b, [rcx]

        ; If char is terminator (0), end
        test r8, r8
        jz _calculate_next_line_length_file_end

        inc rcx

        ; If char is LF, end
        cmp r8, 0x0D
        je _calculate_next_line_length_found_line_break

        inc rax
        mov r8b, [rcx]

        jmp _calculate_next_line_length_loop

    _calculate_next_line_length_found_line_break:
        inc rcx ; Add LF to pointer
        mov rdx, rcx
        jmp _calculate_next_line_length_end
        
    _calculate_next_line_length_file_end:
        mov rdx, qword 0

    _calculate_next_line_length_end:
        ret