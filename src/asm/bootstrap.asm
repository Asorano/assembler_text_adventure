default rel

%macro PRINT_ERROR 1
    mov rcx, 0x4
    call SetTextColor

    mov rcx, %1
    call WriteText

    mov rcx, 0x7
    call SetTextColor
%endmacro

section .data
    story_file_directory db "stories/" ; Exactly 8 bytes
    STORY_FILE_DIRECTORY_LENGTH equ $ - story_file_directory

    search_path db "stories/*.story", 0

    msg_err_no_files db "Seems like a black hole ate all the stories! Noooooooo!", 10, "(No stories found. The files must be located in the 'stories' directory and must have the extension '.stories')", 0
    msg_err_file_parsing db "Oh no, the data overloaded the reactor! EMERGENCY SHUTDOWN!! FAST!", 10, "(The story file is corrupted and could not be parse)", 0
    msg_err_invalid_input db "This story does not exist!", 10, 0

    msg_welcome db "Welcome to the x64 Text Adventures!", 10, 0
    msg_story_selection db "Which story do you want to play?", 10, 0
    msg_input_request db "Please enter the story number:", 10, 0

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, ExitProcess, ClearOutput, ResetCursorPosition, SetTextColor
    extern SetupInput, ReadNumber
    extern GetFileNamesInDirectory, FindFileByPathAndIndex, ReadFileWithCallback, CopyMemory
    extern ParseGameData
    extern RunGame

    global BootstrapGame

; Sets up input, output and console
; Then shows the story file selection and awaits the input from the player
; If a valid file is chosen, parse its content and if the parsing was successful, run the game
;
; Loading the file from the directory is interesting:
; SelectStoryFile will only return the name of the selected file without the correct path (./stories/name.story)
; When a file was successfully selected, the directory ("stories/"), which is exactly 8 bytes long, is copied
; in front of the file name on the stack.
; And then the address of the directory on the stack is used (rsp+8) 
; This would break if the length of the directory name would change!
BootstrapGame:
    ; Stack frame:
    ;   8 bytes result of ParseGameData
    ;   8 bytes for the directory           (rsp+8)
    ; 256 bytes for the file name           (rsp+16)
    ; ---------------------------------------------
    ; => 272
    push rbp
    mov rbp, rsp
    sub rsp, 272

    call SetupOutput
    call SetupInput
    call ResetCursorPosition
    call ClearOutput

    lea rcx, [rsp+16]
    call SelectStoryFile
    test rax, rax
    jz EndGame

    ; Copy the 8 bytes of the directory in front of the file name on the stack
    lea rcx, [story_file_directory]
    lea rdx, [rsp+8]
    mov r8, STORY_FILE_DIRECTORY_LENGTH
    call CopyMemory

    ; Read and parse the file
    lea rcx, [rsp+8]
    mov rdx, ParseGameData
    lea r8, [rsp]
    call ReadFileWithCallback

    ; Proloque
    mov rcx, [rsp]    ; Set first decision as initial decision
    add rsp, 272
    pop rbp

    test rax, rax
    jz PrintParseErrorAndEnd

    test rcx, rcx
    jz PrintParseErrorAndEnd

    ; Start the game with the chosen file
    jmp RunGame

PrintParseErrorAndEnd:
    PRINT_ERROR msg_err_file_parsing

EndGame:
    push rbp
    mov rbp, rsp
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

    test rax, rax
    jz _select_story_no_files

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

_select_story_no_files:
    PRINT_ERROR msg_err_no_files
    mov rax, 0
    jmp _select_story_file_end

_select_story_file_invalid_input:
    PRINT_ERROR msg_err_invalid_input
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