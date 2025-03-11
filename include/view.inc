section .data
    ; Header
    txt_cut_line db "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*", 0
    txt_health db "   Health: ", 0
    txt_decision_taken db "   Decisions taken: ", 0

    ; Game End
    txt_game_over_box db 10, "|-------------------------------------------------|", 10, "|-*-*-*-*-*-*-*-*-   GAME OVER   -*-*-*-*-*-*-*-*-|", 10, "|-------------------------------------------------|", 10, 10, 0
    txt_game_over_goodbye db "Thank you for playing! Better luck next time!", 0

section .text
    extern SetConsoleTextAttribute

    RenderGameHeader:

        mov rcx, '/'
        call WriteChar

        mov rcx, txt_cut_line
        call WriteText

        mov rcx, '\'
        call WriteChar

        mov rcx, 10
        call WriteChar

        ; mov rcx, txt_health
        ; call WriteText

        ; ; Write current health
        ; mov rcx, 0x06
        ; call SetTextColor

        ; mov rax, [health]
        ; mov ecx, eax
        ; call WriteNumber

        ; mov rcx, 0x07
        ; call SetTextColor

        ; mov rcx, '/'
        ; call WriteChar

        ; mov rcx, 0x06
        ; call SetTextColor

        ; ; Write max health
        ; mov rax, [health]
        ; shr rax, 32
        ; mov ecx, eax
        ; call WriteNumber

        ; mov rcx, 0x07
        ; call SetTextColor

        mov rcx, txt_decision_taken
        call WriteText

        mov rcx, 0x0E
        call SetTextColor

        ; Write decisions taken
        mov rax, [decisions_taken]
        mov ecx, eax
        call WriteNumber

        mov rcx, 0x07
        call SetTextColor

        mov rcx, 10
        call WriteChar
        call WriteChar

        mov rcx, '\'
        call WriteChar

        mov rcx, txt_cut_line
        call WriteText

        mov rcx, '/'
        call WriteChar

        mov rcx, 10
        call WriteChar

        mov rcx, 0x07
        call SetTextColor

        mov rcx, 10
        call WriteChar

        ret

    SetTextColor:
        ; rcx = color
        sub rsp, 0x28                    ; Shadow space for function call

        mov rdx, rcx
        mov rcx, [handle_console_out]     ; Console handle
        call SetConsoleTextAttribute      ; Change text color

        add rsp, 0x28
        ret

    RenderGameEnd:
        ; Print game over text and ends the process
        mov rcx, 0x0c
        call SetTextColor

        mov rcx, txt_game_over_box
        call AnimateText

        mov rcx, 0x07
        call SetTextColor

        mov rcx, txt_game_over_goodbye
        call AnimateText

        ret