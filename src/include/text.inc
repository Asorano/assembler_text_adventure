section .data
    err_invalid_input: db "You need to enter a value between 1 and ", 0
    err_invalid_action: db "Impossible!", 10, 10, 0
    err_invalid_decision_id: db "A glitch in the space-time continuum has been detected!", 10, "All memories have been erased for safety reasons.", 10, "(The selected action was not properly connected to a decision)", 10, 0

    txt_total_decisions_taken db " decisions taken", 0
    txt_input_confirm db "Your decision is: ", 0
