## TODO
- Rename game_decision_buffer?
- Improve the stack frame in the game_loop
- Return the game_decision_buffer address from the Parse function and only have it locally inside
    - Later this can be replaced by allocating memory on the heap
- Add parsing support for \" and \n etc
- Print a proper error when the parsing failed due to wrong symbols
- Support a dynamic count of actions per decision (currently limited to 4)