section .text
    GetActionTarget:
        ; rcx => decision address
        ; rdx => action index
        ; rax = returns action target decision address
        shl rdx, 3  ; multiply by 8 since an action address is 8 bytes, shifting by 3 = rdx * 8
        add rcx, 8
        add rcx, rdx
        mov rax, [rcx]
        ret

    GetActionCount:
        ; rcx => decision address
        mov rax, 0
        add rcx, 8     ; Jump to the first possible action

    _action_counter_loop:
        mov rdx, [rcx]  ; Load the
        cmp rdx, 0
        je _action_return

        inc rax
        add rcx, 8
        jmp _action_counter_loop

    _action_return:
        ret
