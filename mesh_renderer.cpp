#include "mesh_renderer.h"

void prepareMeshRenderer(MeshRenderer* meshRenderer){
    RenderDevice* device = meshRenderer->renderDevice;
    device->bindShader(&meshRenderer->shader);
    device->bindVertexBuffer(&meshRenderer->vertexBuffer);
    device->bindIndexBuffer(&meshRenderer->indexBuffer);
    device->bindVertexUniformBuffer(&meshRenderer->uniformBuffer);
    device->enableDepthTesting(true);
}

void renderMeshes(MeshRenderer* meshRenderer, Mesh* meshes, u32 totalMeshes, Camera* camera){
    RenderDevice* device = meshRenderer->renderDevice;
    MeshUniforms* unis = (MeshUniforms*)device->getPointerToBufferData(&meshRenderer->uniformBuffer);
    for(u32 i = 0; i < totalMeshes; i++){
        Matrix4 proj = createPerpectiveProjectionMatrix(70.0, 1280.0 / 720.0, 0.001, 1000.0);
        
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
        unis->perspectiveViewMatrix = mvMatrix;
        device->drawIndices(meshes[i].bufferOffset, meshes[i].indexCount, RENDERER_INDEX_TYPE_U32, RENDER_DRAW_MODE_TRIANGLES); 
    }
}

void initializeMeshRenderer(OSDevice* osDevice, RenderDevice* renderDevice, MeshRenderer* meshRenderer){
    meshRenderer->osDevice = osDevice;
    meshRenderer->renderDevice = renderDevice;

    f32 verts[] = {
        -1, -1, 0, 
        0, 1, 0,
        1, -1, 0,
    };
    u32 elms[] = {
        0, 1, 2, 2, 3, 0,
    };

    renderDevice->createBufferWithData(&meshRenderer->vertexBuffer, verts, sizeof(verts), 0);
    renderDevice->createBufferWithData(&meshRenderer->indexBuffer, elms, sizeof(elms), 1);
    renderDevice->createBufferWithData(&meshRenderer->uniformBuffer, &meshRenderer->uniforms, sizeof(meshRenderer->uniforms), 2);

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

    const s8* pth = osDevice->getPathFromExecutable("mesh_shader.metal");
    osDevice->readTextFile(pth, &shaderText, &fileLength);
    delete[] pth;

    renderDevice->createShaderFromString(&meshRenderer->shader, (const char*)shaderText, "vertexShader", "fragmentShader", &meshRenderer->vertexBuffer, &vbd);
    renderDevice->bindShader(&meshRenderer->shader);
    renderDevice->bindVertexBuffer(&meshRenderer->vertexBuffer);


}