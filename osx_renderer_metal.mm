#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

#include "renderer.h"

MTLVertexFormat metalVertexFormats[] = {
    MTLVertexFormatFloat,
    MTLVertexFormatFloat2,
    MTLVertexFormatFloat3,
    MTLVertexFormatFloat4
};

MTLPrimitiveType metalPrimitiveTypes[] = {
    MTLPrimitiveTypePoint,
    MTLPrimitiveTypeLine,
    MTLPrimitiveTypeTriangle
};

MTLPixelFormat metalPixelFormats[] = {
    MTLPixelFormatR8Unorm,
    MTLPixelFormatRG8Unorm,
    MTLPixelFormatRG8Unorm, //RGB8 Missing????
    MTLPixelFormatRGBA8Unorm,
};

static id<MTLDevice> device;
static id<MTLCommandQueue> commandQueue;
static id<MTLCommandBuffer> commandBuffer;
static id<MTLRenderCommandEncoder> renderEncoder;
static id<MTLSamplerState> linearSamplerState;
static id<MTLSamplerState> nearestPointSamplerState;
static id<MTLSamplerState>* currentSamplerState;
static MTLTextureDescriptor* textureDescriptor;
static MTKView * view;

static Buffer* currentVertexBuffer;
static Shader* currentShader;
static Texture2D* currentTexture2D;

void METALcreateTexture2DWithData(Texture2D* texture, 
                                  void* data, 
                                  u32 width, u32 height, 
                                  u32 bytesPerRow, 
                                  RendererPixelSize pixelSize, 
                                  u32 mipMapLevel, u32 index){
    
    textureDescriptor.width = width;
    textureDescriptor.height = height;
    textureDescriptor.pixelFormat = metalPixelFormats[pixelSize];

    texture->texture2DData = (void*)[device newTextureWithDescriptor: textureDescriptor];
    MTLRegion region = {
        {0, 0, 0},
        { textureDescriptor.width , textureDescriptor.height, 1}
    };
    [(id<MTLTexture>)texture->texture2DData replaceRegion:region
               mipmapLevel:mipMapLevel
               withBytes:data
               bytesPerRow:bytesPerRow];
}

void METALcreateBufferWithData(Buffer* buffer, void* data, u32 dataSize, u32 index){
    buffer->index = index;
    buffer->bufferData = (void*)[device newBufferWithBytes: data
                                                 length: dataSize
                                                 options: MTLResourceStorageModeShared];
}

void METALcreateShaderFromString(Shader* shader, 
                                 const char* shaderCode, 
                                 const char* vertexFunctionName, 
                                 const char* fragmentFunctionName,
                                 Buffer* vertexBuffer,
                                 VertexBufferDescriptor* vertBufDescriptor){

    NSString* string = [[NSString alloc] initWithCString: shaderCode
                                        encoding: NSUTF8StringEncoding];
    NSError* err = 0;
    shader->shaderLibrary = (void*)[device newLibraryWithSource:string
                                                        options: [[MTLCompileOptions alloc] init] 
                                                        error:&err];
                                                        
    if(err){
        NSLog(@"%@", [err localizedFailureReason]);
    }
    string = [[NSString alloc] initWithCString: vertexFunctionName
                                        encoding: NSUTF8StringEncoding];

    id<MTLFunction> vertexFunction = [(id<MTLLibrary>)shader->shaderLibrary newFunctionWithName:string];
    string = [[NSString alloc] initWithCString: fragmentFunctionName
                                        encoding: NSUTF8StringEncoding];
    id<MTLFunction> fragmentFunction = [(id<MTLLibrary>)shader->shaderLibrary newFunctionWithName:string];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    // pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    // pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    // pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    // pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    // pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    // pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    // pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    u32 totalVerticesAttributes = vertBufDescriptor->totalAttributes;
    MTLVertexDescriptor *vertDescriptor = [MTLVertexDescriptor vertexDescriptor];
    u32 vertexBufferStride = 0;
    for(u32 i = 0; i < totalVerticesAttributes; i++){
        MTLVertexAttributeDescriptor *vertAttribDescriptor = [MTLVertexAttributeDescriptor new];

        vertAttribDescriptor.format = metalVertexFormats[vertBufDescriptor->rendererVertexFormats[i]];
        vertAttribDescriptor.offset = vertBufDescriptor->attributeBufferOffsets[i];
        vertAttribDescriptor.bufferIndex = vertexBuffer->index;
        [vertDescriptor.attributes setObject: vertAttribDescriptor atIndexedSubscript: i];
        vertexBufferStride += sizeof(float) * vertBufDescriptor->attributeDimensions[i];
    }

    MTLVertexBufferLayoutDescriptor *layoutDescriptor = [MTLVertexBufferLayoutDescriptor new];

    layoutDescriptor.stride = vertexBufferStride;
    layoutDescriptor.stepFunction = MTLVertexStepFunctionPerVertex;
    layoutDescriptor.stepRate = 1;
    [vertDescriptor.layouts setObject: layoutDescriptor atIndexedSubscript: vertexBuffer->index];

    pipelineStateDescriptor.vertexDescriptor = vertDescriptor;

    err = 0;
    shader->shaderPipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&err];
    if(err){
        NSLog(@"%@", [err localizedFailureReason]);
    }
}

void METALbindVertexBuffer(Buffer* vertexBuffer){
    currentVertexBuffer = vertexBuffer;
    [renderEncoder setVertexBuffer:(id<MTLBuffer>)currentVertexBuffer->bufferData
                        offset:0
                        atIndex:currentVertexBuffer->index];
}

void METALbindShader(Shader* shader){
    currentShader = shader;
    [renderEncoder setRenderPipelineState:(id<MTLRenderPipelineState>)currentShader->shaderPipelineState];
}

void METALbindTexture2D(Texture2D* texture){
    currentTexture2D = texture;
    [renderEncoder setFragmentTexture:(id<MTLTexture>)texture->texture2DData
                        atIndex:texture->index];
        
    [renderEncoder setFragmentSamplerState:*currentSamplerState atIndex: texture->index];
}

void METALprepareRenderer(){
    commandBuffer = [commandQueue commandBuffer];
    renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:view.currentRenderPassDescriptor];
}

void METALdrawVertices(u32 startVertex, u32 vertexCount, RenderDrawMode mode){
        [renderEncoder drawPrimitives:metalPrimitiveTypes[mode]
                        vertexStart:startVertex
                        vertexCount:vertexCount];
}

void METALfinalizeRenderer(){
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    [view draw];
}

void METALsetClearColor(float r, float g, float b, float a){
    view.clearColor = MTLClearColorMake(r, g, b, a);
}

void METALsetTexture2DSamplerMode(Texture2D* texture, TextureSamplerMode mode){
    switch(mode){
        case TEXTURE_SAMPLER_MODE_NEAREST_PIXEL:{
            currentSamplerState = &nearestPointSamplerState;
            break;
        }
        case TEXTURE_SAMPLER_MODE_LINEAR_INTERPOLATION:{
            currentSamplerState = &linearSamplerState;
            break;
        }
        default: break;
    }
}

void initializeMetalRenderDevice(RenderDevice* renderDevice, NSWindow* window){
    renderDevice->subsystem = RENDERER_SUBSYSTEM_METAL;

    device = MTLCreateSystemDefaultDevice();
    commandQueue = [device newCommandQueue];
    view = [[MTKView alloc] initWithFrame: NSMakeRect(0, 0, 
                                                        window.contentView.frame.size.width, 
                                                        window.contentView.frame.size.width)
                                                        device: device];
    if(!view){
        NSLog(@"Error initializing MTKView object\n");
    }
    view.paused = true;
    view.enableSetNeedsDisplay = false;
    [window setContentView: view];

    textureDescriptor = [[MTLTextureDescriptor alloc] init];

    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterNearest;
    nearestPointSamplerState = [device newSamplerStateWithDescriptor: samplerDescriptor];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterLinear;
    linearSamplerState = [device newSamplerStateWithDescriptor: samplerDescriptor];
    currentSamplerState = &nearestPointSamplerState;

    renderDevice->createTexture2DWithData = METALcreateTexture2DWithData;
    renderDevice->createBufferWithData = METALcreateBufferWithData;
    renderDevice->createShaderFromString = METALcreateShaderFromString;
    renderDevice->bindVertexBuffer = METALbindVertexBuffer;
    renderDevice->bindShader = METALbindShader;
    renderDevice->prepareRenderer = METALprepareRenderer;
    renderDevice->finalizeRenderer = METALfinalizeRenderer;
    renderDevice->drawVertices = METALdrawVertices;
    renderDevice->setClearColor = METALsetClearColor;
    renderDevice->setTexture2DSamplerMode = METALsetTexture2DSamplerMode;
    renderDevice->bindTexture2D = METALbindTexture2D;
}