#pragma once

#include "os.h"
#include "renderer.h"

struct TextUniforms {
    Matrix4 perspectiveMatrix;
    Vector4 colors[256];
};

struct CharacterAtlas {
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

struct TextObject {
    static const u32 MAX_STRING_LENGTH = 256;
    u32 index;
    u32 textLength;
    f32 scale;
    f32 x;
    f32 y;
    Vector4 color;
    s8 text[MAX_STRING_LENGTH];
};

struct TextObjectManager {
    static const u32 MAX_TEXT_OBJECTS = 256;
    u32 totalTextObjects;
    TextObject textObjects[MAX_TEXT_OBJECTS];
};

struct TextRenderer {
    static const u32 MAX_VERTICES = 65536;
    static const u32 MAX_INDICES = (MAX_VERTICES / 4) * 6;
    OSDevice* osDevice;
    RenderDevice* renderDevice;
    RenderBuffer vertexBuffer;
    RenderBuffer indexBuffer;
    RenderBuffer uniformBuffer;
    Shader shader;
    Texture2D characterAtlasTexture;
    CharacterAtlas charAtlas;
    u32 totalVertices;
    u32 totalIndices;
};