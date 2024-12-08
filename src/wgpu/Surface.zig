const std = @import("std");
const log = std.log.scoped(.@"wgpu/surface");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const Adapter = wgpu.Adapter;
const AdapterImpl = Adapter.AdapterImpl;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const TextureUsage = wgpu.TextureUsage;
const TextureFormat = wgpu.TextureFormat;
const PresentMode = wgpu.PresentMode;
const CompositeAlphaMode = wgpu.CompositeAlphaMode;
const DeviceImpl = wgpu.Device.DeviceImpl;
const SurfaceGetCurrentTextureStatus = wgpu.SurfaceGetCurrentTextureStatus;

const Surface = @This();
pub const SurfaceImpl = *opaque {};

_inner: SurfaceImpl,

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: ?[*]const u8 = null,
};

pub const DescriptorFromMetalLayer = extern struct {
    chain: ChainedStruct,
    layer: *anyopaque
};

pub const DescriptorFromWindowsHWND = extern struct {
    chain: ChainedStruct,
    hinstance: *anyopaque,
    hwnd: *anyopaque,

};

pub const DescriptorFromXlibWindow = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    window: u64,
};

pub const DescriptorFromWaylandSurface = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    surface: *anyopaque
};

extern "c" fn wgpuSurfaceRelease(surface: SurfaceImpl) void;
pub fn Release(surface: Surface) void {
    
    wgpuSurfaceRelease(surface._inner);
    log.info("released surface", .{});

}

pub const Capabilities = extern struct {
    nextInChain: ?*ChainedStructOut = null,
    usages: TextureUsage = .None,
    formatCount: usize = 0,
    formats: ?[*]const TextureFormat = null,
    presentModeCount: usize = 0,
    presentModes: ?[*]const PresentMode = null,
    alphaModeCount: usize = 0,
    alphaModes: ?[*]const CompositeAlphaMode = null,
    
    extern "c" fn wgpuSurfaceCapabilitiesFreeMembers(capabilities: Capabilities) void;
    pub fn FreeMembers(capabilities: Capabilities) void {
        wgpuSurfaceCapabilitiesFreeMembers(capabilities);
    }
    
    pub fn logCapabilites(capabilities: Capabilities) void {
        
        log.info("Surface capabilities:", .{});
        log.info(" - nextInChain: {?}", .{capabilities.nextInChain});
        log.info(" - formats:", .{});
        for (0..capabilities.formatCount) |i| {
            log.info("  - {s}", .{@tagName(capabilities.formats.?[i])});
        }

        log.info(" - presentModes:", .{});
        for (0..capabilities.presentModeCount) |i| {
            log.info("  - {s}", .{@tagName(capabilities.presentModes.?[i])});
        }

        log.info(" - alpaModes:", .{});
        for (0..capabilities.alphaModeCount) |i| {
            log.info("  - {s}", .{@tagName(capabilities.alphaModes.?[i])});
        }
    }
    
};

extern "c" fn wgpuSurfaceGetCapabilities(
    surface: SurfaceImpl, 
    adapter: AdapterImpl, 
    capabilities: *Capabilities
) void;
/// Surface Members need to be freed by calling FreeMembers.
pub fn GetCapabilities(surface: Surface, adapter: Adapter) Capabilities {

    var capabilities = Capabilities{};

    wgpuSurfaceGetCapabilities(surface._inner, adapter._inner, &capabilities);

    return capabilities;

}


pub const Configuration = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    device: DeviceImpl,
    format: TextureFormat,
    usage: TextureUsage,
    viewFormatCount: usize = 0,
    viewFormats: ?[*]const TextureFormat = null,
    alphaMode: CompositeAlphaMode,
    width: u32,
    height: u32,
    presentMode: PresentMode,
};

extern "c" fn wgpuSurfaceConfigure(surface: SurfaceImpl, config: *const Configuration) void;
pub fn Configure(surface: Surface, config: *const Configuration) void {
    wgpuSurfaceConfigure(surface._inner, config);
    log.debug("Configured", .{});
}

extern "c" fn wgpuSurfaceUnconfigure(surface: SurfaceImpl) void;
pub fn Unconfigure(surface: Surface) void {
    wgpuSurfaceUnconfigure(surface._inner);
    log.debug("Unconfigured", .{});
}


const GetSurfaceTextureError = error {
    NullTexture,
    RecoverableTexture,
    UnrecoverableTexture
};
extern "c" fn wgpuSurfaceGetCurrentTexture(surface: SurfaceImpl, surfaceTexture: *Texture) void;
pub fn GetCurrentTexture(surface: Surface) GetSurfaceTextureError!wgpu.Texture {

    var surface_texture = Texture{};

    wgpuSurfaceGetCurrentTexture(surface._inner, &surface_texture);

    switch (surface_texture.status) {
        .Success => {

            if (surface_texture.texture) |texture| {
                return wgpu.Texture { ._impl = texture };
            } else {
                log.err("surface_texture.texture was null", .{});
                return GetSurfaceTextureError.NullTexture;
            }

        }, 
        .Timeout, .Outdated, .Lost => {
            return GetSurfaceTextureError.RecoverableTexture;
        },
        inline else => |status| {
            log.err("Failed to get current texture with status: {s}", .{@tagName(status)});
            return GetSurfaceTextureError.UnrecoverableTexture;
        } 
    }


}

pub const Texture = extern struct {
    texture: ?wgpu.Texture.TextureImpl = null,
    suboptimal: bool = false,
    status: wgpu.SurfaceGetCurrentTextureStatus = .Lost
};

extern "c" fn wgpuSurfacePresent(surface: SurfaceImpl) void;
pub fn Present(surface: Surface) void {
    wgpuSurfacePresent(surface._inner);
}
