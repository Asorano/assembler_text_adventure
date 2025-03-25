default rel

section .data
    search_path db "stories\\*.story", 0

    msg_welcome db "Welcome to the x64 Text Adventures!", 10, 0
    msg_no_files db "No files found.", 0
    msg_file_not_found db "This story is not written yet! Invalid input.", 0
    msg_story_selection db "Which story do you want to play?", 10, 0
    msg_invalid_input db "This story does not exist!", 10, 0
    msg_input_request db "Enter the number: ", 10, 0

section .bss
    file_name resb 256

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, printf, ExitProcess, ClearOutput, ResetCursorPosition, SetTextColor
    extern SetupInput, ReadNumber
    extern GetFileNamesInDirectory, FindFileByPathAndIndex

    global BootstrapGame

BootstrapGame:
    call SetupOutput
    call SetupInput
    call ResetCursorPosition
    call ClearOutput

    call SelectStoryFile
    test rax, rax
    jz EndGame

    mov rcx, msg_welcome
    call WriteText
    jmp EndGame

SelectStoryFile:
    sub rsp, 8

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
    mov [rsp], rax

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
    lea r8, [file_name]
    call FindFileByPathAndIndex

    cmp rax, 0
    jne _select_story_file_not_found

    mov rax, 1

    lea rcx, [file_name]
    call WriteText

_select_story_file_end:
    add rsp, 8
    ret

_select_story_file_invalid_input:
    mov rcx, msg_invalid_input
    call WriteText
    mov rax, 0
    jmp _select_story_file_end

_select_story_file_not_found:
    mov rcx, msg_file_not_found
    call WriteText
    mov rax, 0
    jmp _select_story_file_end

WriteFileEntry:
    sub rsp, 16
    inc rdx
    mov [rsp], rcx

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

EndGame:
    sub rsp, 40
    xor ecx, ecx
    call ExitProcess
    add rsp, 40