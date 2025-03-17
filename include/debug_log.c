#include <windows.h>
#include <stdint.h>
#include <stdio.h>

const uint8_t MAX_ACTION_COUNT_PER_DECISION = 4;

typedef struct {
    char* linkedDecisionId;
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

void log_action(const GameAction* action) {
    printf("   - Action: %s => %s\n", action->linkedDecisionId, action->text);
}

void log_parsed_decisions(const GameDecision* decisions, uint16_t decisionCount) {
    printf("Parsed %i decisions:\n", decisionCount);

    for(int index = 0; index < decisionCount; index++)
    {
        GameDecision decision = decisions[index];
        printf(" - Decision %i: %s -> %s\n", index, decision.id, decision.text);

        log_action(&decision.action_0);
        log_action(&decision.action_1);
        log_action(&decision.action_2);
        log_action(&decision.action_3);
    }

    //gameData->decisionCount = data.num1;
}