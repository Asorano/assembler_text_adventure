section .text
    WritePlayerStats:
        mov rcx, txt_current_health
        mov rdx, txt_current_health_l
        call WriteText

        mov rcx, [current_health]
        call WriteNumber

        mov rcx, '.'
        call WriteChar

        mov rcx, 10
        call WriteChar
        call WriteChar


        ret