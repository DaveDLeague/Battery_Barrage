#include "terrain_renderer.h"

void initializeTerrain(Terrain* terrain){

}

void prepareTerrainRenderer(TerrainRenderer* terrainRenderer){
    RenderDevice* device = terrainRenderer->renderDevice;
    device->bindShader(&terrainRenderer->shader);
    device->bindVertexBuffer(&terrainRenderer->vertexBuffer);
    device->bindIndexBuffer(&terrainRenderer->indexBuffer);
    device->bindVertexUniformBuffer(&terrainRenderer->uniformBuffer);
    device->enableDepthTesting(true);
}
float x = 0;
float y = 0;
float z = 0;
void renderTerrain(TerrainRenderer* terrainRenderer, Terrain* terrain, Camera* camera){
    RenderDevice* device = terrainRenderer->renderDevice;

    TerrainUniforms* unis = (TerrainUniforms*)device->getPointerToBufferData(&terrainRenderer->uniformBuffer);
    Matrix4 proj = createPerpectiveProjectionMatrix(70.0, 1280.0 / 720.0, 0.001, 1000.0);
    unis->lightPosition = Vector3(x, y, z);
    y+=0.1;
    Matrix4 viewMatrix = createIdentityMatrix();
    viewMatrix.m[3][0] = camera->position.x;
    viewMatrix.m[3][1] = camera->position.y;
    viewMatrix.m[3][2] = camera->position.z;
    viewMatrix = multiply(quaternionToMatrix4(camera->orientation), viewMatrix);
    Vector3 newUp(viewMatrix.m[0][1], viewMatrix.m[1][1], viewMatrix.m[2][1]);
    Vector3 newRight(viewMatrix.m[0][0], viewMatrix.m[1][0], viewMatrix.m[2][0]);
    Vector3 newForward(-viewMatrix.m[0][2], -viewMatrix.m[1][2], -viewMatrix.m[2][2]);
    normalize(&newUp);
    normalize(&newRight);
    normalize(&newForward);
    camera->up = newUp;
    camera->right = newRight;
    camera->forward = newForward;

    Matrix4 mvMatrix = multiply(proj, viewMatrix);
    unis->projectionViewMatrix = mvMatrix;

    device->drawIndices(0, terrainRenderer->totalIndices, RENDERER_INDEX_TYPE_U16, RENDER_DRAW_MODE_TRIANGLES);
}

void initializeTerrainRenderer(OSDevice* osDevice, RenderDevice* renderDevice, TerrainRenderer* terrainRenderer){
    terrainRenderer->osDevice = osDevice;
    terrainRenderer->renderDevice = renderDevice;
    
    u32 totalVertices = 40000;
    f32 width = sqrt(totalVertices);
    u32 totalRects = (u32)(width - 1) * (u32)(width - 1);
    u32 totalFloats = totalVertices * 6;
    u32 totalIndices = totalRects * 6;
    f32* verts = new f32[totalFloats];
    u16* elms = new u16[totalIndices];
    u32 ctr = 0;

    f32 x = -width / 2;
    f32 z = -width / 2;
    f32 s = 1;
    for(int i = 0; i < totalVertices; i++){
        float sinX = sin(x);
        float sinZ = sin(z);
        float cosX = cos(x);
        float cosZ = cos(z);
        verts[ctr++] = x; verts[ctr++] = sinX + sinZ; verts[ctr++] = z;  
        x += s;
        if(x >= width / 2){
            x =  -width / 2;
            z += s;
        } 

        Vector3 v1;
        Vector3 v2;

        if(cosX == 0){
            v1 = Vector3(0, 1, 0);
        }else{
            v1 = normalize(Vector3(1, 1 / cosX, 0));
        }
        if(cosZ == 0){
            v2 = Vector3(0, 1, 0);
        }else{
            v2 = normalize(Vector3(0, 1 / cosZ, 1));
        }

        Vector3 norm = normalize(v1 + v2);

        verts[ctr++] = norm.x;
        verts[ctr++] = norm.y;
        verts[ctr++] = norm.z;
        terrainRenderer->totalVertices++;
    }
    
    ctr = 0;
    u32 elNum = 0;
    int rc = 0;
    for(int i = 0; i < totalRects; i++){
        elms[ctr++] = elNum; 
        elms[ctr++] = elNum + 1; 
        elms[ctr++] = elNum + width;
        elms[ctr++] = elNum + width; 
        elms[ctr++] = elNum + 1; 
        elms[ctr++] = elNum + width + 1;
        rc++;
        if(rc == (u32)width - 1){
            rc = 0;
            elNum += 2;
        }else{
            elNum++;
        }

        terrainRenderer->totalIndices += 6;
    }

    renderDevice->createBufferWithData(&terrainRenderer->vertexBuffer, verts, sizeof(f32) * totalFloats, 0);
    renderDevice->createBufferWithData(&terrainRenderer->indexBuffer, elms, sizeof(u16) * totalIndices, 1);
    renderDevice->createBuffer(&terrainRenderer->uniformBuffer, sizeof(TerrainUniforms), 2);

    delete[] verts;
    delete[] elms;

    RendererVertexFormat rvf[] = {
        RENDERER_VERTEX_FORMAT_F32x3, RENDERER_VERTEX_FORMAT_F32x3
    };
    u32 elemSizes[] = {
        sizeof(float), sizeof(float)
    };
    u32 bufOffs[] = {
        0, sizeof(float) * 3
    };
    VertexBufferDescriptor vbd;
    vbd.totalAttributes = 2;
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