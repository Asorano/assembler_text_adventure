section .data
    txt_cut_line db "-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-", 10, 0
    txt_cut_line_l equ $ - txt_cut_line

    txt_health db "Health: ", 0
    txt_health_l equ $ - txt_health

    txt_decision_taken db "          Decisions taken: ", 0
    txt_decision_taken_l equ $ - txt_decision_taken

section .text
    RenderGameView:
        mov rcx, txt_cut_line
        mov rdx, txt_cut_line_l
        call WriteText

        mov rcx, txt_health
        mov rdx, txt_health_l
        call WriteText

        ; Write current health
        mov rax, [health]
        mov ecx, eax
        call WriteNumber

        mov rcx, '/'
        call WriteChar

        ; Write max health
        mov rax, [health]
        shr rax, 32
        mov ecx, eax
        call WriteNumber

        mov rcx, txt_decision_taken
        mov rdx, txt_decision_taken_l
        call WriteText

        ; Write decisions taken
        mov rax, [decisions_taken]
        mov ecx, eax
        call WriteNumber

        mov rcx, 10
        call WriteChar
        call WriteChar

        mov rcx, txt_cut_line
        mov rdx, txt_cut_line_l
        call WriteText

        mov rcx, 10
        call WriteChar

        ret