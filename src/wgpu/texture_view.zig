pub const TextureView = opaque {
    extern "c" fn wgpuTextureViewRelease(textureView: ?*const TextureView) void;
    pub fn release(textureView: *const TextureView) void {
        wgpuTextureViewRelease(textureView);
    }
};
