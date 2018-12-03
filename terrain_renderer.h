#pragma once

#include "renderer.h"

struct TerrainUniforms {
    Matrix4 projectionViewMatrix;
    Vector3 lightPosition;
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