#pragma once

#include "renderer.h"

struct FontAtlas{
    u32 totalCharacters;
    u32 totalBitmapWidth;
    u32 totalBitmapHeight;
    u8* bitmap;
    u16* characterCodes;
    u32* xOffsets;
    u32* yOffsets;
    u32* widths;
    u32* heights;
    f32* xShifts;
    f32* yShifts;
};

struct TextObject{
    static const u16 MAX_STRING_LENGTH = 256;
    FontAtlas* fontAtlas;
    s8 text[MAX_STRING_LENGTH];
    u16 textLength;
    f32 scale;
    f32 x;
    f32 y;
};

struct TextRenderer{
    static const u16 MAX_TEXT_OBJECTS = 65535;
    FontAtlas fontAtlas;
    TextObject textObjects[MAX_TEXT_OBJECTS];
    Matrix4 viewProjection;
    u32 totalTextObjects;
    u32 totalVertices;
    u32 totalIndices;
};