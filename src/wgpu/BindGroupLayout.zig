pub const BindGroupLayout = *BindGroupLayoutImpl;
pub const BindGroupLayoutImpl = opaque {

    extern "c" fn wgpuBindGroupLayoutRelease(bindGroupLayout: BindGroupLayout) void;
    pub fn release(bindGroupLayout: BindGroupLayout) void {
        wgpuBindGroupLayoutRelease(bindGroupLayout);
    }

    
// TODO: Implement these methods
// WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, WGPUStringView label) WGPU_FUNCTION_ATTRIBUTE;
// WGPU_EXPORT void wgpuBindGroupLayoutAddRef(WGPUBindGroupLayout bindGroupLayout) WGPU_FUNCTION_ATTRIBUTE;
    
};
