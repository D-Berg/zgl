const std = @import("std");
const log = std.log.scoped(.@"wgpu/ComputePipeline");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const PipeLineLayout = wgpu.PipelineLayout;
const PipeLineLayoutImpl = PipeLineLayout.PipelineLayoutImpl;
const ProgrammableStageDescriptor = wgpu.ProgrammableStageDescriptor;
const BindgroupLayout = wgpu.BindGroupLayout;

pub const ComputePipeline = opaque {
    extern "c" fn wgpuComputePipelineRelease(compute_pipeline: ?*const ComputePipeline) void;
    pub fn release(compute_pipeline: *const ComputePipeline) void {
        wgpuComputePipelineRelease(compute_pipeline);
        log.info("Released ComputePipeline", .{});
    }

    extern "c" fn wgpuComputePipelineGetBindGroupLayout(
        compute_pipeline: ?*const ComputePipeline,
        group_index: u32,
    ) ?*const BindgroupLayout;
    pub fn getBindGroupLayout(
        compute_pipeline: *const ComputePipeline,
        group_index: u32,
    ) WGPUError!*const BindgroupLayout {
        const maybe_layout = wgpuComputePipelineGetBindGroupLayout(compute_pipeline, group_index);

        if (maybe_layout) |layout| {
            log.info("Got BindgroupLayout for index {}", .{group_index});
            return layout;
        } else {
            log.err("Failed to get BindgroupLayout {}", .{group_index});
            return WGPUError.FailedToGetBindGroupLayout;
        }
    }
};
