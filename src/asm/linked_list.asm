default rel

%include "linked_list.inc"

section .text
    global CreateLinkedList, AppendToLinkedList, FreeLinkedList, GetLinkedListLength

    extern GetProcessHeap, HeapAlloc, HeapFree

    ; Creates a new linked list with length 0
    ; # Arguments
    ; - [in]    rcx = Heap handle
    ; - [out]   rax = Pointer to linked list head
    CreateLinkedList:
        ; Proloque
        push rbp
        mov rbp, rsp
        sub rsp, 32

        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, LinkedListHead_size
        call HeapAlloc

        mov qword [rax + LinkedListHead.length], 0

        ; Epiloque
        add rsp, 32
        pop rbp
        ret

    ; Moves the length of a linked list to rax
    ; # Arguments
    ; - [in]    rcx = Pointer to linked list head
    ; - [out]   rax = item count of linked list
    GetLinkedListLength:
        mov rax, [rcx + LinkedListHead.length]
        ret

    ; Adds an item to the linked list
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to head of linked list
    ; - [in]     r8 = pointer to data
    AppendToLinkedList:
        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  8 bytes pointer to list head           (rsp+32)
        ; -  8 bytes pointer to data                (rsp+40)
        ; --------------------------------------------------
        ; => 48 bytes
        sub rsp, 48
        mov [rsp+32], rdx
        mov [rsp+40], r8

        ; Increment length
        inc qword [rdx + LinkedListHead.length]

        ; Allocate item
        ; rcx = heap handle
        mov rdx, 8                  ; flags (HEAP_ZERO_MEMORY = 8)
        mov r8, LinkedListItem_size
        call HeapAlloc

        ; Set the data of the new allocated item
        mov rcx, [rsp+40]
        mov [rax + LinkedListItem.data], rcx

        ; Move new item
        mov rdx, rax

        ; Get first list item
        mov rax, [rsp+32]
        mov rcx, rax
        add rcx, LinkedListHead.head

    _loop_append_to_linked_list:
        cmp qword [rcx], 0x0
        je _append_to_linked_list

        mov rax, [rcx]
        mov rcx, rax
        add rcx, LinkedListItem.next
        jmp _loop_append_to_linked_list

    _append_to_linked_list:
        mov [rcx], rdx

    _end_append_to_linked_list:
        ; Epiloque
        add rsp, 48
        pop rbp
        ret


    ; Frees the memory of a linked list
    ;
    ; Walks through the chain of items and calls the free callback for each of them
    ;
    ; # Arguments
    ; - [in]    rcx = heap handle
    ; - [in]    rdx = pointer to linked list head
    ; - [in]     r8 = callback for freeing the item
    ;
    ; # Callback
    ; - [in]    rcx = Heap handle
    ; - [in]    rdx = pointer to data
    FreeLinkedList:
        ; Return if null pointer
        test rcx, rcx
        jz _ret_free_linked_list

        ; Proloque
        push rbp
        mov rbp, rsp
        ; Stack frame:
        ; - 32 bytes shadow space
        ; -  8 bytes heap handle        (rsp+32)
        ; -  8 bytes free callback      (rsp+40)
        ; -  8 bytes current item       (rsp+48)
        ; -  8 bytes alignment
        ; --------------------------------------
        ; => 64 bytes
        sub rsp, 64
        mov [rsp+32], rcx
        mov [rsp+40],  r8

        mov rax, [rdx + LinkedListHead.head]
        mov [rsp+48], rax

        ; Free the list head
        ; rcx = heap handle
        mov  r8, rdx
        xor rdx, rdx
        call HeapFree

        ; Get the first item pointer
        mov rdx, [rsp+48]

    _loop_free_linked_list:
        ; If the pointer is NULL, the end was reached
        test rdx, rdx
        jz _end_free_linked_list
        
        ; Call the free callback if not NULL
        mov rcx, [rdx + LinkedListItem.data]
        call [rsp+40]

    _free_item:
        ; Store the next item in the stack frame
        mov  r8, [rsp+48]
        mov rcx, [r8 + LinkedListItem.next]
        mov [rsp+48], rcx

        ; Free the current item
        mov rcx, [rsp+32]
        xor rdx, rdx
        call HeapFree

        mov rdx, [rsp+48]
        jmp _loop_free_linked_list

        ; Epiloque
    _end_free_linked_list:
        pop rbp
        add rsp, 64

    _ret_free_linked_list:
        ret
