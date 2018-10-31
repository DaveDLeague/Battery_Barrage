#!/bin/bash
xcrun -sdk macosx metal -std=osx-metal1.1 -c -o $1.air $1.metal 
xcrun -sdk macosx metallib $1.air -o $1.metallib
rm $1.air