#include <stdio.h>
#include <windows.h>
#include <stdint.h>

extern void* CreateLinkedList(HANDLE heapHandle);
extern int64_t GetLinkedListLength(void* linkedList);
extern void FreeLinkedList(HANDLE heapHandle, void* linkedList, void (*callback)(void* data));
extern void AppendToLinkedList(HANDLE heapHandle, void* linkedList, void* data);

void FreeText(void* data)
{
    // free(data);
}

void TestLinkedList()
{
    HANDLE handle = GetProcessHeap();
    void* linkedList = CreateLinkedList(handle);    

    char* text = malloc(sizeof(char) * 50);

    text = "Hello";
    AppendToLinkedList(handle, linkedList, text);

    text = "World";
    AppendToLinkedList(handle, linkedList, text);

    text = "!";
    AppendToLinkedList(handle, linkedList, text);

    printf("Length: %i\n", GetLinkedListLength(linkedList));

    FreeLinkedList(handle, linkedList, FreeText);
}