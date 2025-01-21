const std = @import("std");
const log = std.log.scoped(.@"wgpu/RenderPipeline");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayoutImpl = wgpu.PipelineLayout.PipelineLayoutImpl;
const VertexState = wgpu.VertexState;
const PrimitiveState = wgpu.PrimitiveState;
const DepthStencilState = wgpu.DepthStencilState;
const MultiSampleState = wgpu.MultiSampleState;
const FragmentState = wgpu.FragmentState;
const BindGroup = wgpu.BindGroup;

const RenderPipeline = @This();
pub const RenderPipelineImpl = *opaque {};

_impl: RenderPipelineImpl,

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: wgpu.StringView = .{ .data = "", .length = 0 },
    layout: ?PipelineLayoutImpl = null,
    vertex: VertexState,
    primitive: PrimitiveState,
    depthStencil: ?*const DepthStencilState = null,
    multisample: MultiSampleState,
    fragment: ?*const FragmentState = null,
};

extern "c" fn wgpuRenderPipelineRelease(renderPipeline: RenderPipelineImpl) void;
pub fn Release(renderPipeline: RenderPipeline) void {
    wgpuRenderPipelineRelease(renderPipeline._impl);
    log.info("Released RenderPipeline", .{});
}


extern "c" fn wgpuRenderPipelineGetBindGroupLayout(renderPipeline: RenderPipelineImpl, groupIndex: u32) ?*BindGroup.Layout;
pub fn GetBindGroupLayout(renderPipeline: RenderPipeline, groupIndex: u32) WGPUError!*BindGroup.Layout {
    const maybe_layout = wgpuRenderPipelineGetBindGroupLayout(renderPipeline._impl, groupIndex);

    if (maybe_layout) |layout| {
        return layout;
    } else {
        return WGPUError.FailedToGetBindGroupLayout;
    }

}

// WGPUChainedStruct const * nextInChain;
// WGPU_NULLABLE char const * label;
// WGPU_NULLABLE WGPUPipelineLayout layout;
// WGPUVertexState vertex;
// WGPUPrimitiveState primitive;
// WGPU_NULLABLE WGPUDepthStencilState const * depthStencil;
// WGPUMultisampleState multisample;
// WGPU_NULLABLE WGPUFragmentState const * fragment;


