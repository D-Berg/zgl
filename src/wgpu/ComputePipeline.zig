const std = @import("std");
const log = std.log.scoped(.@"wgpu/ComputePipeline");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const PipeLineLayout = wgpu.PipelineLayout;
const PipeLineLayoutImpl = PipeLineLayout.PipelineLayoutImpl;
const ProgrammableStageDescriptor = wgpu.ProgrammableStageDescriptor;
const BindgroupLayout = wgpu.BindGroupLayout;

pub const ComputePipeline = *ComputePipelineImpl;
pub const ComputePipelineImpl = opaque {

    extern "c" fn wgpuComputePipelineRelease(compute_pipeline: ComputePipeline) void;
    pub fn release(computePipeline: ComputePipeline) void {
        wgpuComputePipelineRelease(computePipeline);
        log.info("Released ComputePipeline", .{});
    }
    
    extern "c" fn wgpuComputePipelineGetBindGroupLayout(computePipeline: ComputePipeline, groupIndex: u32) ?BindgroupLayout;
    pub fn GetBindGroupLayout(computePipeline: ComputePipeline, groupIndex: u32) WGPUError!BindgroupLayout {

        const maybe_layout = wgpuComputePipelineGetBindGroupLayout(computePipeline, groupIndex);

        if (maybe_layout) |layout| {
            log.info("Got BindgroupLayout for index {}", .{groupIndex});
            return layout;
        } else {
            log.err("Failed to get BindgroupLayout {}", .{groupIndex});
            return WGPUError.FailedToGetBindGroupLayout;
        }
    
    }
    
};
