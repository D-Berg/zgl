const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayoutImpl = wgpu.PipelineLayout.PipelineLayoutImpl;


const ShaderModule = @This();
pub const ShaderModuleImpl = *opaque {};
_impl: ShaderModuleImpl,


pub const CompilationHint = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    entryPoint: [*]const u8,
    layout: ?PipelineLayoutImpl
};

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: wgpu.StringView = .{ .data = "", .length = 0},
};

extern "c" fn wgpuShaderModuleRelease(shaderModule: ShaderModuleImpl) void;
pub fn Release(shaderModule: ShaderModule) void {
    wgpuShaderModuleRelease(shaderModule._impl);
}

