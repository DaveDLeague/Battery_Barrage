#!/bin/bash

if [ $1 == "build" ]
then
    clang++ -c -fpic battery_barrage.cpp && g++ -shared -o libbb.so battery_barrage.o
    clang++ -o game osx_platform.mm -ggdb -D DEBUG_COMPILE -framework Cocoa -framework Metal -framework MetalKit -framework GameController
elif [ $1 == "compile" ]
then
    g++ -c -fpic battery_barrage.cpp && g++ -shared -o libbb.so battery_barrage.o
elif [ $1 == "memoryBuild" ]
then
    clang++ -o game osx_platform.mm -fsanitize=address -fno-omit-frame-pointer -ggdb -D DEBUG_COMPILE -framework Cocoa -framework Metal -framework MetalKit -framework GameController
    
fi