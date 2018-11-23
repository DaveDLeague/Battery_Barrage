#include "common_utils.h"

#include "battery_barrage.h"

void initializeGameState(BatteryBarrageState* bbState){
    bbState->totalFrames = 0;
    
}

extern "C" void updateGameState(float deltaTime, BatteryBarrageState* bbState){
   
}