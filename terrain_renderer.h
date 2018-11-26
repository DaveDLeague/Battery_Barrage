#pragma once

#include "renderer.h"

struct TerrainVertex {
    Vector2 position;
};

struct Terrain {
    static const u32 HEIGHTMAP_WIDTH = 8;
    TerrainVertex vertices[HEIGHTMAP_WIDTH][HEIGHTMAP_WIDTH];
};

struct TerrainUniforms {
    Matrix4 projectionViewMatrix;
};

struct TerrainRenderer {
    OSDevice* osDevice;
    RenderDevice* renderDevice;
    Shader shader; 
    RenderBuffer vertexBuffer;
    RenderBuffer indexBuffer;
    RenderBuffer uniformBuffer;
    u32 totalVertices;
    u32 totalIndices;
};