section .text
    AnimateText:
        ; rcx = address of text
        ; rdx = length of the text

        mov rax, 0

    _animate_loop:
        cmp rax, rdx
        je _end_animate

        ; Sleep
        push rcx
        push rdx
        push rax

        sub rsp, 0x28
        mov ecx, 30
        call Sleep
        add rsp, 0x28

        pop rax
        pop rdx
        pop rcx

        push rax
        push rcx
        push rdx

        add rcx, rax
        mov rcx, [rcx]
        call WriteChar

        pop rdx
        pop rcx
        pop rax

        inc rax

        jmp _animate_loop

    _end_animate:
        ret