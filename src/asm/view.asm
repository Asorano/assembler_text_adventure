default rel

%include "data.inc"

section .data
    ; Game Start
    txt_start_box_line_top db "*-------------------------------------------------*", 10, 0
    txt_start_box_line_star db "|-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-|", 10, 0
    txt_start_box_line_game_name db "|-*-*-*-*-*-*-*-*- x64 Adventure -*-*-*-*-*-*-*-*-|", 10, 0
    txt_start_box_line_copyright db "|----------------- @2025 Asorano -----------------|", 0

    ; Story intro
    msg_story_intro_header db "You are playing:", 10, 0
    msg_story_intro_author db "by ", 0

    ; Header
    txt_cut_line db "*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*", 0
    txt_health db "   Health: ", 0
    txt_decision_taken db "   Decisions taken: ", 0

    ; Game End
    txt_game_over_box db "|-------------------------------------------------|", 10, "|-*-*-*-*-*-*-*-*-   GAME OVER   -*-*-*-*-*-*-*-*-|", 10, "|-------------------------------------------------|", 10, 10, 0
    txt_game_over_goodbye db "Thank you for playing! Better luck next time!", 0

section .text
    extern SetTextColor, WriteText, WriteChar, WriteNumber, AnimateText, ClearOutput, ResetCursorPosition
    extern Sleep
    global RenderStoryIntro, RenderGameIntro, RenderGameHeader, RenderGameEnd, RenderDecision

    ; Renders the title and the author
    ; # Parameters:
    ; - [in]    rcx = Pointer to the GameData
    RenderStoryIntro:
%if SKIP_ANIMATIONS == 1
        ret
%endif

        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 8 bytes address to GameData
        ; - 8 bytes alignment
        ; -----------------------------
        ; => 16 bytes
        sub rsp, 16
        mov [rsp], rcx

        mov rcx, 0x8
        call SetTextColor

        mov rcx, txt_start_box_line_top
        call WriteText

        mov rcx, 0xE
        call SetTextColor

        mov rcx, msg_story_intro_header
        call AnimateText

        mov rcx, 0x7
        call SetTextColor

        mov rcx, [rsp]
        mov rcx, [rcx]
        call AnimateText

        mov rcx, 10
        call WriteChar

        mov rcx, 0x8
        call SetTextColor

        mov rcx, msg_story_intro_author
        call AnimateText

        mov rcx, [rsp]
        mov rcx, [rcx+GameData.author]
        call AnimateText

        mov rcx, 10
        call WriteChar

        mov rcx, 0x8
        call SetTextColor

        mov rcx, txt_start_box_line_top
        call WriteText

        mov rcx, 0x7
        call SetTextColor

        mov rcx, 2000
        call Sleep

        add rsp, 16
        pop rbp
        ret

    RenderGameIntro:
%if SKIP_ANIMATIONS == 1
        ret
%endif
        call ClearOutput
        call ResetCursorPosition

        mov rcx, 0x03
        call SetTextColor

        mov rcx, txt_start_box_line_top
        call WriteText

        ; End intro
        sub rsp, 0x28
        mov ecx, 200
        call Sleep
        add rsp, 0x28

        mov rcx, txt_start_box_line_star
        call WriteText

        ; End intro
        sub rsp, 0x28
        mov ecx, 200
        call Sleep
        add rsp, 0x28

        mov rcx, txt_start_box_line_game_name
        call WriteText

        ; End intro
        sub rsp, 0x28
        mov ecx, 200
        call Sleep
        add rsp, 0x28

        mov rcx, txt_start_box_line_star
        call WriteText

        ; End intro
        sub rsp, 0x28
        mov ecx, 200
        call Sleep
        add rsp, 0x28

        mov rcx, txt_start_box_line_copyright
        call WriteText

        ; End intro
        sub rsp, 0x28
        mov ecx, 500
        call Sleep
        add rsp, 0x28

        mov rdi, 0
    _intro_color_loop:
        sub rsp, 0x28
        mov ecx, 200
        call Sleep
        add rsp, 0x28

        call ClearOutput
        call ResetCursorPosition

        mov rcx, rdi
        call SetTextColor

        mov rcx, txt_start_box_line_top
        call WriteText
        mov rcx, txt_start_box_line_star
        call WriteText
        mov rcx, txt_start_box_line_game_name
        call WriteText
        mov rcx, txt_start_box_line_star
        call WriteText
        mov rcx, txt_start_box_line_copyright
        call WriteText

        inc rdi
        cmp rdi, 0xF
        jne _intro_color_loop

        ; End intro
        sub rsp, 0x28
        mov ecx, 300
        call Sleep
        add rsp, 0x28

        mov rcx, 0x07
        call SetTextColor
        ret

    ; Arguments:
    ; - [in]    rcx = taken decision count
    RenderGameHeader:
        ; Stack frame:
        ; - 8 bytes (decisions taken)
        ; - 8 bytes alignment
        ; ---------------------------
        ; => 16 bytes
        sub rsp, 16
        mov [rsp], rcx

        mov rcx, 0x0B
        call SetTextColor

        mov rcx, '/'
        call WriteChar

        mov rcx, txt_cut_line
        call WriteText

        mov rcx, '\'
        call WriteChar

        mov rcx, 10
        call WriteChar

        mov rcx, txt_decision_taken
        call WriteText

        mov rcx, 0x06
        call SetTextColor

        ; Write decisions taken
        mov rcx, [rsp]
        call WriteNumber

        mov rcx, 0x0B
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

        mov rcx, 0x07
        call SetTextColor

        add rsp, 16
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

        mov rcx, 10
        call WriteChar

        ret

    ; Prints a decision
    ; # Arguments:
    ; - [in]    rcx = Pointer to decision
    RenderDecision:
        push rbp
        mov rbp, rsp

        mov rsi, rcx

        mov rcx, [rcx + GameDecision.text]
        call AnimateText

        mov rcx, 10
        call WriteChar

        mov rcx, 10
        call WriteChar

        mov rcx, rsi
        call RenderActions

        pop rbp
        ret

    ; Prints the action texts of a decision
    ; # Arguments:
    ; - [in]    rcx = Pointer to decision
    ; # Registers:
    ; - r12 = Current action address (after initialization)
    ; - r12 = Current action number (index + 1) 
    RenderActions:
        ; Save caller-saved registers (windows calling convetion)
        push rbp
        mov rbp, rsp

        push r12
        push r13

        ; Initialize registers
        mov r12, rcx                                        ; r12 now contains the address of the decision
        add r12, GameDecision.action_0 + GameAction.text    ; Add the offset to the first action and the offset of the action target address to get the text address 

        ; Initialize action counter
        mov r13, 1

    _write_actions_loop:
        ; Check that the max action count was not reached yet
        cmp r13, MAX_ACTION_COUNT
        jae _end_write_actions_loop
        
        ; Check whether the text address of the action is valid
        ; If the address is 0x0, there is no further action
        mov rax, [r12]
        test rax, rax
        jz _end_write_actions_loop

        ; Write action to console
        mov rcx, r12
        mov rdx, r13
        call RenderAction

        ; Update current action address by adding the size of a GameAction
        add r12, GameAction_size
        inc r13
        jmp _write_actions_loop

    _end_write_actions_loop:
        ; Write line break
        mov rcx, 10
        call WriteChar

        ; Restore caller-saved registers (windows calling convention)
        pop r13
        pop r12
        pop rbp

        ret

    ; Prints a single action
    ; # Arguments:
    ; - [in]    rcx = Address of the action
    ; - [in]    rdx = Action index
    RenderAction:
        push rcx

        ; Write action number
        mov rcx, rdx
        call WriteNumber
        ; Write )
        mov rcx, ')'
        call WriteChar
        ; Write space
        mov rcx, ' '
        call WriteChar
        ; Write action text
        pop rcx
        mov rcx, [rcx]
        call AnimateText
        ; Write line break
        mov rcx, 10
        call WriteChar

        ret
