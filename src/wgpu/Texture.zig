const std = @import("std");
const log = std.log.scoped(.@"wgpu/texture");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const TextureFormat = wgpu.TextureFormat;
const TextureUsage = wgpu.TextureUsage;
const TextureViewDescriptor = wgpu.TextureViewDescriptor;

const TextureAspect = wgpu.TextureAspect;
const TextureView = wgpu.TextureView;

pub const Texture = *TextureImpl; 
const TextureImpl = opaque {

    extern "c" fn wgpuTextureRelease(texture: Texture) void;
    pub fn release(texture: Texture) void {
        wgpuTextureRelease(texture);
    }

    extern "c" fn wgpuTextureCreateView(texture: Texture, descriptor: ?*const TextureViewDescriptor) ?TextureView;
    pub fn CreateView(texture: Texture, descriptor: ?*const TextureViewDescriptor) WGPUError!TextureView {

        const maybe_texture_view = wgpuTextureCreateView(texture, descriptor);

        if (maybe_texture_view) |texture_view| {
            return texture_view;
        } else {
            return error.FailedToGetTextureView;
        }
    }

    extern "c" fn wgpuTextureGetFormat(texure: Texture) TextureFormat;
    pub fn GetFormat(texture: Texture) TextureFormat {
        return wgpuTextureGetFormat(texture);
    }
};
