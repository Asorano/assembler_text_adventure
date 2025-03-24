default rel

section .data
    txt_no_files db "No files found.", 0
    txt_question db "Which story do you want to load?", 10, 0
    txt_input db "Enter the number: ", 10, 0
    search_path db "stories\\*.story", 0  ; Current directory, all files

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, printf, ExitProcess, ClearOutput, ResetCursorPosition
    extern SetupInput, ReadActionIndex
    extern GetFileNamesInDirectory

    global RunDev

RunDev:
    call SetupOutput
    call SetupInput
    call ResetCursorPosition
    call ClearOutput

    call SelectStoryFile

    sub rsp, 40
    xor ecx, ecx
    call ExitProcess
    add rsp, 40

SelectStoryFile:
    sub rsp, 8

    ; Write question
    lea rcx, [txt_question]
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
    lea rcx, [txt_input]
    call WriteText

    mov rcx, 15
    call ReadActionIndex

    add rsp, 8
    ret

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
