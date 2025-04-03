default rel

%include "data.inc"

%macro PRINT_ERROR 1
    mov rcx, 0x4
    call SetTextColor

    mov rcx, %1
    call WriteText

    mov rcx, 0x7
    call SetTextColor
%endmacro

%macro CLEAN_BOOTSTRAP_STACK 0
    add rsp, 272
    pop rbp
%endmacro

section .data
    story_file_directory db "stories/" ; Exactly 8 bytes
    STORY_FILE_DIRECTORY_LENGTH equ $ - story_file_directory

    search_path db "stories/*.story", 0

    msg_err_no_files db "Seems like a black hole ate all the stories! Noooooooo!", 10, "(No stories found. The files must be located in the 'stories' directory and must have the extension '.stories')", 0
    msg_err_file_parsing db "Oh no, the data overloaded the reactor! EMERGENCY SHUTDOWN!! FAST!", 0
    msg_err_invalid_input db "Seems like you are not good enough with numbers yet to play this game.", 10, 0

    msg_welcome db "Welcome to the x64 Text Adventures!", 10, 0
    msg_story_selection db "Which story do you want to play?", 10, 0
    msg_input_request db "Please enter the story number:", 10, 0

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, ExitProcess, ClearOutput, ResetCursorPosition, SetTextColor
    extern SetupInput, ReadNumber
    extern GetFileNamesInDirectory, FindFileByPathAndIndex, ReadFileWithCallback, CopyMemory
    extern ParseGameData, FreeGameData
    extern RunGame

    global BootstrapGame

; Sets up input, output and console
; Then shows the story file selection and awaits the input from the player
; If a valid file is chosen, parse its content and if the parsing was successful, run the game
;
; Loading the file from the directory is interesting:
; SelectFile will only return the name of the selected file without the correct path (./stories/name.story)
; When a file was successfully selected, the directory ("stories/"), which is exactly 8 bytes long, is copied
; in front of the file name on the stack.
; And then the address of the directory on the stack is used (rsp+8) 
; This would break if the length of the directory name would change!
BootstrapGame:
    ; Proloque:
    push rbp
    mov rbp, rsp

    ; Stack frame:
    ; - 8 bytes pointer to data
    ; - 8 bytes alignment
    ; -------------------------
    ; => 16 bytes
    sub rsp, 16

    call SetupOutput
    call SetupInput
    ; call ResetCursorPosition
    ; call ClearOutput

    ; Returns the pointer to the first decision if successful
    call SelectAndLoadFile

    test rax, rax
    jz EndGame

    jmp EndGame

    ; Start the game with the chosen file
    mov [rsp], rax

    mov rcx, [rsp]
    call RunGame

    ; Free memory again
    ; mov rcx, [rsp]
    ; call FreeGameData
EndGame:
    ; Epiloque:
    ; Additional 16 bytes to get the 32 bytes shadow space
    sub rsp, 16
    xor ecx, ecx
    call ExitProcess
    add rsp, 32
    pop rbp

; Shows the file selection in the console and awaits the player input
; # Parameters
; [out]     rax = Pointer to decision data if successful, 0 if the selection failed
SelectAndLoadFile:
    ; Prologue
    push rbp
    mov rbp, rsp
    ; Stack frame:
    ; -   8 bytes file name buffer address
    ; -   8 bytes for parse result            (rsp+8)
    ; -   8 bytes for the directory           (rsp+16)
    ; - 256 bytes for the file name           (rsp+24)
    ; -   8 bytes alignment
    ; -----------------------------------
    ; => 288 bytes
    sub rsp, 288
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
    lea r8, [rsp+24]
    call FindFileByPathAndIndex

    cmp rax, 0
    jne _select_story_file_invalid_input

    ; Copy the 8 bytes of the directory in front of the file name on the stack
    lea rcx, [story_file_directory]
    lea rdx, [rsp+16]
    mov r8, STORY_FILE_DIRECTORY_LENGTH
    call CopyMemory

    ; Read and parse the file
    lea rcx, [rsp+16]
    mov rdx, ParseGameData
    lea r8, [rsp+8]
    call ReadFileWithCallback 

    ; Check parse result
    test rax, rax
    jz _select_story_file_parse_error

    mov rax, [rsp+8]
    test rax, rax
    jz _select_story_file_parse_error

_select_story_file_end:
    ; Epiloque
    add rsp, 288
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

_select_story_file_parse_error:
    PRINT_ERROR msg_err_file_parsing
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