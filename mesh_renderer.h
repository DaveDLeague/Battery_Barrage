#pragma once

#include "renderer.h"

struct Mesh {
    u32 bufferOffset;
    u32 indexCount;
    Vector3 position;
    Quaternion orientation;
};

struct MeshUniforms {
    Matrix4 perspectiveViewMatrix;
};

struct MeshManager {

};

struct MeshRenderer {
    OSDevice* osDevice;
    RenderDevice* renderDevice;
    Shader shader;
    RenderBuffer vertexBuffer;
    RenderBuffer indexBuffer;
    RenderBuffer uniformBuffer;
    MeshUniforms uniforms;
};
