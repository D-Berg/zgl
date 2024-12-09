const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const PipeLineLayout = wgpu.PipelineLayout;
const PipeLineLayoutImpl = PipeLineLayout.PipelineLayoutImpl;
const ProgrammableStageDescriptor = wgpu.ProgrammableStageDescriptor;

pub const ComputePipeline = opaque {
    pub const Descriptor = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        label: ?[*]const u8 = null,
        layout: ?PipeLineLayoutImpl = null,
        compute: ProgrammableStageDescriptor
    };

    extern "c" fn wgpuComputePipelineRelease(compute_pipeline: *ComputePipeline) void;
    pub fn Release(compute_pipeline: *ComputePipeline) void {
        wgpuComputePipelineRelease(compute_pipeline);
    }
};
