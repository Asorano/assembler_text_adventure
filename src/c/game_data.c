#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

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

GameDecision* GetDecisionById(GameData* gameData, char* id)
{
    printf("Looking for %s in story %s \n", id, gameData->title);

    for(int index = 0; index < gameData->decisionCount; index++)
    {
        GameDecision decision = gameData->decisions[index];

        if(strcmp(decision.id, id) == 0)
        {
            return &(gameData->decisions[index]);
        }
    }

    return NULL;
}

GameData* ParseGameData(char* rawData, int rawDataLength) {
    GameData* gameData = (GameData*) malloc(sizeof(GameData));
    gameData->title = "The biggest adventure yet!";
    gameData->author = "Asorano";
    gameData->decisionCount = 3;

    GameDecision* decisions = (GameDecision*) malloc(sizeof(GameDecision) * 3);
    gameData->decisions = decisions;
    
    GameDecision firstDecision;
    firstDecision.id = "act_0_initial";
    firstDecision.text = "You are in a dark room. What do you do?";
    firstDecision.action_0.targetDecisionId = "act_0_turn_light_on";
    firstDecision.action_0.text = "Turn the light on";
    firstDecision.action_1.targetDecisionId = "act_0_end_game_immediately";
    firstDecision.action_1.text = "Too creepy already! Just leave";
    firstDecision.action_2.targetDecisionId = NULL;
    firstDecision.action_2.text = NULL;

    GameDecision secondDecision;
    secondDecision.id = "act_0_turn_light_on";
    secondDecision.text = "The light turns on. You see a carnage in front of you. A massacre. A whole pile of corpse.";
    secondDecision.action_0.targetDecisionId = "act_0_initial";
    secondDecision.action_0.text = "Turn the light off";
    secondDecision.action_1.targetDecisionId = NULL;
    secondDecision.action_1.text = NULL;

    GameDecision thirdDecision;
    thirdDecision.id = "act_0_end_game_immediately";
    thirdDecision.text = "The dream is over! Head back to reality.";
    thirdDecision.action_0.targetDecisionId = NULL;
    thirdDecision.action_0.text = NULL;

    decisions[0] = firstDecision;
    decisions[1] = secondDecision;
    decisions[2] = thirdDecision;

    return gameData;
}

void FreeGameData(GameData* pointer) {
    free(pointer);
}

