default rel

section .data
    search_path db "stories\\*.story", 0  ; Current directory, all files

section .text
    extern SetupOutput, WriteText, WriteChar, WriteNumber, printf, ExitProcess
    extern ReadFilesInDirectoryWithCallback

    global RunDev

RunDev:
    call SetupOutput
    lea rcx, [search_path]
    lea rdx, TestPrintFiles
    call ReadFilesInDirectoryWithCallback

    mov rcx, rax
    call WriteNumber

    sub rsp, 40
    xor ecx, ecx
    call ExitProcess
    add rsp, 40

TestPrintFiles:
    call WriteText
    mov rcx, 10
    call WriteChar
    ret
