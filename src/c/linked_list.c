#include <stdio.h>
#include <windows.h>
#include <stdint.h>

extern void* CreateLinkedList(HANDLE heapHandle);
extern int64_t GetLinkedListLength(void* linkedList);
extern void FreeLinkedList(HANDLE heapHandle, void* linkedList, void (*callback)(void* data));
extern void AppendToLinkedList(HANDLE heapHandle, void* linkedList, void* data);

void FreeText(void* data)
{
    free(data);
}

void AppendSomething(HANDLE handle, void* list, char* text)
{
    char* data = malloc(sizeof(char) * 50);
    strcpy(data, text);
    AppendToLinkedList(handle, list, data);
}

void TestLinkedList()
{
    HANDLE handle = GetProcessHeap();
    void* linkedList = CreateLinkedList(handle);    

    AppendSomething(handle, linkedList, "Hello");
    AppendSomething(handle, linkedList, "World");
    AppendSomething(handle, linkedList, "!");

    printf("Length: %i\n", GetLinkedListLength(linkedList));

    FreeLinkedList(handle, linkedList, FreeText);
}