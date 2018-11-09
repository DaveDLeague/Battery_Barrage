#pragma once

enum RendererSubsystem {
    RENDERER_SUBSYSTEM_METAL,
    RENDERER_SUBSYSTEM_DX11,
    RENDERER_SUBSYSTEM_OPENGL,

    TOTAL_RENDERER_SUBSYSTEMS
};

enum RendererIndexType {
    RENDERER_INDEX_TYPE_U16,
    RENDERER_INDEX_TYPE_U32,
};

enum RendererVertexFormat {
    RENDERER_VERTEX_FORMAT_F32,
    RENDERER_VERTEX_FORMAT_F32x2,
    RENDERER_VERTEX_FORMAT_F32x3,
    RENDERER_VERTEX_FORMAT_F32x4,

    TOTAL_RENDERER_VERTEX_FORMATS
};

enum RendererPixelSize {
    RENDERER_PIXEL_SIZE_R8,
    RENDERER_PIXEL_SIZE_R8G8,
    RENDERER_PIXEL_SIZE_R8G8B8,
    RENDERER_PIXEL_SIZE_R8G8B8A8,
    RENDERER_PIXEL_SIZE_R16,
    RENDERER_PIXEL_SIZE_R16G16,
    RENDERER_PIXEL_SIZE_R16G16B16,
    RENDERER_PIXEL_SIZE_R16G16B16A16,
    RENDERER_PIXEL_SIZE_R32,
    RENDERER_PIXEL_SIZE_R32G32,
    RENDERER_PIXEL_SIZE_R32G32B32,
    RENDERER_PIXEL_SIZE_R32G32B32A32,

    TOTAL_RENDER_PIXEL_SIZES
};

enum RenderDrawMode {
    RENDER_DRAW_MODE_POINTS,
    RENDER_DRAW_MODE_LINES,
    RENDER_DRAW_MODE_TRIANGLES,

    TOTAL_RENDER_DRAW_MODES
};

enum TextureSamplerMode {
    TEXTURE_SAMPLER_MODE_NEAREST_PIXEL,
    TEXTURE_SAMPLER_MODE_LINEAR_INTERPOLATION,

    TOTAL_TEXTURE_SAMPLER_MODES
};

struct Texture2D {
    u32 index;
    void* texture2DData;
    void* textureSamplerDescriptor;
};

struct Buffer {
    u32 index;
    void* bufferData;
};

struct Shader {
    void* shaderLibrary;
    void* shaderPipelineState;
};

struct VertexBufferDescriptor {
    u8 totalAttributes;
    RendererVertexFormat* rendererVertexFormats;
    u32* attributeElementSizes;
    u32* attributeBufferOffsets; 
};

struct RenderDevice {
    RendererSubsystem subsystem;
    void (*createTexture2DWithData)(Texture2D* texture, 
                                  void* data, 
                                  u32 width, u32 height, 
                                  u32 bytesPerRow, 
                                  RendererPixelSize pixelSize, 
                                  u32 mipMapLevel, u32 index);
    void (*createBuffer)(Buffer* buffer, u32 size, u32 index);
    void (*createBufferWithData)(Buffer* buffer, void* data, u32 size, u32 index);
    void (*createShaderFromString)(Shader* shader, 
                                   const char* shaderCode, 
                                   const char* vertexFunctionName, 
                                   const char* fragmentFunctionName,
                                   Buffer* vertexBuffer,
                                   VertexBufferDescriptor* vertBufDescriptor);
    void (*bindVertexBuffer)(Buffer* vertexBuffer);
    void (*bindIndexBuffer)(Buffer* indexBuffer);
    void (*bindVertexUniformBuffer)(Buffer* vertUniBuffer);
    void (*bindFragmentUniformBuffer)(Buffer* fragUniBuffer);
    void (*bindShader)(Shader* shader);
    void (*bindTexture2D)(Texture2D* texture);
    void (*setTexture2DSamplerMode)(Texture2D* texture, TextureSamplerMode mode);
    void (*prepareRenderer)(void);
    void (*finalizeRenderer)(void);
    void (*drawVertices)(u32 startVertex, u32 vertexCount, RenderDrawMode mode);
    void (*drawIndices)(u32 offset, u32 count, RendererIndexType type, RenderDrawMode mode);
    void (*setClearColor)(float r, float g, float b, float a);
    void* (*getPointerToBufferData)(Buffer* b);
};