#pragma once
#include "common_utils.h"
#include "intrinsics.h"
#include "os.h"
#include "graphics_math.cpp"
#include "camera.cpp"
#include "text_renderer.cpp"
#include "terrain_renderer.cpp"
#include "mesh_renderer.cpp"

struct BatteryBarrageState {
    u32 gameWidth;
    u32 gameHeight;

    u64 totalFrames;
    TextRenderer textRenderer;

    void (*readFromFile)(const s8*, u8*&, u64*);
};