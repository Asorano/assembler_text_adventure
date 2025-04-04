#include <stdio.h>

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


typedef struct {
    void* next;
    GameDecision decision;
} LinkedListItem;

void log_action(GameAction action)
{
    if(action.linked_decision == NULL)
    {
        printf("\t- None\n");
    }
    else {
        printf("\- %s <= %s\n", action.linked_decision, action.text);
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
