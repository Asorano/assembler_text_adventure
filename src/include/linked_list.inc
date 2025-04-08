struc LinkedListHead
    .length             resq 1; Length of linked list
    .head               resq 1; Pointer to head item
endstruc

struc LinkedListItem
    .next               resq 1  ; Pointer to next item
    .data               resq 1  ; Pointer to data of this item
endstruc