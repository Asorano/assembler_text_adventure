#include <stdio.h>
#include <stdint.h>

// struc GameAction
//     .linked_decision    resq 1  ; Pointer to linked decision
//     .text               resq 1  ; Pointer to text   
// endstruc
typedef struct {
    char* linked_decision;
    char* text;
} GameAction;

// struc GameDecision 
//     .id:        resq 1  ; Pointer to id string
//     .text:      resq 1  ; Pointer to text string
//     .action_0   resb GameAction_size  ; Pointer to first action
//     .action_1   resb GameAction_size  ; Pointer to second action
//     .action_2   resb GameAction_size  ; Pointer to third action
//     .action_3   resb GameAction_size  ; Pointer to fourth action
// endstruc
typedef struct {
    char* id;
    char* text;

    GameAction action_0;
    GameAction action_1;
    GameAction action_2;
    GameAction action_3;
} GameDecision;

// struc DecisionLinkedList
//     .next               resq 1                  ; Pointer to next decision
//     .decision           resb GameDecision_size  ; Decision
// endstruc
typedef struct {
    void* next;
    GameDecision decision;
} LinkedListItem;

// struc GameData
//     .title              resq 1  ; Pointer to title text
//     .author             resq 1  ; Pointer to autor
//     .decision_count     resq 1  ; Int
//     .decisions          resq 1  ; Pointer to first decision
// endstruc
typedef struct {
    char* title;
    char* author;
    int64_t decision_count;
    LinkedListItem* decisions;
} GameData;

void log_action(GameAction action)
{
    if(action.linked_decision == NULL)
    {
        printf(" - None\n");
    }
    else {
        printf(" - %s <= %s\n", action.linked_decision, action.text);
    }
}

void log_decision(LinkedListItem* item)
{
    printf("Decision: %s => %s\n", item->decision.id, item->decision.text);
    log_action(item->decision.action_0);
    log_action(item->decision.action_1);
    log_action(item->decision.action_2);
    log_action(item->decision.action_3);
}

void log_game_data(GameData* gameData)
{
    printf("------------------------\nGame Data\n------------------------\n - Title: %s\n - Author: %s\n\n", gameData->title, gameData->author);
    
    LinkedListItem* currentItem = gameData->decisions;
    while(currentItem != NULL)
    {
        log_decision(currentItem);
        currentItem = currentItem->next;
    }
}