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


GameData* MockGameData() {
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

int parseNextLine(char* source, char* destination) {
    char currentChar = source[0];

    int counter = 0;
    while(currentChar != 0)
    {
        if(currentChar == 0x0A)
        {
            counter++;
            break;
        }

        if(currentChar == 0x0D)
        {
            destination[counter] = 0;
        }
        else {
            destination[counter] = currentChar;
        }

        counter++;
        currentChar = source[counter];
    }

    return counter;
}

void FreeGameData(GameData* pointer) {
    free(pointer->title);
    free(pointer);
}

#define FREE_TEMP_BUFFERS \
    FreeGameData(gameData); \
    free(currentLine);

#define PARSE_METADATA(name, dest) \
    length = parseNextLine(rawData + currentPosition, currentLine); \
    if(length == 0) \
    { \
        printf("Missing metadata %s!\n", #name); \
        FreeGameData(gameData); \
        free(currentLine); \
        return NULL; \
    } \
    dest = (char*) malloc(length); \
    strcpy_s(dest, length, currentLine); \
    printf("[META] %s: %s\n", #name, gameData->name); \
    currentPosition += length;

GameData* ParseGameData(char* rawData, int rawDataLength) {
    GameData* gameData = (GameData*) malloc(sizeof(GameData));
    char* currentLine = (char*)malloc(1024);

    // Parse metadata
    int length;
    int currentPosition = 0;
    PARSE_METADATA(title, gameData->title);
    PARSE_METADATA(author, gameData->author);

    // Parse decisions
    GameDecision* currentDecision = NULL;
    int currentActionIndex = 0;
    while(length != 0)
    {
        length = parseNextLine(rawData + currentPosition, currentLine);
        currentPosition += length;
        // Jump over empty lines
        if(length == 2)
        {
            continue;
        }

        // New decision?
        if(currentLine[0] == '[')
        {
            currentDecision = (GameDecision*) malloc(sizeof(GameDecision));

        }
        else {
            
        }

        printf("%s\n", currentLine);
    }

    free(currentLine);
    return gameData;
}