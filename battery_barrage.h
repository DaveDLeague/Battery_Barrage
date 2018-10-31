#include "common_utils.h"
#include "graphics_math.h"
#include "text_renderer.h"

struct BatteryBarrageState {
    u32 gameWidth;
    u32 gameHeight;

    u64 totalFrames;
    TextRenderer textRenderer;

    void (*readFromFile)(const s8*, u8*&, u64*);
};