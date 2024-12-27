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

const builtin = @import("builtin");

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

pub const DescriptorFromCanvasHTMLSelector = extern struct {
    chain: ChainedStruct,
    selector: [*]const u8,
};

extern "c" fn wgpuSurfaceRelease(surface: SurfaceImpl) void;
pub fn Release(surface: Surface) void {
    
    wgpuSurfaceRelease(surface._inner);
    log.info("released surface", .{});

}

/// Not official webgpu api, but nice to have.
/// ensures that we don't accidently index out of range if formatCount is 0.
pub fn GetPreferredFormat(surface: Surface, adapter: Adapter) TextureFormat {

    const capabilities = surface.GetCapabilities(adapter);
    defer capabilities.FreeMembers();

    if (capabilities.formats.len > 0) {
        return capabilities.formats[0];
    } else {
        return TextureFormat.Undefined;
    }
}


const MAX_USAGES = @typeInfo(TextureUsage).@"enum".fields.len;
var usages_buffer: [MAX_USAGES]TextureUsage = undefined;
pub const Capabilities = struct {
    nextInChain: ?*ChainedStructOut = null,
    usages: ?[]const TextureUsage = null, // TODO: not defined in emscripten. Find out which one is valid.
    formats: []const TextureFormat,
    presentModes: []const PresentMode,
    alphaModes: []const CompositeAlphaMode,
    _inner: WGPUCapabilities,


    const WGPUCapabilities = union(enum) {
        native: Native,
        web: Web,
    };

    const Web = extern struct {
        nextInChain: ?*ChainedStructOut = null,
        formatCount: usize = 0,
        formats: [*c]const TextureFormat = null,
        presentModeCount: usize = 0,
        presentModes: [*c]const PresentMode = null,
        alphaModeCount: usize = 0,
        alphaModes: [*c]const CompositeAlphaMode = null,

    };

    const Native = extern struct {
        nextInChain: ?*ChainedStructOut = null,
        usages: u32 = 0,// TODO: not defined in emscripten.
        formatCount: usize = 0,
        formats: [*c]const TextureFormat = null,
        presentModeCount: usize = 0,
        presentModes: [*c]const PresentMode = null,
        alphaModeCount: usize = 0,
        alphaModes: [*c]const CompositeAlphaMode = null,
    };

    
    extern "c" fn wgpuSurfaceCapabilitiesFreeMembers(capabilities: *const anyopaque) void;
    pub fn FreeMembers(capabilities: *const Capabilities) void {
        switch (capabilities._inner) {
            inline else => |*caps| wgpuSurfaceCapabilitiesFreeMembers(caps),
        }
    }
    
    pub fn logCapabilites(capabilities: *const Capabilities) void {
        
        log.info("Surface capabilities:", .{});
        log.info(" - nextInChain: {?}", .{capabilities.nextInChain});
        if (capabilities.usages) |usages| {
            log.info(" - usages:", .{});

            for (usages) |usage| {
                log.info("  - {s}", .{@tagName(usage)});
            }
        }

        log.info(" - formats: {}", .{capabilities.formats.len});
        for (capabilities.formats) |format| {
            // log.info("  - {x}", .{@intFromEnum(capabilities.formats.?[i])});
            log.info("  - {s}", .{@tagName(format)});
        }

        log.info(" - presentModes:", .{});
        for (capabilities.presentModes) |presentMode| {
            log.info("  - {s}", .{@tagName(presentMode)});
        }

        log.info(" - alpaModes:", .{});
        for (capabilities.alphaModes) |alphaMode| {
            log.info("  - {s}", .{@tagName(alphaMode)});
        }
    }
    
};

extern "c" fn wgpuSurfaceGetCapabilities(
    surface: SurfaceImpl, 
    adapter: AdapterImpl, 
    capabilities: *anyopaque
) void;
/// Surface Members need to be freed by calling FreeMembers.
pub fn GetCapabilities(surface: Surface, adapter: Adapter) Capabilities {

    // Since emscripten SurfaceCapabilities doesnt (as of yet) have
    // usages we need two different one.
    if (builtin.target.os.tag == .emscripten) {
        var web_cap = Capabilities.Web{};
        wgpuSurfaceGetCapabilities(surface._inner, adapter._inner, &web_cap);

        return Capabilities{
            .nextInChain = web_cap.nextInChain,
            .formats = web_cap.formats[0..web_cap.formatCount],
            .presentModes = web_cap.presentModes[0..web_cap.presentModeCount],
            .alphaModes = web_cap.alphaModes[0..web_cap.alphaModeCount],
            ._inner = .{ .web = web_cap }
        };
    } else {
        var native_cap = Capabilities.Native{};
        
        wgpuSurfaceGetCapabilities(surface._inner, adapter._inner, &native_cap);

        var usage_idx: usize = 0;
        inline for (@typeInfo(TextureUsage).@"enum".fields) |field| {

            const bit_is_set: bool = blk: {
                if (field.value == 0) {
                    if (native_cap.usages == 0) {
                        break :blk true;
                    } else {
                        break :blk false;
                    }
                } else {
                    break :blk native_cap.usages & field.value == field.value;
                }
            };

            if (bit_is_set) {
                usages_buffer[usage_idx] = @as(TextureUsage, @enumFromInt(field.value));
                usage_idx += 1;
            }
        }

        return Capabilities {
            .nextInChain = native_cap.nextInChain,
            .usages = usages_buffer[0..usage_idx],
            .formats = native_cap.formats[0..native_cap.formatCount],
            .presentModes = native_cap.presentModes[0..native_cap.presentModeCount],
            .alphaModes = native_cap.alphaModes[0..native_cap.alphaModeCount],
            ._inner = .{ .native = native_cap }
        };

    }




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
/// Unsupported on emscripten.
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
