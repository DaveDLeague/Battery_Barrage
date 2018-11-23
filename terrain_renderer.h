#pragma once

#include "renderer.h"

struct Terrain {
    
};

struct TerrainRenderer {
    RenderDevice* device;
    Shader shader; 
    RenderBuffer vertexBuffer;
    RenderBuffer indexBuffer;
    RenderBuffer uniformBuffer;
};