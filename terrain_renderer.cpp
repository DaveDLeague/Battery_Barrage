#include "terrain_renderer.h"

void initializeTerrain(Terrain* terrain){

}

void prepareTerrainRenderer(TerrainRenderer* terrainRenderer){
    RenderDevice* device = terrainRenderer->renderDevice;
    device->bindShader(&terrainRenderer->shader);
    device->bindVertexBuffer(&terrainRenderer->vertexBuffer);
    device->bindIndexBuffer(&terrainRenderer->indexBuffer);
    device->bindVertexUniformBuffer(&terrainRenderer->uniformBuffer);
}

void renderTerrain(TerrainRenderer* terrainRenderer, Terrain* terrain, Camera* camera){
    RenderDevice* device = terrainRenderer->renderDevice;

    TerrainUniforms* unis = (TerrainUniforms*)device->getPointerToBufferData(&terrainRenderer->uniformBuffer);
    Matrix4 proj = createPerpectiveProjectionMatrix(70.0, 1280.0 / 720.0, 0.001, 1000.0);
    Matrix4 viewMatrix = createIdentityMatrix();
    viewMatrix.m[3][0] = camera->position.x;
    viewMatrix.m[3][1] = camera->position.y;
    viewMatrix.m[3][2] = camera->position.z;
    Matrix4 mvMatrix = multiply(proj, viewMatrix);
    unis->projectionViewMatrix = mvMatrix;

    device->drawIndices(0, terrainRenderer->totalIndices, RENDERER_INDEX_TYPE_U16, RENDER_DRAW_MODE_TRIANGLES);
}

void initializeTerrainRenderer(OSDevice* osDevice, RenderDevice* renderDevice, TerrainRenderer* terrainRenderer){
    terrainRenderer->osDevice = osDevice;
    terrainRenderer->renderDevice = renderDevice;

    u8* fontFileData;
    u64 len;

    u32 totalFloats = 1000 * 4 * 3;
    u32 totalVerts = totalFloats / 12;
    u32 totalElements = totalVerts * 6;
    f32* verts = new f32[totalFloats];
    u16* elms = new u16[totalElements];

    

    float startX = -sqrt(totalVerts) / 2;
    float startZ = -sqrt(totalVerts) / 2;
    float s = 1;
    u32 ctr = 0;

    for(int i = 0; i < totalVerts; i++){

        verts[ctr++] = startX;     verts[ctr++] = sin(startX) + sin(startZ); verts[ctr++] = startZ;
        verts[ctr++] = startX;     verts[ctr++] = sin(startX) + sin(startZ + s); verts[ctr++] = startZ + s;
        verts[ctr++] = startX + s; verts[ctr++] = sin(startX + s) + sin(startZ + s); verts[ctr++] = startZ + s;
        verts[ctr++] = startX + s; verts[ctr++] = sin(startX + s) + sin(startZ); verts[ctr++] = startZ;
        terrainRenderer->totalVertices += 4;
        startX += s;
        if(startX >= sqrt(totalVerts) / 2){
            startX = -sqrt(totalVerts) / 2;
            startZ += s;
        }
    }

    ctr = 0;
    u32 num = 0;
    for(int i = 0; i < totalVerts; i++){
        elms[ctr++] = num; elms[ctr++] = num + 1; elms[ctr++] = num + 2;
        elms[ctr++] = num + 2; elms[ctr++] = num + 3; elms[ctr++] = num;
        num += 4;
        terrainRenderer->totalIndices += 6;
    }

    renderDevice->createBufferWithData(&terrainRenderer->vertexBuffer, verts, sizeof(f32) * totalFloats, 0);
    renderDevice->createBufferWithData(&terrainRenderer->indexBuffer, elms, sizeof(u16) * totalElements, 1);
    renderDevice->createBuffer(&terrainRenderer->uniformBuffer, sizeof(TerrainUniforms), 2);
    
    delete[] verts;
    delete[] elms;

    RendererVertexFormat rvf[] = {
        RENDERER_VERTEX_FORMAT_F32x3
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

    const s8* pth = osDevice->getPathFromExecutable("terrain_shader.metal");
    osDevice->readTextFile(pth, &shaderText, &fileLength);
    delete[] pth;

    renderDevice->createShaderFromString(&terrainRenderer->shader, (const char*)shaderText, "vertexShader", "fragmentShader", &terrainRenderer->vertexBuffer, &vbd);
    renderDevice->bindShader(&terrainRenderer->shader);
    renderDevice->bindVertexBuffer(&terrainRenderer->vertexBuffer);
}