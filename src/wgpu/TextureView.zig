

pub const TextureView = *opaque {

    extern "c" fn wgpuTextureViewRelease(texture_view: TextureView) void;
    pub fn release(texture_view: TextureView) void {
        wgpuTextureViewRelease(texture_view);
    }

};
