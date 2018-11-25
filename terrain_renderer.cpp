#include "terrain_renderer.h"

void initializeTerrain(Terrain* terrain){

}

void prepareTerrainRenderer(TerrainRenderer* terrainRenderer){
    RenderDevice* device = terrainRenderer->renderDevice;
    device->bindShader(&terrainRenderer->shader);
    device->bindVertexBuffer(&terrainRenderer->vertexBuffer);
    device->bindIndexBuffer(&terrainRenderer->indexBuffer);
}

void renderTerrain(TerrainRenderer* terrainRenderer, Terrain* terrain){
    RenderDevice* device = terrainRenderer->renderDevice;
    device->drawIndices(0, 3, RENDERER_INDEX_TYPE_U16, RENDER_DRAW_MODE_TRIANGLES);
}

void initializeTerrainRenderer(OSDevice* osDevice, RenderDevice* renderDevice, TerrainRenderer* terrainRenderer){
    terrainRenderer->osDevice = osDevice;
    terrainRenderer->renderDevice = renderDevice;

    u8* fontFileData;
    u64 len;

    f32 verts[] = {
        -0.5, -0.5,
        0.0, 0.5,
        0.5, -0.5
    };

    u16 elms[] = {
        0, 1, 2 
    };

    renderDevice->createBufferWithData(&terrainRenderer->vertexBuffer, verts, sizeof(verts), 0);
    renderDevice->createBufferWithData(&terrainRenderer->indexBuffer, elms, sizeof(elms), 1);
    
    RendererVertexFormat rvf[] = {
        RENDERER_VERTEX_FORMAT_F32x2
    };
    u32 elemSizes[] = {
        sizeof(float)
    };
    u32 bufOffs[] = {
        0
    };
    VertexBufferDescriptor vbd;
    vbd.totalAttributes = 1;
    vbd.rendererVertexFormats = rvf;
    vbd.attributeElementSizes = elemSizes;
    vbd.attributeBufferOffsets = bufOffs;

    s8* shaderText;
    u64 fileLength;
    osDevice->readTextFile("terrain_shader.metal", &shaderText, &fileLength);

    renderDevice->createShaderFromString(&terrainRenderer->shader, (const char*)shaderText, "vertexShader", "fragmentShader", &terrainRenderer->vertexBuffer, &vbd);
    renderDevice->bindShader(&terrainRenderer->shader);
    renderDevice->bindVertexBuffer(&terrainRenderer->vertexBuffer);
}