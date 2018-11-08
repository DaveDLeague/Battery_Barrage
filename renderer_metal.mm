#include "renderer.h"

#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

struct Renderer_Metal{
    id<MTLDevice> device;
    id<MTLCommandQueue> commandQueue;
    id<MTLRenderCommandEncoder> renderEncoder;
    MTKView * view;
};

void createVertexBufferWithData(Renderer* renderDevice, void* data, u32 length, RenderDataType type, Buffer* buffer){
    
}

void setVertexBufferAttributes(Buffer* buffer, u32 totalAttributes, RenderDataType* dataTypes, u32 strides){
    MTLVertexDescriptor *vertDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    for(u32 i = 0; i < totalAttributes; i++){
        MTLVertexAttributeDescriptor *attribDescriptor = [MTLVertexAttributeDescriptor new];
        attribDescriptor.format = MTLVertexFormatFloat2;
        attribDescriptor.offset = 0;
        attribDescriptor.bufferIndex = 0;
        [vertDescriptor.attributes setObject: attribDescriptor atIndexedSubscript: i];
    }
}

void createTextureWithData(){

}

void initializeRenderer(void* osWindow, void* osRenderer, Renderer* renderer){
    NSWindow* window = (NSWindow*)osWindow;
    Renderer_Metal *rndMtl = (Renderer_Metal*)osRenderer;
    renderer->renderDevice = rndMtl;

    rndMtl->device = MTLCreateSystemDefaultDevice();
    rndMtl->commandQueue = [rndMtl->device newCommandQueue];
    NSRect viewRect = NSMakeRect(0, 0, window.frame.size.width, window.frame.size.height); 
    rndMtl->view = [[MTKView alloc] initWithFrame: viewRect
                                             device: rndMtl->device];
    rndMtl->view.paused = true;
    rndMtl->view.enableSetNeedsDisplay = false;
    [window setContentView: rndMtl->view];
}

