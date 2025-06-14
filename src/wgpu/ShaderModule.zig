const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayoutImpl = wgpu.PipelineLayout.PipelineLayoutImpl;

pub const ShaderModule = opaque {
    extern "c" fn wgpuShaderModuleRelease(shader_module: ?*const ShaderModule) void;
    pub fn release(shader_module: *const ShaderModule) void {
        wgpuShaderModuleRelease(shader_module);
    }
};
