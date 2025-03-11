section .data
    txt_cut_line db "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*", 0
    txt_cut_line_l equ $ - txt_cut_line

    txt_health db "   Health: ", 0
    txt_health_l equ $ - txt_health

    txt_decision_taken db "          Decisions taken: ", 0
    txt_decision_taken_l equ $ - txt_decision_taken

section .text
    extern SetConsoleTextAttribute

    RenderGameView:

        mov rcx, '/'
        call WriteChar

        mov rcx, txt_cut_line
        call WriteText

        mov rcx, '\'
        call WriteChar

        mov rcx, 10
        call WriteChar

        mov rcx, txt_health
        mov rdx, txt_health_l
        call WriteText

        ; Write current health
        mov rcx, 0x06
        call SetTextColor

        mov rax, [health]
        mov ecx, eax
        call WriteNumber

        mov rcx, 0x07
        call SetTextColor

        mov rcx, '/'
        call WriteChar

        mov rcx, 0x06
        call SetTextColor

        ; Write max health
        mov rax, [health]
        shr rax, 32
        mov ecx, eax
        call WriteNumber

        mov rcx, 0x07
        call SetTextColor

        mov rcx, txt_decision_taken
        mov rdx, txt_decision_taken_l
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
        mov rdx, txt_cut_line_l
        call WriteText

        mov rcx, '/'
        call WriteChar

        mov rcx, 10
        call WriteChar

        mov rcx, 0x07
        call SetTextColor

        ret

    SetTextColor:
        ; rcx = color
        sub rsp, 0x28                    ; Shadow space for function call

        mov rdx, rcx
        mov rcx, [handle_console_out]     ; Console handle
        call SetConsoleTextAttribute      ; Change text color

        add rsp, 0x28
        ret