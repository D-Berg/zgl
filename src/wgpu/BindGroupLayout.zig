pub const BindGroupLayout = opaque {
    extern "c" fn wgpuBindGroupLayoutRelease(bind_group_layout: ?*const BindGroupLayout) void;
    pub fn release(bind_group_layout: *const BindGroupLayout) void {
        wgpuBindGroupLayoutRelease(bind_group_layout);
    }

    // TODO: Implement these methods
    // WGPU_EXPORT void wgpuBindGroupLayoutSetLabel(WGPUBindGroupLayout bindGroupLayout, WGPUStringView label) WGPU_FUNCTION_ATTRIBUTE;
    // WGPU_EXPORT void wgpuBindGroupLayoutAddRef(WGPUBindGroupLayout bindGroupLayout) WGPU_FUNCTION_ATTRIBUTE;

};
