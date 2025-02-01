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

const c = @import("../zgl.zig").c;

pub const RenderPipeline = *RenderPipelineImpl;
const RenderPipelineImpl = opaque {

    extern "c" fn wgpuRenderPipelineRelease(renderPipeline: RenderPipeline) void;
    pub fn Release(renderPipeline: RenderPipeline) void {
        wgpuRenderPipelineRelease(renderPipeline);
        log.info("Released RenderPipeline", .{});
    }


    extern "c" fn wgpuRenderPipelineGetBindGroupLayout(renderPipeline: RenderPipeline, groupIndex: u32) ?BindGroupLayout;
    pub fn GetBindGroupLayout(renderPipeline: RenderPipeline, groupIndex: u32) WGPUError!BindGroupLayout {
        const maybe_layout = wgpuRenderPipelineGetBindGroupLayout(renderPipeline, groupIndex);

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


