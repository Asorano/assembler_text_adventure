# x64 Text Adventure for Windows
Little text adventure game with content loaded from a file in x64 assembly for Windows with nasm, lld-link and clang.

The project uses a **Makefile** for building.

## Setup
- Install **NASM**
- Install llvm with **clang** and **lld-link**
- Install **Make** for building
- Install **x64dbg** and add it to the **PATH** for debugging

## Content - game.bin
The game data consists of **decisions** and **actions** and is stored in a file called **game.bin** which must reside in the same directory as the executable.

### Decision
A decision describes a situation and offers up to - currently - 4 possible actions.
The header contains the ID of the decision and the text that is shown when the decision is triggered.

```
[decision_id = "This text describes the current situation to the player"]
linked_decision_id => "The text that describes the action"
another_linked_decision_id => "Another possible action"

[linked_decision_id = "The linked decision from the action above"]
```

If a decision has no action, it will be handled as game end.

## Building
The building can be configured by the following environment variables:
- FILE_NAME: Overrides the default file name **game.bin**
- SKIP_ANIMATIONS: Disables all animations for faster debugging (1 => skip animations, 0 => play animations)

The Makefile has two configurations:
- **dev**: Builds the game with debug symbols
- **release**: Builds the game in release mode with enabled animations

The Makefile tasks are:
- **clean**: Removes all built artifacts
- **build**: Builds the executable
- **run**: Builds and runs the executable
- **debug**: Builds the executable and starts x64dbg with the built file

## Feature Ideas
- Pass the file name via command line instead of using an environment variable during building
- Allocate memory on the heap for the file content and the game data instead of fixed-sized buffers
- Support dynamic action count instead of the currently hardcoded limit of 4
- Print a proper error when the parsing of the file fails

## Code Improvements
- Replace strcmp with an own implementation
- Improve the file parsing by allowing characters like \"
- Use the makefile prepare for creating the directories on the Github Runner (fails currently)
- Define proper stack frames for the functions
