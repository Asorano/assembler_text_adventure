    struc GameDecision
        .id resb 32
        .txt:       resq 1          ; 8 byte, address to decision text
        .actions:   resq 4          ; 8 byte for addresses of max 4 possible actions per decision
    endstruc

    struc GameAction
        .txt:       resq 1          ; 8 byte, address of text
        .decision:  resq 1          ; 8 byte, address of triggered decision
    endstruc

section .data
    BUFFER_SIZE equ 1048576               ; 1MB
    GAME_DECISION_BUFFER_SIZE equ 1048576     ; 1MB
    GAME_TEXT_BUFFER_SIZE equ 1048576     ; 1MB

    txt_test db "AB", 0
    txt_file_parsing_error db "File parsing error", 0

section .bss
    file_buffer resb BUFFER_SIZE  ; 1MB buffer
    file_size resq 1

    ; Game Data Buffer
    ; - GameData
    ; - 
    game_decision_buffer resb GAME_DECISION_BUFFER_SIZE  ; 1MB buffer
    game_text_buffer resb GAME_TEXT_BUFFER_SIZE  ; 1MB buffer

section .text

    ParseGameFile:
        ; Arguments:
        ; - rcx = unparsed data buffer
        ; Registers:
        ; - rax = current char
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

        lea r10, game_decision_buffer           ; Load game_decision_buffer
        lea r11, game_text_buffer               ; Load game_text_buffer

        mov al, byte [rcx]                      ; Load first character
        
        mov r12, ' '                            ; Replace all whitespaces at the beginning 
        call _parse_game_file_skip_char         ; Skip potential initial whitespace
        
        ; DECISION PARSING

        cmp rax, '['                            ; Check that the decision starts with [
        jne _file_parsing_error                 

        inc rcx
        mov al, byte [rcx]
        mov r12, '='
        call _parse_game_text

        ; lea rax, [file_buffer]
        ; lea rcx, [game_decision_buffer]
        ; movzx dx, byte [rax]

        ; File needs to start with an [
        cmp rdx, '['
        jne _file_parsing_error

        mov r8, ']'

        mov rax, 1
        jmp _end_parsing
        
    _parse_game_text:
        ; r12 = terminator char
        cmp rax, r12
        je _end_parse_game_text     ; End text if the terminator was found
        
        mov [r11], byte al          ; Write into text buffer
        inc r11

        inc rcx                     ; Load next char into rax
        mov al, byte [rcx]
        jmp _parse_game_text

    _end_parse_game_text:
        mov [r11], byte 0                ; Add string terminator
        inc r11
        ret

    _parse_game_file_skip_char:
        cmp rax, r12
        jne _end_skip_whitespace
        inc rcx                                 ; Increment data_buffer address
        mov al, byte [rcx]                      ; Load next char into rax
        jmp _parse_game_file_skip_char
    _end_skip_whitespace:
        ret

    _file_parsing_error:
        mov rcx, txt_file_parsing_error
        call WriteText
        mov rax, 0

    _end_parsing:
        pop r12
        ret
