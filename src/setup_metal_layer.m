#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import "../glfw/include/GLFW/glfw3.h"
#import "../glfw/include/GLFW/glfw3native.h"


CAMetalLayer* setupMetalLayer(void* window) {
    NSWindow* ns_window = (__bridge NSWindow*)window;
    //NSView* ns_view = [ns_window contentView];
    
    CAMetalLayer* metal_layer = [CAMetalLayer layer];
    //metal_layer.device = MTLCreateSystemDefaultDevice();
    //metal_layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    //metal_layer.framebufferOnly = YES;
    //metal_layer.frame = ns_view.bounds;

    //[ns_view setWantsLayer:YES];
    //[ns_view setLayer:metal_layer];
    [ns_window.contentView setWantsLayer: YES];
    [ns_window.contentView setLayer: metal_layer];

    return metal_layer;
}
