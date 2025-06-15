const std = @import("std");
const log = std.log.scoped(.@"wgpu/texture");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const TextureFormat = wgpu.TextureFormat;
const TextureUsage = wgpu.TextureUsage;
const TextureViewDescriptor = wgpu.TextureViewDescriptor;

const TextureAspect = wgpu.TextureAspect;

pub const Texture = opaque {
    extern "c" fn wgpuTextureRelease(texture: ?*const Texture) void;
    pub fn release(texture: *const Texture) void {
        wgpuTextureRelease(texture);
    }

    extern "c" fn wgpuTextureCreateView(
        texture: ?*const Texture,
        descriptor: ?*const TextureViewDescriptor,
    ) ?*const wgpu.TextureView;

    pub fn createView(
        texture: *const Texture,
        descriptor: ?*const TextureViewDescriptor,
    ) WGPUError!*const wgpu.TextureView {
        const maybe_texture_view = wgpuTextureCreateView(texture, descriptor);

        if (maybe_texture_view) |texture_view| {
            return texture_view;
        } else {
            return error.FailedToGetTextureView;
        }
    }

    extern "c" fn wgpuTextureGetFormat(texure: ?*const Texture) TextureFormat;
    pub fn getFormat(texture: *const Texture) TextureFormat {
        return wgpuTextureGetFormat(texture);
    }
};
