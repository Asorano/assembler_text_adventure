#include <windows.h>

void print_message(const char* message) {
    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD written;
    WriteConsoleA(hConsole, "Message from C: ", 16, &written, NULL);
    WriteConsoleA(hConsole, message, lstrlenA(message), &written, NULL);
    WriteConsoleA(hConsole, "\r\n", 2, &written, NULL);
}

typedef struct {
    char* title;
} AdventureSummary;


typedef enum {
    Decision,
    Action,
    Text
} GameDataBlock;

int parse_game_file(const char* file_data, int length, char* game_data) {
    char currentChar = file_data[0];

    if(currentChar != '[')
    {
        return 1;
    }

    currentChar = file_data[2];
    game_data[0] = currentChar;
    // int counter = 1;
    // while(currentChar != ']')
    // {
    //     *game_data = currentChar;
    //     game_data++;
    //     currentChar = file_data[counter];
    // }

    // char first_char = *file_data; // Explicitly dereference the pointer
    // return first_char;

    return 0;
}