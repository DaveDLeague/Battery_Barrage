#include <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h> //for key codes
#include <Metal/Metal.h>
#include <MetalKit/MetalKit.h>
#include <GameController/GameController.h>
#include <dlfcn.h>

#include "battery_barrage.cpp"
#include "osx_renderer_metal.mm"

#define WIDTH 1280
#define HEIGHT 720

OSDevice osDevice;
RenderDevice renderDevice = {};
TextObjectManager txtObjMgr = {};
TextRenderer textRenderer = {};
TerrainRenderer terrainRenderer = {};

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

void OSXreadBinaryFile(const s8* fileName, u8** fileData, u64* fileLength){
    NSString* string = [[NSString alloc] initWithUTF8String: fileName];
    NSData* data = [NSData dataWithContentsOfFile: string];
    *fileLength = [data length];
    *fileData = (u8*)[data bytes];
    [string release];
    //[data release];//this might cause problems
}

void OSXreadTextFile(const s8* fileName, s8** fileData, u64* fileLength){
    NSError* err;
    const s8* fn = fileName;
    NSString* fl = [[NSString alloc] initWithUTF8String: fn];
    NSString* string = [NSString stringWithContentsOfFile: fl
                                        encoding: NSUTF8StringEncoding
                                        error: &err];

    [fl release];
    *fileLength = [string length];
    *fileData = (s8*)[string UTF8String];
    [string release];//this might cause problems
}

const s8* OSXgetPathToExecutable(){
    static bool initialized = false;
    static const s8* path;
    if(!initialized){
        NSString *appParentDirectory = [[NSBundle mainBundle] bundlePath];
        path = [appParentDirectory UTF8String];
    }
    //[appParentDirectory release];
    return path;
}

const s8* OSXgetPathFromExecutable(const s8* path){
    const s8* execPath = OSXgetPathToExecutable();
    u32 epLen = getStringLength(execPath);
    u32 pLen = getStringLength(path);
    u32 fullLen = epLen + pLen;
    s8* fullPath = new s8[fullLen];
    for(u32 i = 0; i < epLen - 1; i++){
        fullPath[i] = execPath[i];
    }
    fullPath[epLen - 1] = '/';
    for(u32 i = 0; i < pLen; i++){
        fullPath[i + epLen] = path[i];
    }

    return (const s8*)fullPath;
}

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
    osDevice.getPathFromExecutable = OSXgetPathFromExecutable;
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
    renderDevice.setClearColor(0.4, 0.8, 1, 1);

    initializeTextRenderer(&osDevice, &renderDevice, &textRenderer);
    setTextRendererProjection(&textRenderer, 0, WIDTH, 0, HEIGHT);

    Terrain terrain;
    initializeTerrainRenderer(&osDevice, &renderDevice, &terrainRenderer);

    void* handle = dlopen(OSXgetPathFromExecutable("libbb.so"), RTLD_LAZY);
    typedef void (*fnPtr)(float, BatteryBarrageState*);
    fnPtr update = (fnPtr)dlsym(handle, "updateGameState");

    NSString * path = [[NSString alloc] initWithUTF8String: OSXgetPathFromExecutable("libbb.so")];
    NSDate * fileLastModifiedDate = 0;

    NSError * error = 0;
    NSDictionary * attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:&error];

    if (attrs && !error){
        fileLastModifiedDate = [attrs fileModificationDate];
    }

    TextObject* nums = createTextObject(&txtObjMgr, "1234567890", 50, 650);
    TextObject* spec = createTextObject(&txtObjMgr, "`~!@#$\\/%^&*()-_=+?><\";", 50, 600);
    TextObject* tpLo = createTextObject(&txtObjMgr, "qwertyuiop", 50, 550);
    TextObject* mdLo = createTextObject(&txtObjMgr, "asdfghjkl", 50, 500);
    TextObject* btLo = createTextObject(&txtObjMgr, "zxcvbnm", 50, 450);
    TextObject* tpUp = createTextObject(&txtObjMgr, "QWERTYUIOP", 50, 400);
    TextObject* mdUp = createTextObject(&txtObjMgr, "ASDFGHJKL", 50, 350);
    TextObject* btUp = createTextObject(&txtObjMgr, "ZXCVBNM", 50, 300);

    Camera camera;
    camera.forward = Vector3(0, 0, 1);
    camera.right = Vector3(1, 0, 0);
    camera.up = Vector3(0, 1, 0);
    camera.position = Vector3(0, -5, -100);

    f32 moveSpeed = 0.2;
    bool moveForward = false;
    bool moveBack = false;
    bool moveLeft = false;
    bool moveRight = false;
    bool moveUp = false;
    bool moveDown = false;

    bool yawLeft = false;
    bool yawRight = false;
    bool pitchUp = false;
    bool pitchDown = false;
    bool rollRight = false;
    bool rollLeft = false;
    
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
                        case kVK_ANSI_W:{
                            moveForward = true;
                            break;
                        }
                        case kVK_ANSI_S:{
                            moveBack = true;
                            break;
                        }
                        case kVK_ANSI_A:{
                            moveRight = true;
                            break;
                        }
                        case kVK_ANSI_D:{
                            moveLeft = true;
                            break;
                        }
                        case kVK_ANSI_R:{
                            moveUp = true;
                            break;
                        }
                        case kVK_ANSI_F:{
                            moveDown = true;
                            break;
                        }
                        case kVK_RightArrow:{
                            yawRight = true;
                            break;
                        }
                        case kVK_LeftArrow:{
                            yawLeft = true;
                            break;
                        }
                        case kVK_UpArrow:{
                            pitchUp = true;
                            break;
                        }
                        case kVK_DownArrow:{
                            pitchDown = true;
                            break;
                        }
                        case kVK_ANSI_Q:{
                            rollLeft = true;
                            break;
                        }
                        case kVK_ANSI_E:{
                            rollRight = true;
                            break;
                        }
                    }
                }else if([ev type] == NSEventTypeKeyUp){
                    switch([ev keyCode]){
                        case kVK_ANSI_W:{
                            moveForward = false;
                            break;
                        }
                        case kVK_ANSI_S:{
                            moveBack = false;
                            break;
                        }
                        case kVK_ANSI_A:{
                            moveRight = false;
                            break;
                        }
                        case kVK_ANSI_D:{
                            moveLeft = false;
                            break;
                        }
                        case kVK_ANSI_R:{
                            moveUp = false;
                            break;
                        }
                        case kVK_ANSI_F:{
                            moveDown = false;
                            break;
                        }
                        case kVK_RightArrow:{
                            yawRight = false;
                            break;
                        }
                        case kVK_LeftArrow:{
                            yawLeft = false;
                            break;
                        }
                        case kVK_UpArrow:{
                            pitchUp = false;
                            break;
                        }
                        case kVK_DownArrow:{
                            pitchDown = false;
                            break;
                        }
                        case kVK_ANSI_Q:{
                            rollLeft = false;
                            break;
                        }
                        case kVK_ANSI_E:{
                            rollRight = false;
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
                    handle = dlopen(OSXgetPathFromExecutable("libbb.so"), RTLD_LAZY);
                    update = (fnPtr)dlsym(handle, "updateGameState");
                    fileLastModifiedDate = [attrs fileModificationDate];
                    NSLog(@"%@\t%@", [attrs fileModificationDate], fileLastModifiedDate);
                }
            }
        }
        #endif

        renderDevice.prepareRenderer();

        camera.position -= (camera.forward * moveForward * moveSpeed);
        camera.position += (camera.forward * moveBack * moveSpeed);
        camera.position += (camera.right * moveRight * moveSpeed);
        camera.position -= (camera.right * moveLeft * moveSpeed);
        camera.position -= (camera.up * moveUp * moveSpeed);
        camera.position += (camera.up * moveDown * moveSpeed);
        
        rotate(&camera.orientation, camera.up, yawRight * 0.01);
        rotate(&camera.orientation, camera.up, yawLeft * -0.01);
        rotate(&camera.orientation, camera.forward, rollLeft * 0.01);
        rotate(&camera.orientation, camera.forward, rollRight * -0.01);
        rotate(&camera.orientation, camera.right, pitchUp * -0.01);
        rotate(&camera.orientation, camera.right, pitchDown * 0.01);

        prepareTerrainRenderer(&terrainRenderer);
        renderTerrain(&terrainRenderer, &terrain, &camera);

        prepareTextRenderer(&textRenderer);
        renderTextObjects(&textRenderer, &txtObjMgr);
        finalizeTextRenderer(&textRenderer);

        renderDevice.finalizeRenderer();
    
    }

	[pool drain]; 

    return 0;
}