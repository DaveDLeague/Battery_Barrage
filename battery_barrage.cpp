#include "common_utils.h"

#include "battery_barrage.h"

#include "graphics_math.cpp"
#include "text_renderer.cpp"

void initializeGameState(BatteryBarrageState* bbState){
    bbState->totalFrames = 0;
    u8* fileData;
    u64 fileSize;

    bbState->readFromFile("font atlas builder/arial.fontatlas", fileData, &fileSize);

    loadFontAtlas(fileData, &bbState->textRenderer.fontAtlas);
    
    createTextObject(&bbState->textRenderer, "+3xt T35t", 100, 100, 1);
    createTextObject(&bbState->textRenderer, "5ma113r", 100, 200, 0.5);
    createTextObject(&bbState->textRenderer, "Much L@rg3!", 100, 300, 2);

    bbState->textRenderer.viewProjection = createOrthogonalProjectionMatrix(0, bbState->gameWidth, 0, bbState->gameHeight, -1, 1);
}

extern "C" void updateGameState(float deltaTime, BatteryBarrageState* bbState){
     bbState->textRenderer.textObjects[0].y = 200;
    bbState->textRenderer.textObjects[0].x = 100;
}