#include <stdio.h>
#include <windows.h>
#include <stdint.h>

extern void* CreateLinkedList(HANDLE heapHandle);
extern void* GetLinkedListItemByIndex(void* linkedList, int64_t index);
extern void* GetFirstLinkedListItem(void* linkedList);
extern void* GetLastLinkedListItem(void* linkedList);
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

    int itemCount = 3;

    AppendSomething(handle, linkedList, "Hello");
    AppendSomething(handle, linkedList, "World");
    AppendSomething(handle, linkedList, "!");

    printf("Length: %i\n", GetLinkedListLength(linkedList));

    char* firstText = GetFirstLinkedListItem(linkedList);
    printf("First item: %s\n", firstText);

    char* lastText = GetLastLinkedListItem(linkedList);
    printf("Last item: %s\n", lastText);

    for(int index = 0; index <= itemCount; index++)
    {
        char* indexedText = GetLinkedListItemByIndex(linkedList, index);
        printf("Index[%i]: %s\n", index, indexedText);
    }



    FreeLinkedList(handle, linkedList, FreeText);
}