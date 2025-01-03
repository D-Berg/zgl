const std = @import("std");
const log = std.log.scoped(.@"wgpu/texture");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const TextureFormat = wgpu.TextureFormat;
const TextureViewDimension = wgpu.TexureViewDimension;
const TextureUsage = wgpu.TextureUsage;

const TextureAspect = wgpu.TextureAspect;
const Texture = @This();
pub const TextureImpl = *opaque {};
_impl: TextureImpl,


pub const ViewImpl = *opaque {};

extern "c" fn wgpuTextureRelease(texture: TextureImpl) void;
pub fn Release(texture: Texture) void {
    wgpuTextureRelease(texture._impl);
}



// WGPU_EXPORT WGPUTextureView wgpuTextureCreateView(WGPUTexture texture, WGPU_NULLABLE WGPUTextureViewDescriptor const * descriptor) WGPU_FUNCTION_ATTRIBUTE;
extern "c" fn wgpuTextureCreateView(texture: TextureImpl, descriptor: ?*const View.Descriptor) ?ViewImpl;
pub fn CreateView(texture: Texture, descriptor: ?*const View.Descriptor) WGPUError!View {

    const maybe_impl = wgpuTextureCreateView(texture._impl, descriptor);

    if (maybe_impl) |impl| return View{ ._impl = impl } else return error.FailedToGetTextureView;
}

extern "c" fn wgpuTextureGetFormat(texure: TextureImpl) TextureFormat;
pub fn GetFormat(texture: Texture) TextureFormat {
    return wgpuTextureGetFormat(texture._impl);
}

pub const View = struct {
    _impl: ViewImpl,

    extern "c" fn wgpuTextureViewRelease(view: ViewImpl) void;
    pub fn Release(view: View) void {
        wgpuTextureViewRelease(view._impl);
    }

    pub const Descriptor = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        label: wgpu.StringView = .{ .data = "", .length = 0 },
        format: TextureFormat,
        dimension: TextureViewDimension,
        baseMipLevel: u32,
        mipLevelCount: u32,
        baseArrayLayer: u32,
        arrayLayerCount: u32,
        aspect: TextureAspect,
        usage: TextureUsage,
    };

};

