#include <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h> //for key codes
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <GameController/GameController.h>
#include <dlfcn.h>

#include "common_utils.h"
#include "graphics_math.cpp"
#include "osx_renderer_metal.mm"

#include "os.h"

#include "text_renderer.cpp"
#include "terrain_renderer.cpp"

#include "battery_barrage.cpp"

#define WIDTH 1280
#define HEIGHT 720

OSDevice osDevice;
RenderDevice renderDevice = {};
TextObjectManager txtObjMgr = {};
TextRenderer textRenderer = {};
TerrainRenderer terrainRenderer = {};

void OSXreadBinaryFile(const s8* fileName, u8** fileData, u64* fileLength){
    NSString* string = [[NSString alloc] initWithUTF8String: fileName];
    NSData* data = [NSData dataWithContentsOfFile: string];
    *fileLength = [data length];
    *fileData = (u8*)[data bytes];
    [string release];
    [data release];//this might cause problems
}

void OSXreadTextFile(const s8* fileName, s8** fileData, u64* fileLength){
    NSError* err;
    NSString* fl = [[NSString alloc] initWithUTF8String: fileName];
    NSString* string = [NSString stringWithContentsOfFile: fl
                                        encoding: NSUTF8StringEncoding
                                        error: &err];
    [fl release];
    *fileLength = [string length];
    *fileData = (s8*)[string UTF8String];
    [string release];//this might cause problems
}

const s8* OSXgetPathToExecutable(){
    NSString *appParentDirectory = [[NSBundle mainBundle] bundlePath];
    return (const s8*)[appParentDirectory UTF8String];
}

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

void OSXdisplayMessageBox(const char* message){
    NSString* string = [[NSString alloc] initWithCString: message
                                        encoding: NSUTF8StringEncoding];
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:string];
    [alert runModal];
    [string release];
    [alert release];
}

int main(int argc, char** argv){ 

    osDevice.getPathToExecutable = OSXgetPathToExecutable;
    osDevice.readBinaryFile = OSXreadBinaryFile;
    osDevice.readTextFile = OSXreadTextFile;

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
						defer:false]; 
	[window autorelease]; 
 
	NSWindowController * windowController = [[NSWindowController alloc] initWithWindow:window]; 
	[windowController autorelease]; 
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    WindowDelegate *delegate = [WindowDelegate alloc];
    [delegate autorelease];
    [window setDelegate:delegate];
    [window setTitle:[[NSProcessInfo processInfo] processName]];
    [window setAcceptsMouseMovedEvents:true];
    [window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
	[window orderFrontRegardless];  
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:true];

    initializeRenderDevice(&renderDevice, window);
    renderDevice.setClearColor(0.0, 0.6, 1, 1);

    initializeTextRenderer(&osDevice, &renderDevice, &textRenderer);
    setTextRendererProjection(&textRenderer, 0, WIDTH, 0, HEIGHT);

    Terrain terrain;
    initializeTerrainRenderer(&osDevice, &renderDevice, &terrainRenderer);

    void* handle = dlopen("./libbb.so", RTLD_LAZY);
    typedef void (*fnPtr)(float, BatteryBarrageState*);
    fnPtr update = (fnPtr)dlsym(handle, "updateGameState");

    NSString * path = @"./libbb.so";
    NSDate * fileLastModifiedDate = 0;

    NSError * error = 0;
    NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];

    if (attrs && !error){
        fileLastModifiedDate = [attrs fileModificationDate];
    }

    TextObject* tobj = createTextObject(&txtObjMgr, "HEL LO", 100, 100, 0.7, Vector4(1, 0, 0, 1));
    TextObject* tobj2 = createTextObject(&txtObjMgr, "@ @@ @@@@", 200, 200, 1, Vector4(1, 1, 1, 0.5));
    TextObject* tobj3 = createTextObject(&txtObjMgr, "+35T #$", 200, 400, 1, Vector4(0, 0, 1, 0.25));

    NSEvent* ev;  
    while(true){
        do {
            ev = [NSApp nextEventMatchingMask: NSEventMaskAny
                                    untilDate: 0
                                       inMode: NSDefaultRunLoopMode
                                      dequeue: true];
            if (ev) {
                if([ev type] == NSEventTypeKeyDown){
                    switch([ev keyCode]){
                        case kVK_Escape:{
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
        @autoreleasepool {
            attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];
            if (attrs && !error){
                NSDate* date = [attrs fileModificationDate];
                if([date compare:fileLastModifiedDate] != NSOrderedSame){
                    dlclose(handle);
                    handle = dlopen("./libbb.so", RTLD_LAZY);
                    update = (fnPtr)dlsym(handle, "updateGameState");
                    fileLastModifiedDate = [attrs fileModificationDate];
                    NSLog(@"%@\t%@", [attrs fileModificationDate], fileLastModifiedDate);
                }
            }
        }
        #endif
        
        renderDevice.prepareRenderer();

        prepareTerrainRenderer(&terrainRenderer);
        renderTerrain(&terrainRenderer, &terrain);

        prepareTextRenderer(&textRenderer);
        renderTextObjects(&textRenderer, &txtObjMgr);
        finalizeTextRenderer(&textRenderer);

        renderDevice.finalizeRenderer();
    
    }

	[pool drain]; 

    return 0;
}