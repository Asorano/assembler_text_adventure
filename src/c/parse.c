#include <stdlib.h>
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

typedef struct {
    char* title;
    char* author;
    int decisionCount;
    GameDecision* decisions;
} GameData;

const char* getFixedTitle() {
    return "Hello World"; // Points to string literal in read-only segment
}

const char* getFixedAuthor() {
    return "Asorano"; // Points to string literal in read-only segment
}

const char* getFirstDecisionTitle() {
    return "Hellothere!"; // Points to string literal in read-only segment
}

GameData* ParseGameData(char* rawData, int rawDataLength) {

    GameData* gameData = (GameData*) malloc(sizeof(GameData));
    gameData->title = getFixedTitle();
    gameData->author = getFixedAuthor();
    gameData->decisionCount = 1;

    GameDecision* decisions = (GameDecision*) malloc(sizeof(GameDecision) * 1);
    gameData->decisions = decisions;
    
    GameDecision firstDecision;
    firstDecision.id = getFirstDecisionTitle();
    firstDecision.text = getFirstDecisionTitle();
    firstDecision.action_0.targetDecisionId = getFirstDecisionTitle();
    firstDecision.action_0.text = getFixedAuthor();

    decisions[0] = firstDecision;

    return gameData;
}

void FreeGameData(GameData* pointer) {
    free(pointer);
}

