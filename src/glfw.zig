const std = @import("std");
const log = std.log.scoped(.@"glfw");
const wgpu = @import("zgl.zig").wgpu;
const Instance = wgpu.Instance;
const Surface = wgpu.Surface;

const os_tag = @import("builtin").os.tag;

pub const GlfwError = error {
    FailedInit,
    FailedToCreateWindow
};

extern "c" fn glfwInit() u32;
pub fn init() GlfwError!void {

    const status = glfwInit();

    if (status == 0) {
        log.err("Failed to init glfw", .{});
        return error.FailedInit;
    }
}

extern "c" fn glfwTerminate() void;
pub fn terminate() void {
    glfwTerminate();
}

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
        title: [*]const u8, 
        monitor: ?*GLFWmonitor, 
        share: ?*GLFWwindow
    ) ?*GLFWwindow;
    pub fn Create(width: u32, height: u32, title: []const u8) GlfwError!Window {

        const maybe_window = glfwCreateWindow(width, height, title.ptr, null, null);

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


};



pub fn GetWGPUSurface(window: Window, instance: Instance) wgpu.WGPUError!Surface {

    switch (os_tag) {
        .macos => {
            return try GetWGPUMetalSurface(window, instance);
        },
        .linux => {
            @compileError("not yet implemented");
        },
        else => {
            @compileError("Unsupported OS");
        }
    }

}

extern "c" fn glfwGetX11Display() *anyopaque;
extern "c" fn glfwGetX11Window() *GLFWwindow;
fn GetWGPUX11Surface() wgpu.WGPUError!Surface {
    const x11_display = glfwGetX11Display();
    const x11_window = glfwGetX11Window();

    const fromX11 = Surface.DescriptorFromXlibWindow{
        .window = @intFromPtr(x11_window),
        .display = x11_display,
        .chain = .{ .sType = .SurfaceDescriptorFromXlibWindow }
    };
    const surface_desc = Surface.Descriptor {
        .nextInChain = &fromX11.chain,
    };

    return try Instance.CreateSurface(&surface_desc);
}
    
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

    const fromMetalLayer = Surface.DescriptorFromMetalLayer {
        .chain = .{ .next = null, .sType = .SurfaceDescriptorFromMetalLayer },
        .layer = metal_layer
    };

    const surfaceDesc = Surface.Descriptor {
        .label = "",
        .nextInChain = &fromMetalLayer.chain
    };

    return try Instance.CreateSurface(instance, &surfaceDesc);
}

