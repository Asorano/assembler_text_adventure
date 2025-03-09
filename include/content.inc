section .data
    ; Common

    ; Common Texts
    err_invalid_input: db "You need to enter a value between 1 and ", 0
    err_invalid_input_l equ $ - err_invalid_input

    err_invalid_action: db "Impossible!", 10, 10, 0
    err_invalid_action_l equ $ - err_invalid_action

    txt_game_over db 10, "***************************", 10, "******** GAME OVER ********", 10, "***************************", 10, 10, "Thank you for playing! Better luck next time!", 10, 0
    txt_game_over_l equ $ - txt_game_over

    txt_total_decisions_taken db " decisions taken"
    txt_total_decisions_taken_l equ $ - txt_total_decisions_taken

    txt_input_confirm db "Your decision is: ", 0
    txt_input_confirm_l equ $ - txt_input_confirm

    txt_decision_taken db 10, "---------------------------------------------------------------------------", 10, 10, 0
    txt_decision_taken_l equ $ - txt_decision_taken

    txt_stats_health db 10, "Health: ", 0
    txt_stats_health_l equ $ - txt_stats_health

    ; Decisions
    dc_initial:
        dq txt_dc_initial
        dd txt_dc_initial_l
        dq dc_stage1_light_on
        dq dc_game_end
        dq 0

    txt_dc_initial:
        db  "You are in a dark room. What do you do?", 10, "   1) Turn on the light", 10, "   2) Exit the game. Too creepy here.", 10, 10, 0
    txt_dc_initial_l equ $ - txt_dc_initial

    dc_stage1_light_on:
        dq txt_dc_stage1_light_on
        dd txt_dc_stage1_light_on_l
        dq dc_initial
        dq 0

    txt_dc_stage1_light_on db "The light turns on. You see a carnage in front of you. A massacre. A whole pile of corpse.", 10, "   1) Turn the light off", 10, 10, 0
    txt_dc_stage1_light_on_l equ $ - txt_dc_stage1_light_on

    dc_game_end:
        dq txt_dc_game_end
        dd txt_dc_game_end_l
        dq 0

    txt_dc_game_end db "The dream is over! Head back to reality.", 10, 0
    txt_dc_game_end_l equ $ - txt_dc_game_end