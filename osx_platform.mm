#include <Cocoa/Cocoa.h>
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>

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
    [NSApp activateIgnoringOtherApps:YES];

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    id<MTLRenderCommandEncoder> renderEncoder;
    unsigned int width, height;
    MTKView * view = [[MTKView alloc] initWithFrame: viewRect
                                             device: device];
    view.clearColor = MTLClearColorMake(0.2, 0.1, 0.1, 1);
    view.paused = true;
    view.enableSetNeedsDisplay = false;

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
            [renderEncoder endEncoding];
            [commandBuffer presentDrawable:view.currentDrawable];
        }
        [commandBuffer commit];
        [view draw];
    }

	[pool drain]; 


	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    return 0;
}