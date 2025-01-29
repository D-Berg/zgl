const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayoutImpl = wgpu.PipelineLayout.PipelineLayoutImpl;


pub const ShaderModule = *opaque {
    extern "c" fn wgpuShaderModuleRelease(shaderModule: ShaderModule) void;
    pub fn release(shaderModule: ShaderModule) void {
        wgpuShaderModuleRelease(shaderModule);
    }
};




