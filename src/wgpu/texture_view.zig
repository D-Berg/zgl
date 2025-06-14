

pub const TextureView = *TextureViewImpl;
const TextureViewImpl = opaque {

    extern "c" fn wgpuTextureViewRelease(textureView: TextureView) void;
    pub fn release(textureView: TextureView) void {
        wgpuTextureViewRelease(textureView);
    }

};
