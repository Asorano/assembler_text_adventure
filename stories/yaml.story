author: Benjamin Berger
title: Yamlventure XXL
decisions:
    act_0_initial:
        text: You are in a dark room. What do you do?
        actions:
            - text: Turn on the light
              target: act_0_turn_light_on
            - text: Too creepy already! Just leave
              target: act_0_end_game_immediately

    act_0_turn_light_on:
        text: The light turns on. You see a carnage in front of you. A massacre. A whole pile of corpse.
        actions:
            - text: Turn the light off
              target: act_0_initial

    act_0_end_game_immediately:
        text: The dream is over! Head back to reality.