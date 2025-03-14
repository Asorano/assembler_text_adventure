#include <windows.h>
#include <stdint.h>

typedef struct {
    uint16_t decisionCount;
} GameData;

uint16_t debug_log_decision(const void* buffer) {

    GameData* gameData = (GameData*) buffer;
    return 42;
}