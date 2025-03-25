default rel

section .data
    search_path db "*.story", 0

    msg_welcome db "Welcome to the x64 Text Adventures!", 10, 0
    msg_no_files db "No files found.", 0
    msg_story_selection db "Which story do you want to play?", 10, 0
    msg_invalid_input db "This story does not exist!", 10, 0
    msg_input_request db "Please enter the story number:", 10, 0

    msg_parsing_file db "Loading game file...", 10, 0

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, ExitProcess, ClearOutput, ResetCursorPosition, SetTextColor
    extern SetupInput, ReadNumber
    extern GetFileNamesInDirectory, FindFileByPathAndIndex, ReadFileWithCallback
    extern ParseGameData
    extern RunGame

    global BootstrapGame

; Sets up input, output and console
; Then shows the story file selection and awaits the input from the player
; If a valid file is chosen, parse its content and if the parsing was successful, run the game
BootstrapGame:
    ; Stack frame:
    ;   8 bytes result of ParseGameData
    ; 256 bytes for the file name           (rsp+8)
    ;   8 bytes alignment
    ; ---------------------------------------------
    ; => 272
    push rbp
    mov rbp, rsp
    sub rsp, 272

    call SetupOutput
    call SetupInput
    call ResetCursorPosition
    call ClearOutput

    lea rcx, [rsp+8]
    call SelectStoryFile
    test rax, rax
    jz _end_game

    mov rcx, msg_parsing_file
    call WriteText

    ; Read and parse the file
    lea rcx, [rsp+8]
    mov rdx, ParseGameData
    lea r8, [rsp]
    call ReadFileWithCallback

    test rax, rax
    jz _end_game

    ; Start the game with the chosen file
    mov rcx, [rsp]    ; Set first decision as initial decision
    call RunGame

_end_game:
    ; Restore stack
    add rsp, 272
    
    sub rsp, 32
    xor ecx, ecx
    call ExitProcess
    add rsp, 32

    pop rbp

; Shows the file selection in the console and awaits the player input
; # Parameters
; [out]     rcx = Pointer to 256-bytes buffer for the file name
; [out]     rax = 1 if success, 0 if the selection failed
SelectStoryFile:
    ; Prologue
    push rbp
    ; Stack frame:
    ; - 8 bytes file name buffer address
    ; -----------------------------------
    ; => 8 bytes
    sub rsp, 8
    mov [rsp], rcx

    ; Write question
    lea rcx, [msg_story_selection]
    call WriteText
    ; Line break
    mov rcx, 10
    call WriteChar
    ; Get file names
    lea rcx, [search_path]
    lea rdx, WriteFileEntry
    call GetFileNamesInDirectory

    ; Line break
    mov rcx, 10
    call WriteChar

    ; Input text
    lea rcx, [msg_input_request]
    call WriteText

    ; Read number input
    call ReadNumber
    cmp rax, -1
    je _select_story_file_invalid_input

    ; The user input is 1 - n but the index starts with 0
    dec rax

    lea rcx, [search_path]
    mov rdx, rax
    mov r8, [rsp]
    call FindFileByPathAndIndex

    cmp rax, 0
    jne _select_story_file_invalid_input

    mov rax, 1

_select_story_file_end:
    ; Epiloque
    add rsp, 8
    pop rbp
    ret

_select_story_file_invalid_input:
    mov rcx, msg_invalid_input
    call WriteText
    mov rax, 0
    jmp _select_story_file_end

; Prints the name of a file in this format "n) File name"
; # Parameters:
; - [in]    rcx = Pointer to the file name string
; - [in]    rdx = Index of the file
WriteFileEntry:
    sub rsp, 16
    mov [rsp], rcx

    inc rdx
    mov rcx, rdx
    call WriteNumber

    mov rcx, ')'
    call WriteChar

    mov rcx, ' '
    call WriteChar

    mov rcx, [rsp]
    call WriteText

    mov rcx, 10
    call WriteChar

    add rsp, 16
    ret