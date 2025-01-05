const std = @import("std");
const log = std.log.scoped(.@"wgpu/ComputePipeline");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const PipeLineLayout = wgpu.PipelineLayout;
const PipeLineLayoutImpl = PipeLineLayout.PipelineLayoutImpl;
const ProgrammableStageDescriptor = wgpu.ProgrammableStageDescriptor;
const Bindgroup = wgpu.BindGroup;

pub const ComputePipeline = opaque {
    pub const Descriptor = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        label: wgpu.StringView = .{ .data = "", .length = 0 },
        layout: ?PipeLineLayoutImpl = null,
        compute: ProgrammableStageDescriptor
    };

    extern "c" fn wgpuComputePipelineRelease(compute_pipeline: *ComputePipeline) void;
    pub fn Release(compute_pipeline: *ComputePipeline) void {
        wgpuComputePipelineRelease(compute_pipeline);
        log.info("Released ComputePipeline", .{});
    }
    
    extern "c" fn wgpuComputePipelineGetBindGroupLayout(computePipeline: *ComputePipeline, groupIndex: u32) ?*Bindgroup.Layout;
    pub fn GetBindGroupLayout(computePipeline: *ComputePipeline, groupIndex: u32) WGPUError!*Bindgroup.Layout {

        const maybe_layout = wgpuComputePipelineGetBindGroupLayout(computePipeline, groupIndex);

        if (maybe_layout) |layout| {
            log.info("Got BindgroupLayout {}", .{groupIndex});
            return layout;
        } else {
            log.err("Failed to get BindgroupLayout {}", .{groupIndex});
            return WGPUError.FailedToGetBindGroupLayout;
        }
    
    }


    
};
