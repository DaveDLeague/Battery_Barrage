#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <GameController/GameController.h>

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

int main(int argc, char** argv){
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init]; 
    [NSApp sharedApplication];
    
    if([[GCController controllers] count]){
        NSLog(@"Controller Found\n");
    }else{
        NSLog(@"Controller NOT Found\n");
    }

    NSUInteger windowStyle = NSWindowStyleMaskTitled        | 
                             NSWindowStyleMaskClosable      | 
                             NSWindowStyleMaskResizable     | 
                             NSWindowStyleMaskMiniaturizable;

	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect viewRect = NSMakeRect(0, 0, 800, 600); 
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
    float sz = 0.8;
    float vertices[] = {
        -sz, -sz,
         0, sz,
         sz, -sz,
    };

    unsigned short indices[] = {
        0, 1, 2
    };

    id<MTLBuffer> indexBuffer = [device newBufferWithBytes: indices
                                        length: sizeof(indices)
                                        options: MTLResourceStorageModeShared];
    id<MTLBuffer> vertBuffer = [device newBufferWithBytes: vertices
                                        length: sizeof(vertices)
                                        options: MTLResourceStorageModeShared];
    MTLVertexDescriptor *vertDescriptor = [MTLVertexDescriptor vertexDescriptor];
    
    MTLVertexAttributeDescriptor *attribDescriptor = [MTLVertexAttributeDescriptor new];
    attribDescriptor.format = MTLVertexFormatFloat2;
    attribDescriptor.offset = 0;
    attribDescriptor.bufferIndex = 0;
    [vertDescriptor.attributes setObject: attribDescriptor atIndexedSubscript: 0];
    
    MTLVertexBufferLayoutDescriptor *layoutDescriptor = [MTLVertexBufferLayoutDescriptor new];
    layoutDescriptor.stride = sizeof(float) * 2;
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

    [window setContentView:view];

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
                        case 0:{
                            NSLog(@"A\n");
                            break;
                        }
                    }
                }else{
                    [NSApp sendEvent: ev];
                }
            }
        } while (ev);
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
        if(renderPassDescriptor){
            renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
            [renderEncoder setRenderPipelineState:pipelineState];

            [renderEncoder setVertexBuffer:vertBuffer
                                offset:0
                                atIndex:0];

            [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                        indexCount:3
                        indexType:MTLIndexTypeUInt16
                        indexBuffer: indexBuffer
                        indexBufferOffset:0];

            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
        }
        [commandBuffer commit];
        [view draw];
    }

	[pool drain]; 

    return 0;
}