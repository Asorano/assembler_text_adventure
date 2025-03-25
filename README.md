# x64 Text Adventure for Windows
Little text adventure game with content loaded from files in x64 assembly for Windows with nasm, lld-link and clang for learning assembler and how lower levels on a CPU work.

## Setup
- Install **NASM**
- Install llvm with **clang** and **lld-link**
- Install **Make** for building
- Install **x64dbg** and add it to the **PATH** for debugging

## Content: Stories
> To create a new story, create ****.story*** file in the ***stories*** directory.

The game data consists of **decisions** and **actions** and is stored in files with the **.story** extension inside the **stories** directory.

A decision describes a situation and offers up to - currently - 4 possible actions.
The header contains the ID of the decision and the text that is shown when the decision is triggered.
```
[decision_id = "This text describes the current situation to the player"]
linked_decision_id => "The text that describes the action"
another_linked_decision_id => "Another possible action"

[linked_decision_id = "The linked decision from the action above"]
```

If a decision has no action, it will be handled as a game end.

## Building
The building can be configured by the following environment variables:
- ***SKIP_ANIMATIONS***: Disables all animations for faster debugging (1 => skip animations, 0 => play animations)

> Use ```make clean``` after changing environment variables since the *Makefile* does not detect the changes currently

The *Makefile* has two configurations:
- **dev** (default): Builds the game with debug symbols 
- **release**: Builds the game in release mode

The *Makefile* tasks are:
- **clean**: Removes all built artifacts
- **build**: Builds the executable
- **run**: Builds and runs the executable
- **debug**: Builds the executable and starts x64dbg with the built file

## Current Todos
- Use ReadNumber in ReadActionIndex function and move it to the game.asm
- Clean up stack frames in game.asm since the EndGame for example does not properly work due to the stack

## Feature Ideas
- Support dynamic action count instead of the currently hardcoded limit of 4
- Add story title to data file and display it in the intro
- Make Makefile aware of environment variable changes (currently it is not rebuilt when they change)
- Pass the id of the initial decision via command line to continue an adventure

## Code Improvements
- Unify function, proloque and epiloque comments
- Replace strcmp with an own implementation
- Improve the file parsing by allowing characters like \"
- Use the makefile prepare for creating the directories on the Github Runner (fails currently)
- Define proper stack frames for the functions
- Replace fixed-size buffers for game data and game texts with dynamic memory allocation
- Print a proper error when the parsing of the file fails