#!/bin/bash
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/usr/bin"
metal -std=osx-metal1.1 -o $1.air $1.metal && \
metallib $1.air -o $1.metallib
rm $1.air