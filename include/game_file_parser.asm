default rel
BITS 64

section .data
    GAME_DECISION_BUFFER_SIZE equ 1048576     ; 1MB
    GAME_TEXT_BUFFER_SIZE equ 1048576     ; 1MB

section .bss
    game_decision_count resw 1
    game_decision_buffer resb GAME_DECISION_BUFFER_SIZE  ; 1MB buffer
    game_text_buffer resb GAME_TEXT_BUFFER_SIZE  ; 1MB buffer

section .text
    global ParseGameFile
    extern debug_log_decision

    ParseGameFile:
        ; Arguments:
        ; - rcx = unparsed data buffer
        ; - rdx = length of buffer
        ; Registers:
        ; - rax = current char
        ; - r9  = end address of data_buffer
        ; - r10 = current_decision_address
        ; - r11 = current_text_address
        ; - r12 = current searched char

        ; Flow:
        ; 1) Skip whitespace
        ; 2) Check that first non-whitespace character is [
        ; 3) Enter decision parsing mode                        
        ; 4) Parse decision id until first =                   ; search: =
        ;   1) Throw error if whitespace
        ;   2) Until first =
        ;   3) Max length 32 bytes
        ; 5) Check next char to be " and skip it
        ;   1) Throw error if not "
        ; 6) Parse decision text until first "
        ;   1) Remember length of text
        ; 7)  current_text_address -= text_length 
        ; 8) Put text into current_text_address
        ; 9) Add GameDecision_size to current_decision_address (r10)
        ; 10) Parse next decision

        ; PREPARATION

        push r12                                ; Save non-volatile register for restoring at the end

        mov r10, game_decision_buffer           ; Load game_decision_buffer
        mov r11, game_text_buffer               ; Load game_text_buffer
        
        ; Move the last adress of the data_buffer to r9
        mov r9 , rdx                           
        add r9, rcx
        dec r9

        mov [game_decision_count], word 0       ; Total number of decisions, initialized to 0

        mov al, byte [rcx]                      ; Load first character
        
        mov r12, ' '                            ; Replace all whitespaces at the beginning 
        call SkipChar         ; Skip potential initial whitespace
        
        ; DECISION PARSING

    _parse_decision:
        cmp rax, '['                            ; Check that the decision starts with [
        jne _file_parsing_error                 

        ; Mov current text address to current decision
        mov [r10], r11
        add r10, 8

        ; Parse decision id
        inc rcx
        mov al, byte [rcx]
        mov r12, '='
        call ParseTextIntoBuffer

        mov r12, ' '
        call SkipChar

        ; Check that the next sign is a " and jump over it
        mov r12, 0x22
        call CheckCharAndSkip

        ; Parse the decision text
        mov r12, 0x22
        call ParseTextIntoBuffer

        mov r12, ' '
        call SkipChar

        ; Check that the next sign is a ]
        mov r12, ']'
        call CheckCharAndSkip

        mov r12, ' '
        call SkipChar

        ; Check that the next two chars are CRLF
        mov r12, 0x0D
        call CheckCharAndSkip
        mov r12, 0x0A
        call CheckCharAndSkip

        ; Increment decision count
        inc word [game_decision_count]
        jmp _parse_decision

    _file_parsing_error:
        mov rax, 0

    _end_parsing:
        mov al, byte [game_decision_count]

        mov rcx, [game_decision_buffer]
        call debug_log_decision
        pop r12
        ret

    ; Checks whether the are at least rax bytes til the end of the buffer
    ValidateRemainingLength:
        ; r12 = min required bytes
        push rax    ; Save the current char on the stack

        mov rax, r9
        sub rax, rcx

        cmp rax, r12

        pop rax     ; Restore current char
        ret

    ; Parses a text into the buffer passed via rcx
    ParseTextIntoBuffer:
        ; r12 = terminator char
        cmp rax, r12
        je _end_text_parse     ; End text if the terminator was found
        
        mov [r11], byte al          ; Write into text buffer
        inc r11

        inc rcx                     ; Load next char into rax
        mov al, byte [rcx]
        jmp ParseTextIntoBuffer

    _end_text_parse:
        mov [r11], byte 0                ; Add string terminator
        inc r11

        inc rcx
        mov al, byte [rcx]
        ret

    CheckCharAndSkip:
        ; r12 = target char
        cmp rax, r12
        jne _fail_char_check

        inc rcx
        mov al, byte [rcx]
        ret
    _fail_char_check:
        add rsp, 8 ; Remove the call address from the stack
        jmp _file_parsing_error

    ; Skips chars as long as they are equal to the char in r12 
    SkipChar:
        cmp rax, r12
        jne _end_skip_char
        inc rcx                                 ; Increment data_buffer address
        mov al, byte [rcx]                      ; Load next char into rax
        jmp SkipChar
    _end_skip_char:
        ret