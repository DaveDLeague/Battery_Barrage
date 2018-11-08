#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <GameController/GameController.h>
#include <dlfcn.h>

#include "common_utils.h"
#include "renderer_metal.mm"
#include "battery_barrage.cpp"

#define WIDTH 900
#define HEIGHT 500

@class WindowDelegate;
@interface WindowDelegate : NSView <NSWindowDelegate> {
@public
	NSRect windowRect;
}   
@end

@implementation WindowDelegate
-(void)windowWillClose:(NSNotification *)notification {
	[NSApp terminate:self];
}
@end

void readFile(const s8* fileName, u8*& fileData, u64* fileLength){
    NSString* string = [[NSString alloc] initWithCString: fileName
                                        encoding: NSUTF8StringEncoding];
    NSData* data = [NSData dataWithContentsOfFile: string];
    
    *fileLength = [data length];
    fileData = (u8*)[data bytes];
}

int main(int argc, char** argv){ 
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init]; 
    [NSApp sharedApplication];

    NSUInteger windowStyle = NSWindowStyleMaskTitled        | 
                             NSWindowStyleMaskClosable      | 
                             NSWindowStyleMaskResizable     | 
                             NSWindowStyleMaskMiniaturizable;

	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect viewRect = NSMakeRect(0, 0, WIDTH, HEIGHT); 
	NSRect windowRect = NSMakeRect(NSMidX(screenRect) - NSMidX(viewRect),
								 NSMidY(screenRect) - NSMidY(viewRect),
								 viewRect.size.width, 
								 viewRect.size.height);

	NSWindow * window = [[NSWindow alloc] initWithContentRect:windowRect 
						styleMask:windowStyle 
						backing:NSBackingStoreBuffered 
						defer:NO]; 
	[window autorelease]; 
 
	NSWindowController * windowController = [[NSWindowController alloc] initWithWindow:window]; 
	[windowController autorelease]; 
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    WindowDelegate *delegate = [WindowDelegate alloc];
    [delegate autorelease];
    [window setDelegate:delegate];
    [window setTitle:[[NSProcessInfo processInfo] processName]];
    [window setAcceptsMouseMovedEvents:YES];
    [window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[window orderFrontRegardless];  
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];

    //METAL DEVICE SETUP
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    id<MTLRenderCommandEncoder> renderEncoder;
    unsigned int width, height;
    MTKView * view = [[MTKView alloc] initWithFrame: viewRect
                                             device: device];
    
    if(!view){
        NSLog(@"Error initializing MTKView object\n");
    }
    view.clearColor = MTLClearColorMake(0.2, 0.5, 0.8, 1);
    view.paused = true;
    view.enableSetNeedsDisplay = false;

    //METAL BUFFER SETUP
    float sz = 100;
    float vertices[] = {
        0,  0,  0, 0,
        0,  sz, 0, 1,
        sz, sz, 1, 1,
        sz, 0,  1, 0,
    };

    unsigned short indices[] = {
        0, 1, 2, 2, 3, 0
    };

    struct Uniforms {
        Matrix4 perspectiveMatrix;
    };
    Uniforms uniforms = {};
    
    uniforms.perspectiveMatrix = createOrthogonalProjectionMatrix(0, WIDTH, 0, HEIGHT, -1, 1);
    
    // id<MTLBuffer> indexBuffer = [device newBufferWithBytes: indices
    //                                     length: sizeof(indices)
    //                                     options: MTLResourceStorageModeShared];
    // id<MTLBuffer> vertBuffer = [device newBufferWithBytes: vertices
    //                                     length: sizeof(vertices)
    //                                     options: MTLResourceStorageModeShared];
    id<MTLBuffer> indexBuffer = [device newBufferWithLength: 10000
                                        options: MTLResourceStorageModeShared];
    id<MTLBuffer> vertBuffer = [device newBufferWithLength: 10000
                                        options: MTLResourceStorageModeShared];


    id<MTLBuffer> uniformBuffer = [device newBufferWithBytes: &uniforms
                                        length: sizeof(uniforms)
                                        options: MTLResourceStorageModeShared];
    MTLVertexDescriptor *vertDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    MTLVertexAttributeDescriptor *attribDescriptor = [MTLVertexAttributeDescriptor new];
    attribDescriptor.format = MTLVertexFormatFloat2;
    attribDescriptor.offset = 0;
    attribDescriptor.bufferIndex = 0;
    [vertDescriptor.attributes setObject: attribDescriptor atIndexedSubscript: 0];
    MTLVertexAttributeDescriptor *texDescriptor = [MTLVertexAttributeDescriptor new];
    attribDescriptor.format = MTLVertexFormatFloat2;
    attribDescriptor.offset = sizeof(float) * 2;
    attribDescriptor.bufferIndex = 0;
    [vertDescriptor.attributes setObject: attribDescriptor atIndexedSubscript: 1];
    
    MTLVertexBufferLayoutDescriptor *layoutDescriptor = [MTLVertexBufferLayoutDescriptor new];
    layoutDescriptor.stride = sizeof(float) * 4;
    layoutDescriptor.stepFunction = MTLVertexStepFunctionPerVertex;
    layoutDescriptor.stepRate = 1;
    [vertDescriptor.layouts setObject: layoutDescriptor atIndexedSubscript: 0];

    //METAL SHADER SETUP
    id<MTLRenderPipelineState> pipelineState;
    NSError* err;
    id<MTLLibrary> defaultLibrary = [device newLibraryWithFile:@"basic_shader.metallib" error: &err];
    // MTLCompileOptions* options = [[MTLCompileOptions alloc] init];
    // id<MTLLibrary> defaultLibrary = [device newLibraryWithSource:shaders
    //                                                     options: options 
    //                                                     error:&err];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
    pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineStateDescriptor.vertexDescriptor = vertDescriptor;

    pipelineState = [device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&err];
    if (!pipelineState){
        NSLog(@"Failed to created pipeline state, error %@", err);
        return 1;
    }

    BatteryBarrageState* bbState = new BatteryBarrageState;
    bbState->readFromFile = readFile;
    bbState->gameWidth = WIDTH;
    bbState->gameHeight = HEIGHT;
    initializeGameState(bbState);

    prepareTextBuffers(&bbState->textRenderer, (f32*)[vertBuffer contents], (u16*)[indexBuffer contents]);

    //METAL TEXTURE SETUP
    unsigned char textureData[] = {
        0, 0, 255, 255,     255, 0, 0, 255,     0, 255, 0, 255,
        0, 255, 0, 255,     0, 0, 255, 255,     255, 0, 0, 255,
        255, 0, 0, 255,     0, 255, 0, 255,     0, 0, 255, 255,     
    };

    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    textureDescriptor.width = bbState->textRenderer.fontAtlas.totalBitmapWidth;
    textureDescriptor.height = bbState->textRenderer.fontAtlas.totalBitmapHeight;
    textureDescriptor.pixelFormat = MTLPixelFormatR8Unorm;
    id<MTLTexture> texture = [device newTextureWithDescriptor: textureDescriptor];
    MTLRegion region = {
        {0, 0, 0},
        { textureDescriptor.width , textureDescriptor.height, 1}
    };
    [texture replaceRegion:region
               mipmapLevel:0
               withBytes:bbState->textRenderer.fontAtlas.bitmap
               bytesPerRow:bbState->textRenderer.fontAtlas.totalBitmapWidth];

    MTLSamplerDescriptor *samplerDescriptor = [MTLSamplerDescriptor new];
    samplerDescriptor.minFilter = MTLSamplerMinMagFilterNearest;
    samplerDescriptor.magFilter = MTLSamplerMinMagFilterNearest;
    id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor: samplerDescriptor];

    [window setContentView:view];

    void* handle = dlopen("./libbb.so", RTLD_LAZY);
    typedef void (*fnPtr)(float, BatteryBarrageState*);
    fnPtr update = (fnPtr)dlsym(handle, "updateGameState");


    NSString * path = @"./libbb.so";
    NSDate * fileLastModifiedDate = nil;

    NSError * error = nil;
    NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
    if (attrs && !error){
        fileLastModifiedDate = [attrs fileModificationDate];
    }

    NSEvent* ev;  
    while(true){
        do {
            ev = [NSApp nextEventMatchingMask: NSEventMaskAny
                                    untilDate: nil
                                       inMode: NSDefaultRunLoopMode
                                      dequeue: YES];
            if (ev) {
                if([ev type] == NSEventTypeKeyDown){
                    switch([ev keyCode]){
                        case 53:{
                            [NSApp terminate: NSApp];
                            break;
                        }
                    }
                }else{
                    [NSApp sendEvent: ev];
                }
            }
        } while (ev);

        #ifdef DEBUG_COMPILE
        attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
        if (attrs && !error){
            if([[attrs fileModificationDate] compare:fileLastModifiedDate] != NSOrderedSame){
                dlclose(handle);
                handle = dlopen("./libbb.so", RTLD_LAZY);
                update = (fnPtr)dlsym(handle, "updateGameState");
                fileLastModifiedDate = [attrs fileModificationDate];
                NSLog(@"%@\t%@", [attrs fileModificationDate], fileLastModifiedDate);
            }
        }
        #endif
        
        update(0, bbState);
        prepareTextBuffers(&bbState->textRenderer, (f32*)[vertBuffer contents], (u16*)[indexBuffer contents]);

        Uniforms* ufms = (Uniforms*)[uniformBuffer contents];
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

        renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor: view.currentRenderPassDescriptor];
        [renderEncoder setRenderPipelineState:pipelineState];

        [renderEncoder setVertexBuffer:vertBuffer
                            offset:0
                            atIndex:0];
        [renderEncoder setVertexBuffer:uniformBuffer
                            offset:0
                            atIndex:2];
    
        [renderEncoder setFragmentTexture:texture
                        atIndex:0];
        
        [renderEncoder setFragmentSamplerState:samplerState atIndex: 0];

        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                    indexCount: bbState->textRenderer.totalIndices
                    indexType: MTLIndexTypeUInt16
                    indexBuffer: indexBuffer
                    indexBufferOffset: 0];

        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
       
        [commandBuffer commit];
        [view draw];
    }

	[pool drain]; 

    return 0;
}