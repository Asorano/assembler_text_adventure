section .text
    extern CopyMemory, WriteNumber, WriteChar
    extern HeapAlloc
    global CalculateTextLength, AllocateNextLineOnHeap, CalculateNextLineLength, SkipEmptyLines, SubString, FindFirstCharInString

    ; Calculates the length of a text by searching the index of the first 0
    ; # Arguments:
    ;   - rcx = address of text, text must end with 0
    CalculateTextLength:
        mov rax, 0

    _loop_calc_length:
        ; Loads the next byte
        movzx rdx, byte [rcx]
        cmp rdx, 0
        je _end_calc_length

        inc rax
        inc rcx
        
        jmp _loop_calc_length

    _end_calc_length:
        ret

    ; Returns the index of the first occurence of a char in a string or -1 if none was found
    ; # Arguments
    ; - [in]    rcx = Pointer to string
    ; - [in]    rdx = char to find
    ; - [out]   rax = first index of char or -1
    FindFirstCharInString:
        mov rax, qword -1
        mov  r9, qword -1
        xor  r8, r8

    _loop_find_first_char_in_string:
        ; Check whether current char is 0 and terminates the string
        mov r8b, byte [rcx]
        inc qword rcx
        inc qword r9

        test r8b, r8b
        jz _end_find_first_char_in_string

        ; Check whether the current char is the target char
        cmp r8, rdx
        jne _loop_find_first_char_in_string

        mov rax, r9

    _end_find_first_char_in_string:
        ret

    ; Allocates a substring of the passed string on the heap
    ; # Arguments
    ; - [in]    rcx = Heap handle
    ; - [in]    rdx = The pointer to the string
    ; - [in]     r8 = start index
    ; - [in]     r9 = count
    ; - [out]   rax = pointer to substring or NULL
    SubString:
        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle            (rsp+32)
        ; -  8 bytes pointer to string      (rsp+40)
        ; -  8 bytes start index            (rsp+48)
        ; -  8 bytes count                  (rsp+56)
        ; -  8 bytes required string length (rsp+64)
        ; -  8 bytes pointer to new string  (rsp+72)
        ; -----------------------
        ; => 80 bytes
        sub rsp, 80

        ; Check that the index is >= 0
        cmp r8, 0
        jl _err_sub_string

        ; Check that the count is > 0
        cmp r9, 0
        jle _err_sub_string

        ; Setup stack frame
        mov [rsp+32], rcx
        mov [rsp+40], rdx

        mov [rsp+48], r8
        mov [rsp+56], r9   ; Save count on stack
        add r9, r8          ; Sum start index and count to get min required string length
        mov [rsp+64], r9    ; Store min required length on stack

        ; Check that index + count does not exceed the length of the string
        mov rcx, [rsp+40]
        call CalculateTextLength

        cmp rax, [rsp+64]
        jl _err_sub_string

        ; Allocate memory
        mov rcx, [rsp+32]
        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, [rsp+56]            ; Substring length             
        inc r8                      ; Add one byte for string terminator
        call HeapAlloc
        mov [rsp+72], rax

        ; Copy string to heap
        mov rcx, [rsp+40]   ; Load start address of original string
        add rcx, [rsp+48]   ; Add start index offset

        mov rdx, rax        ; Set destination to address on heap
        mov  r8, [rsp+56]   ; Set length
        call CopyMemory

        mov rax, [rsp+72]

    _end_sub_string:
        ; Epiloque
        add rsp, 80
        pop rbp
        ret

    _err_sub_string:
        xor rax, rax
        jmp _end_sub_string

    ; Allocates the next line of a string on the heap
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to data
    ; - [in]    
    ; - [out]   rax = heap pointer to line
    ; - [out]   rdx = pointer to next line
    ; - [out]    r8 = string length
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
        mov  r8, [rsp+48]
        ; Epiloque
        add rsp, 80
        pop rbp
        ret

    ; Skips all empty lines in the string
    ; # Arguments:
    ; - [in]    rcx = pointer to string
    ; - [out]   rax = skipped line count
    ; - [out]   rdx = pointer to next line
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
        mov rdx, rcx
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