section .data
    ; Common

    ; Common Texts
    err_invalid_input: db "You need to enter a value between 1 and ", 0

    err_invalid_action: db "Impossible!", 10, 10, 0

    txt_total_decisions_taken db " decisions taken", 0

    txt_input_confirm db "Your decision is: ", 0

    ; Decisions
    dc_initial:
        dq txt_dc_initial
        dq dc_stage1_light_on
        dq dc_game_end
        dq 0

    txt_dc_initial: db  "You are in a dark room. What do you do?", 10, "   1) Turn on the light", 10, "   2) Exit the game. Too creepy here.", 10, 10, 0

    dc_stage1_light_on:
        dq txt_dc_stage1_light_on
        dq dc_initial
        dq 0

    txt_dc_stage1_light_on db "The light turns on. You see a carnage in front of you. A massacre. A whole pile of corpse.", 10, "   1) Turn the light off", 10, 10, 0

    dc_game_end:
        dq txt_dc_game_end
        dq 0

    txt_dc_game_end db "The dream is over! Head back to reality.", 10, 0