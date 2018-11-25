#pragma once

#include "renderer.h"

struct TerrainVertex {
    Vector2 position;
};

struct Terrain {
    static const u32 HEIGHTMAP_WIDTH = 8;
    TerrainVertex vertices[HEIGHTMAP_WIDTH][HEIGHTMAP_WIDTH];
};

struct TerrainRenderer {
    RenderDevice* device;
    Shader shader; 
    RenderBuffer vertexBuffer;
    RenderBuffer indexBuffer;
    RenderBuffer uniformBuffer;
};