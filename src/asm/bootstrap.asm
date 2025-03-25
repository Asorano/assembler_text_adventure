default rel

section .data
    txt_welcome db "Welcome to the x64 Text Adventures!", 10, 0

    txt_no_files db "No files found.", 0
    txt_file_not_found db "File not found!", 0
    txt_question db "Which story do you want to play?", 10, 0
    txt_input db "Enter the number: ", 10, 0
    search_path db "stories\\*.story", 0  ; Current directory, all files

section .bss
    file_name resb 256

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, printf, ExitProcess, ClearOutput, ResetCursorPosition, SetTextColor
    extern SetupInput, ReadActionIndex
    extern GetFileNamesInDirectory, FindFileByPathAndIndex

    global BootstrapGame

BootstrapGame:
    call SetupOutput
    call SetupInput
    call ResetCursorPosition
    call ClearOutput
 
    ; Print welcome text in color
    mov rcx, 0x3
    call SetTextColor
    mov rcx, txt_welcome
    call WriteText
    mov rcx, 0x7
    call SetTextColor

    call SelectStoryFile

_end:
    sub rsp, 40
    xor ecx, ecx
    call ExitProcess
    add rsp, 40


_file_not_found:
    mov rcx, txt_file_not_found
    call WriteText
    jmp _end

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

    lea rcx, [search_path]
    mov rdx, 1
    lea r8, [file_name]
    call FindFileByPathAndIndex

    cmp rax, 0
    jne _file_not_found

    lea rcx, [file_name]
    call WriteText

    ; mov rcx, 15
    ; call ReadActionIndex

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
