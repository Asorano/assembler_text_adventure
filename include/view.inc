section .text
    WritePlayerStats:
        mov rcx, txt_current_health
        mov rdx, txt_current_health_l
        call WriteText

        mov rcx, [current_health]
        call WriteNumber
        call WriteNewLine
        call WriteNewLine
        ret