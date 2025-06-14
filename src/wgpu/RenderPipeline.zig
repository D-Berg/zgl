const std = @import("std");
const log = std.log.scoped(.@"wgpu/RenderPipeline");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const PipelineLayout = wgpu.PipelineLayout;
const VertexState = wgpu.VertexState;
const PrimitiveState = wgpu.PrimitiveState;
const DepthStencilState = wgpu.DepthStencilState;
const MultiSampleState = wgpu.MultiSampleState;
const FragmentState = wgpu.FragmentState;
const BindGroupLayout = wgpu.BindGroupLayout;

pub const RenderPipeline = opaque {
    extern "c" fn wgpuRenderPipelineRelease(render_pipeline: ?*const RenderPipeline) void;
    pub fn release(render_pipeline: *const RenderPipeline) void {
        wgpuRenderPipelineRelease(render_pipeline);
        log.info("Released RenderPipeline", .{});
    }

    extern "c" fn wgpuRenderPipelineGetBindGroupLayout(
        render_pipeline: ?*const RenderPipeline,
        group_index: u32,
    ) ?BindGroupLayout;
    pub fn getBindGroupLayout(
        render_pipeline: *const RenderPipeline,
        group_index: u32,
    ) WGPUError!*const BindGroupLayout {
        const maybe_layout = wgpuRenderPipelineGetBindGroupLayout(
            render_pipeline,
            group_index,
        );

        if (maybe_layout) |layout| {
            return layout;
        } else {
            return WGPUError.FailedToGetBindGroupLayout;
        }
    }
};

// const RenderPipelineDescriptor = struct {
//     nextInChain: ?*const ChainedStruct = null,
//     label: []const u8 = "",
//     layout: ?PipelineLayoutImpl = null,
//     vertex: VertexState,
//     primitive: PrimitiveState,
//     depthStencil: ?*const DepthStencilState = null,
//     multisample: MultiSampleState,
//     fragment: ?*const FragmentState = null,
// };
//

// WGPUChainedStruct const * nextInChain;
// WGPU_NULLABLE char const * label;
// WGPU_NULLABLE WGPUPipelineLayout layout;
// WGPUVertexState vertex;
// WGPUPrimitiveState primitive;
// WGPU_NULLABLE WGPUDepthStencilState const * depthStencil;
// WGPUMultisampleState multisample;
// WGPU_NULLABLE WGPUFragmentState const * fragment;
