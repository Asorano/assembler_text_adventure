#define MAX_KEY_LENGTH 256

typedef enum {
    SCALAR,
    MAP,
    LIST
} YamlNodeType;

typedef struct {
    YamlNodeType type;
    int depth;
    char key[MAX_KEY_LENGTH]
} YamlNode;