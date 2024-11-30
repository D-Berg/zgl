const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayoutImpl = wgpu.PipelineLayout.PipelineLayoutImpl;
const VertexState = wgpu.VertexState;
const PrimitiveState = wgpu.PrimitiveState;
const DepthStencilState = wgpu.DepthStencilState;
const MultiSampleState = wgpu.MultiSampleState;
const FragmentState = wgpu.FragmentState;

const RenderPipeline = @This();
pub const RenderPipelineImpl = *opaque {};

_impl: RenderPipelineImpl,

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: ?[*]const u8 = null,
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
}


// WGPUChainedStruct const * nextInChain;
// WGPU_NULLABLE char const * label;
// WGPU_NULLABLE WGPUPipelineLayout layout;
// WGPUVertexState vertex;
// WGPUPrimitiveState primitive;
// WGPU_NULLABLE WGPUDepthStencilState const * depthStencil;
// WGPUMultisampleState multisample;
// WGPU_NULLABLE WGPUFragmentState const * fragment;


