section .text
    WritePlayerStats:
        mov rcx, txt_stats_health
        mov rdx, txt_stats_health_l
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

        mov rcx, '.'
        call WriteChar

        mov rcx, 10
        call WriteChar
        call WriteChar


        ret