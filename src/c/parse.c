#include <windows.h>
#include <stdint.h>
#include <stdio.h>

const uint8_t MAX_ACTION_COUNT_PER_DECISION = 4;

typedef struct {
    char* targetDecisionId;
    char* text;
} GameAction;

typedef struct {
    char* id;
    char* text;

    GameAction action_0;
    GameAction action_1;
    GameAction action_2;
    GameAction action_3;

} GameDecision;

GameDecision* ParseGameData(char* rawData, int rawDataLength) {
    return NULL;
}