default rel
BITS 64

%include "data.inc"

section .text
    extern game_decision_buffer, game_decision_count, game_text_buffer

    global ParseGameData

    ParseGameData:
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
        ; 5) Check next char to be " and skip it
        ;   1) Throw error if not "
        ; 6) Parse decision text until first "
        ;   1) Remember length of text
        ; 7)  current_text_address -= text_length 
        ; 8) Put text into current_text_address
        ; 9) Add GameDecision_size to current_decision_address (r10)
        ; 10) Parse next decision

        ; PREPARATION

        sub rsp, 16
        mov [rsp+8], r12                                ; Save non-volatile register for restoring at the end

        mov r10, game_decision_buffer           ; Load game_decision_buffer
        mov r11, game_text_buffer               ; Load game_text_buffer
        
        ; Move the last adress of the data_buffer to r9
        mov r9 , rdx                           
        add r9, rcx
        dec r9

        mov [game_decision_count], word 0       ; Total number of decisions, initialized to 0

        movzx rax, byte [rcx]                      ; Load first character
        
        mov r12, ' '                            ; Replace all whitespaces at the beginning 
        call SkipChar         ; Skip potential initial whitespace
        
        ; DECISION PARSING

    _parse_decision:
        cmp rax, '['                            ; Check that the decision starts with [
        jne _file_parsing_error                 

        ; Increment decision count
        inc word [game_decision_count]

        ; Mov current text address to current decision
        mov [r10], r11
        add r10, 8

        ; Parse decision id
        inc rcx
        movzx rax, byte [rcx]
        mov r12, '='
        call ParseTextIntoBuffer

        mov r12, ' '
        call SkipChar

        ; Check that the next sign is a " and jump over it
        mov r12, 0x22
        call CheckCharAndSkip

        ; Set decision text pointer
        mov [r10], r11
        add r10, 8

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

        mov r12, 0x0A
        call CheckCharAndSkip

        mov r12, 0x0A
        call SkipChar

        mov r12, ' '
        call SkipChar

        cmp rax, 0
        je _end_parsing

        ; ACTION PARSING
        ; An action can only have up to 4 decisions. They can be null
        call ParseActions
        call ParseActions
        call ParseActions
        call ParseActions

        cmp rax, 0
        je _end_parsing

        jmp _parse_decision

    _file_parsing_error:
        mov rax, 0

    _end_parsing:
        lea rax, [game_decision_buffer]
        mov r12, [rsp+8]
        add rsp, 16
        ret

    ParseActions:
        mov r12, ' '
        call SkipChar

        cmp rax, 0
        je _skip_action

        ; If char is [, it is the next decision and we need to stop
        cmp rax, '['
        je _skip_action

        ; Set linked decision pointer to current text addres
        mov [r10], r11
        add r10, 8

        ; Read id til next space
        mov r12, ' '
        call ParseTextIntoBuffer

        ; Skip following spaces
        mov r12, ' '
        call SkipChar

        mov r12, '='
        call CheckCharAndSkip

        mov r12, '>'
        call CheckCharAndSkip

        ; Skip following spaces
        mov r12, ' '
        call SkipChar

        mov r12, 0x22
        call CheckCharAndSkip

        ; Set text address pointer
        mov [r10], r11
        add r10, 8  

        ; Read text until next "
        mov r12, 0x22
        call ParseTextIntoBuffer

        mov r12, ' '
        call SkipChar

        mov r12, 0x0A
        call SkipChar
        ret

    _skip_action:
        add r10, GameAction_size
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