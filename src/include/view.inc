section .data
    ; Game Start
    txt_start_box db 10, 10, "*-------------------------------------------------*", 10, "|-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-|", 10, "|-*-*-*-*-*-*-*-*- x64 Adventure -*-*-*-*-*-*-*-*-|", 10, "|-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-|", 10, "|----------------- @2025 Asorano -----------------|", 0

    ; Header
    txt_cut_line db "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*", 0
    txt_health db "   Health: ", 0
    txt_decision_taken db "   Decisions taken: ", 0

    ; Game End
    txt_game_over_box db 10, "|-------------------------------------------------|", 10, "|-*-*-*-*-*-*-*-*-   GAME OVER   -*-*-*-*-*-*-*-*-|", 10, "|-------------------------------------------------|", 10, 10, 0
    txt_game_over_goodbye db "Thank you for playing! Better luck next time!", 0

section .text

    RenderGameIntro:
%if SKIP_INTRO == 1
        ret
%endif
        call ClearOutput
        call ResetCursorPosition

        mov rcx, 0x03
        call SetTextColor

        mov rcx, txt_start_box
        call AnimateText

        mov rdi, 0
    _intro_color_loop:
        sub rsp, 0x28
        mov ecx, 250
        call Sleep
        add rsp, 0x28

        call ClearOutput
        call ResetCursorPosition

        mov rcx, rdi
        call SetTextColor

        mov rcx, txt_start_box
        call WriteText

        inc rdi
        cmp rdi, 0xF
        jne _intro_color_loop

        ; End intro
        sub rsp, 0x28
        mov ecx, 1000
        call Sleep
        add rsp, 0x28

        mov rcx, 0x07
        call SetTextColor
        ret

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