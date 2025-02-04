const std = @import("std");
const log = std.log.scoped(.@"glfw");
const wgpu = @import("zgl.zig").wgpu;
const Instance = wgpu.Instance;
const Surface = wgpu.Surface;
const display_server = @import("zgl_options").DisplayServer;
const os_tag = @import("builtin").os.tag;
const c = @import("zgl.zig").c;

pub const GlfwError = error {
    GLFWFailedInit,
    FailedToCreateWindow
};

extern "c" fn glfwInit() u32;
pub fn init() GlfwError!void {

    const status = glfwInit();

    if (status == 0) {
        log.err("Failed to init glfw", .{});

        if (os_tag != .emscripten) { // glfwGetError doesnt work
            var description: [*:0]u8 = undefined;
            _ = glfwGetError(&description);
            log.err("error description = {s}", .{description});
        }

        return error.GLFWFailedInit;
    }
}

extern "c" fn glfwTerminate() void;
pub fn terminate() void {
    glfwTerminate();
}

extern "c" fn glfwGetError(description: *[*:0]u8) u32;

extern "c" fn glfwPollEvents() void;
pub fn pollEvents() void {
    glfwPollEvents();
}

const GLFW_RESIZABLE = 0x00020003;
const GLFW_CLIENT_API = 0x00022001;
const ClientAPI = enum(u32) {
    NO_API = 0,
    OPENGL_API = 0x00030001,
    OPENGL_ES_API = 0x00030002,
};

const GLFWwindow = opaque {};
const GLFWmonitor = opaque {};

pub const Window = struct {
    
    _impl: *GLFWwindow,

    extern "c" fn glfwCreateWindow(
        width: u32, 
        height: u32, 
        title: [*:0]const u8, 
        monitor: ?*GLFWmonitor, 
        share: ?*GLFWwindow
    ) ?*GLFWwindow;
    pub fn Create(width: u32, height: u32, title: []const u8) GlfwError!Window {

        const maybe_window = glfwCreateWindow(width, height, @ptrCast(title), null, null);

        if (maybe_window) |window| {
            log.info("Created Window", .{});
            return Window{ ._impl = window };
        } else {
            log.err("Failed to create Window", .{});
            return error.FailedToCreateWindow;
        }

    }

    extern "c" fn glfwDestroyWindow(window: *GLFWwindow) void;
    pub fn destroy(window: Window) void {
        glfwDestroyWindow(window._impl);
        log.info("Destoyed window", .{});
    }

    extern "c" fn glfwWindowShouldClose(window: *GLFWwindow) u32;
    pub fn ShouldClose(window: Window) bool {
        
        const res = glfwWindowShouldClose(window._impl);

        if (res != 0) {
            return true;
        } else {
            return false;
        }

    }

    pub const Hints = struct {
        resizable: ?bool = null,
        client_api: ?ClientAPI = null
    };


    extern fn glfwWindowHint(hint: u32, value: u32) void;
    pub fn hint(hints: Hints) void {
        if (hints.resizable) |resize| glfwWindowHint(GLFW_RESIZABLE, @intFromBool(resize));
        if (hints.client_api) |val| glfwWindowHint(GLFW_CLIENT_API, @intFromEnum(val));
    }

    const Size = struct {
        width: u32,
        height: u32
    };

    extern "c" fn glfwGetWindowSize(
        handle: *GLFWwindow, 
        width: *u32, 
        height: *u32
    ) void;
    pub fn GetSize(window: Window) !Size {

        var width: u32 = 0;
        var height: u32 = 0;

        glfwGetWindowSize(window._impl, &width, &height);

        if (width == 0 or height == 0) return error.InvalidSize;

        return Size { .width = width, .height = height };
    }


};



pub fn GetWGPUSurface(window: Window, instance: Instance) wgpu.WGPUError!Surface {

    switch (os_tag) {
        .macos => {
            return try GetWGPUMetalSurface(window, instance);
        },
        .linux => {
            switch (display_server) {
                .X11 => return try GetWGPUX11Surface(window, instance),
                .Wayland => return try GetWGPUWaylandSurface(window, instance)
            }
        },
        .windows => {
            return try GetWGPUWindowsSurface(window, instance);
        },
        .emscripten => {
            return try GetWGPUCanvasSurface(instance);
        },
        else => {
            @panic("Unsupported OS");
        }
    }

}


const LPCSTR = ?[*:0]const u8;
const HMODULE = *opaque {};
extern "c" fn glfwGetWin32Window(window: *GLFWwindow) ?*anyopaque;
extern "c" fn GetModuleHandleA(lpModuleName: LPCSTR) ?HMODULE;
extern "c" fn GetModuleHandleW(lpModuleName: LPCSTR) ?HMODULE;

fn GetWGPUWindowsSurface(window: Window, instance: Instance) wgpu.WGPUError!Surface {
    // TODO: Return errors if null instead
    const hwnd = glfwGetWin32Window(window._impl) orelse @panic("hwnd was null");
    const hinstance = GetModuleHandleA(null) orelse @panic("hinstance was null");

    log.debug("hinstance = {any}", .{hinstance});
    log.debug("hwnd = {any}", .{hwnd});

    const fromWindowsHWND = wgpu.SurfaceSourceFromWindowsHWND{
        .hwnd = hwnd,
        .hinstance = hinstance,
        .chain = .{ .sType = .SurfaceSourceWindowsHWND }
    };

    const surface_desc = wgpu.SurfaceDescriptor{
        .nextInChain = &fromWindowsHWND.chain,
    };

    log.info("Getting Windows Surface...", .{});
    return try instance.CreateSurface(&surface_desc);
}


//TODO: make optionals and check null
extern "c" fn glfwGetX11Display() *anyopaque;
extern "c" fn glfwGetX11Window(handle: *GLFWwindow) *GLFWwindow;
fn GetWGPUX11Surface(window: Window, instance: Instance) wgpu.WGPUError!Surface {
    const x11_display = glfwGetX11Display();
    const x11_window = glfwGetX11Window(window._impl);

    const fromX11 = wgpu.SurfaceSourceFromXlibWindow{
        .window = @intFromPtr(x11_window),
        .display = x11_display,
        .chain = .{ .sType = .SurfaceSourceXlibWindow }
    };
    const surface_desc = wgpu.SurfaceDescriptor {
        .nextInChain = &fromX11.chain,
    };

    log.info("Getting X11 Surface", .{});
    return try instance.CreateSurface(&surface_desc);
}


extern "c" fn glfwGetWaylandDisplay() ?*anyopaque;
extern "c" fn glfwGetWaylandWindow(handle: *GLFWwindow) ?*anyopaque;
fn GetWGPUWaylandSurface(window: Window, instance: Instance) wgpu.WGPUError!Surface {

    const wl_display = glfwGetWaylandDisplay() orelse 
        return wgpu.WGPUError.FailedToCreateSurface;

    const wl_surface = glfwGetWaylandWindow(window._impl) orelse 
        return wgpu.WGPUError.FailedToCreateSurface;

    const fromWaland = wgpu.SurfaceSourceFromWaylandSurface{
        .chain = .{ .sType = .SurfaceSourceWaylandSurface },
        .display = wl_display,
        .surface = wl_surface
    };

    const surface_desc = wgpu.SurfaceDescriptor{
        .nextInChain = &fromWaland.chain
    };


    log.info("Getting Wayland Surface", .{});
    return try instance.CreateSurface(&surface_desc);
}
    
// TODO: Shouldnt be pub
pub extern "c" fn glfwGetCocoaWindow(window: *GLFWwindow) *anyopaque;
/// setup_metal_leayer.m
pub extern "c" fn setupMetalLayer(window: *anyopaque) *anyopaque;
/// Works only for metal as of now
/// https://github.com/eliemichel/glfw3webgpu/blob/main/glfw3webgpu.c#L127
fn GetWGPUMetalSurface(window: Window, instance: Instance) wgpu.WGPUError!Surface {

    // Cocoa (mac) specific
    const ns_window = glfwGetCocoaWindow(window._impl);
    
    const metal_layer = setupMetalLayer(ns_window);
    
    log.debug("ns_window: {any}", .{ns_window});
    log.debug("metal_layer: {any}", .{metal_layer});

    const fromMetalLayer = wgpu.SurfaceSourceFromMetalLayer {
        .chain = .{ .next = null, .sType = .SurfaceSourceMetalLayer },
        .layer = metal_layer
    };

    const surfaceDesc = wgpu.SurfaceDescriptor {
        .nextInChain = &fromMetalLayer.chain
    };

    log.info("Getting Cocoa Surface", .{});
    return try instance.CreateSurface(&surfaceDesc);
}

// FIX:
fn GetWGPUCanvasSurface(instance: Instance) wgpu.WGPUError!Surface {

    const fromCanvasHTMLSelector = wgpu.SurfaceSourceFromCanvasHTMLSelector {
        .chain = .{ .sType = .DescriptorFromCanvasHTMLSelector },
        .selector = "canvas"
    };

    const surfaceDesc = wgpu.SurfaceDescriptor {
        .nextInChain = &fromCanvasHTMLSelector.chain
    };

    log.info("Getting Canvas HTML Surface", .{});

    return try instance.CreateSurface(&surfaceDesc);
}


pub const Key = enum(i32) {
    Unknown           = -1,
    Space             = 32,
    Apostrophe        = 39,  // '
    COMMA             = 44,  // ,
    MINUS             = 45,  // - 
    PERIOD            = 46,  // . 
    SLASH             = 47,  // / 
    @"0"              = 48,
    @"1"              = 49,
    @"2"              = 50,
    @"3"              = 51,
    @"4"              = 52,
    @"5"              = 53,
    @"6"              = 54,
    @"7"              = 55,
    @"8"              = 56,
    @"9"              = 57,
    SEMICOLON         = 59,  // ; 
    EQUAL             = 61,  // =
    A                 = 65,
    B                 = 66,
    C                 = 67,
    D                 = 68,
    E                 = 69,
    F                 = 70,
    G                 = 71,
    H                 = 72,
    I                 = 73,
    J                 = 74,
    K                 = 75,
    L                 = 76,
    M                 = 77,
    N                 = 78,
    O                 = 79,
    P                 = 80,
    Q                 = 81,
    R                 = 82,
    S                 = 83,
    T                 = 84,
    U                 = 85,
    V                 = 86,
    W                 = 87,
    X                 = 88,
    Y                 = 89,
    Z                 = 90,
    LEFT_BRACKET      = 91,  // [
    BACKSLASH         = 92,  // \
    RIGHT_BRACKET     = 93,  // ]
    GRAVE_ACCENT      = 96,  // `
    WORLD_1           = 161, // non-US #1
    WORLD_2           = 162, // non-US #2
    
    // Function keys
    ESCAPE            = 256, 
    ENTER             = 257, 
    TAB               = 258, 
    BACKSPACE         = 259, 
    INSERT            = 260, 
    DELETE            = 261, 
    RIGHT             = 262, 
    LEFT              = 263, 
    DOWN              = 264, 
    UP                = 265, 
    PAGE_UP           = 266, 
    PAGE_DOWN         = 267, 
    HOME              = 268, 
    END               = 269, 
    CAPS_LOCK         = 280, 
    SCROLL_LOCK       = 281, 
    NUM_LOCK          = 282, 
    PRINT_SCREEN      = 283, 
    PAUSE             = 284, 
    F1                = 290, 
    F2                = 291, 
    F3                = 292, 
    F4                = 293, 
    F5                = 294, 
    F6                = 295, 
    F7                = 296, 
    F8                = 297, 
    F9                = 298, 
    F10               = 299, 
    F11               = 300, 
    F12               = 301, 
    F13               = 302, 
    F14               = 303, 
    F15               = 304, 
    F16               = 305, 
    F17               = 306, 
    F18               = 307, 
    F19               = 308, 
    F20               = 309, 
    F21               = 310, 
    F22               = 311, 
    F23               = 312, 
    F24               = 313, 
    F25               = 314, 
    KP_0              = 320, 
    KP_1              = 321, 
    KP_2              = 322, 
    KP_3              = 323, 
    KP_4              = 324, 
    KP_5              = 325, 
    KP_6              = 326, 
    KP_7              = 327, 
    KP_8              = 328, 
    KP_9              = 329, 
    KP_DECIMAL        = 330, 
    KP_DIVIDE         = 331, 
    KP_MULTIPLY       = 332, 
    KP_SUBTRACT       = 333, 
    KP_ADD            = 334, 
    KP_ENTER          = 335, 
    KP_EQUAL          = 336, 
    LEFT_SHIFT        = 340, 
    LEFT_CONTROL      = 341, 
    LEFT_ALT          = 342, 
    LEFT_SUPER        = 343, 
    RIGHT_SHIFT       = 344, 
    RIGHT_CONTROL     = 345, 
    RIGHT_ALT         = 346, 
    RIGHT_SUPER       = 347, 
    MENU              = 348, 
};

pub const KeyState = enum(u32) {
    Released = 0,
    Pressed = 1,
};

extern "c" fn glfwGetKey(window: *GLFWwindow, key: i32) u32;
pub fn GetKey(window: Window, key: Key) KeyState {
    const result = glfwGetKey(window._impl, @intFromEnum(key));

    switch (result) {
        @intFromEnum(KeyState.Released) => return .Released,
        @intFromEnum(KeyState.Pressed) => return .Pressed,
        else => {
            @panic("need to handle this errorrro");
        }
    }



}

