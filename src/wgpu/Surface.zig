const std = @import("std");
const zgl = @import("../zgl.zig");
const log = std.log.scoped(.@"wgpu/surface");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const Adapter = wgpu.Adapter;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const TextureUsage = wgpu.TextureUsage;
const TextureFormat = wgpu.TextureFormat;
const PresentMode = wgpu.PresentMode;
const CompositeAlphaMode = wgpu.CompositeAlphaMode;
const SurfaceGetCurrentTextureStatus = wgpu.SurfaceGetCurrentTextureStatus;
const SurfaceConfiguration = wgpu.SurfaceConfiguration;
const SurfaceTexture = wgpu.SurfaceTexture;
const Texture = wgpu.Texture;

const builtin = @import("builtin");

pub const Surface = opaque {
    extern "c" fn wgpuSurfaceConfigure(surface: ?*const Surface, config: *const SurfaceConfiguration) void;
    pub fn configure(surface: *const Surface, config: *const SurfaceConfiguration) void {
        wgpuSurfaceConfigure(surface, config);
        log.debug("Configured", .{});
    }

    extern "c" fn wgpuSurfaceGetCapabilities(
        surface: ?*const Surface,
        adapter: ?*const Adapter,
        capabilities: *anyopaque,
    ) void;
    /// Surface Members need to be freed by calling FreeMembers.
    pub fn getCapabilities(surface: *const Surface, adapter: *const Adapter) Capabilities {

        // Since emscripten SurfaceCapabilities doesnt (as of yet) have
        // usages we need two different one.
        if (builtin.target.os.tag == .emscripten) {
            var web_cap = Capabilities.Web{};
            wgpuSurfaceGetCapabilities(surface, adapter, &web_cap);

            return Capabilities{
                .nextInChain = web_cap.nextInChain,
                .formats = web_cap.formats[0..web_cap.formatCount],
                .presentModes = web_cap.presentModes[0..web_cap.presentModeCount],
                .alphaModes = web_cap.alphaModes[0..web_cap.alphaModeCount],
                ._inner = .{ .web = web_cap },
            };
        } else {
            var native_cap = Capabilities.Native{};

            wgpuSurfaceGetCapabilities(surface, adapter, &native_cap);

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

            return Capabilities{
                .nextInChain = native_cap.nextInChain,
                .usages = usages_buffer[0..usage_idx],
                .formats = native_cap.formats[0..native_cap.formatCount],
                .presentModes = native_cap.presentModes[0..native_cap.presentModeCount],
                .alphaModes = native_cap.alphaModes[0..native_cap.alphaModeCount],
                ._inner = .{ .native = native_cap },
            };
        }
    }

    extern "c" fn wgpuSurfaceGetCurrentTexture(surface: ?*const Surface, surfaceTexture: *SurfaceTexture) void;
    pub fn getCurrentTexture(surface: *const Surface) GetSurfaceTextureError!*const Texture {
        var surface_texture = SurfaceTexture{};

        wgpuSurfaceGetCurrentTexture(surface, &surface_texture);

        switch (surface_texture.status) {
            .SuccessOptimal, .SuccessSuboptimal => {
                if (surface_texture.texture) |texture| {
                    return texture;
                } else {
                    log.err("surface_texture.texture was null", .{});
                    return GetSurfaceTextureError.NullTexture;
                }
            },
            .Timeout, .Outdated, .DeviceLost => {
                return GetSurfaceTextureError.RecoverableTexture;
            },
            inline else => |status| {
                log.err("Failed to get current texture with status: {s}", .{@tagName(status)});
                return GetSurfaceTextureError.UnrecoverableTexture;
            },
        }
    }

    extern "c" fn wgpuSurfacePresent(surface: ?*const Surface) void;
    pub fn present(surface: *const Surface) void {
        wgpuSurfacePresent(surface);
    }

    extern "c" fn wgpuSurfaceUnconfigure(surface: ?*const Surface) void;
    pub fn unconfigure(surface: *const Surface) void {
        wgpuSurfaceUnconfigure(surface);
        log.debug("Unconfigured", .{});
    }

    extern "c" fn wgpuSurfaceRelease(surface: ?*const Surface) void;
    pub fn release(surface: *const Surface) void {
        wgpuSurfaceRelease(surface);
        log.info("Released surface", .{});
    }

    /// Not official webgpu api, but nice to have.
    /// ensures that we don't accidently index out of range if formatCount is 0.
    pub fn getPreferredFormat(surface: *const Surface, adapter: *const Adapter) TextureFormat {
        const capabilities = surface.getCapabilities(adapter);
        defer capabilities.freeMembers();

        if (capabilities.formats.len > 0) {
            return capabilities.formats[0];
        } else {
            return TextureFormat.Undefined;
        }
    }
};

// FIX: This is very ugly
const MAX_USAGES = @typeInfo(TextureUsage).@"enum".fields.len;
var usages_buffer: [MAX_USAGES]TextureUsage = undefined;
pub const Capabilities = struct {
    nextInChain: ?*ChainedStructOut = null,
    usages: ?[]const TextureUsage = null, // TODO: check if emscripten has implemented usages when updating its version
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
        usages: wgpu.Flag = 0, // TODO: not defined in emscripten.
        formatCount: usize = 0,
        formats: [*c]const TextureFormat = null,
        presentModeCount: usize = 0,
        presentModes: [*c]const PresentMode = null,
        alphaModeCount: usize = 0,
        alphaModes: [*c]const CompositeAlphaMode = null,
    };

    extern "c" fn wgpuSurfaceCapabilitiesFreeMembers(capabilities: *const anyopaque) void;
    pub fn freeMembers(capabilities: *const Capabilities) void {
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

const GetSurfaceTextureError = error{
    NullTexture,
    RecoverableTexture,
    UnrecoverableTexture,
};
