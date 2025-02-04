const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const StringView = wgpu.StringView;
const QuerySet = wgpu.QuerySet;
const ComputePipeline = wgpu.ComputePipeline;
const BindGroup = wgpu.BindGroup;


pub const ComputePassEncoder = *ComputePassEncoderImpl;
const ComputePassEncoderImpl = opaque { 

    extern "c" fn wgpuComputePassEncoderRelease(computePassEncoder: ComputePassEncoder) void;
    pub fn release(computePassEncoder: ComputePassEncoder) void {
        wgpuComputePassEncoderRelease(computePassEncoder);
    }

    extern "c" fn wgpuComputePassEncoderSetPipeline(
        computePassEncoder: ComputePassEncoder, 
        pipeline: ComputePipeline
    ) void;
    pub fn setPipeline(computePassEncoder: ComputePassEncoder, pipeline: ComputePipeline) void {
        wgpuComputePassEncoderSetPipeline(computePassEncoder, pipeline);
    }

    extern "c" fn wgpuComputePassEncoderSetBindGroup(
        computePassEncoder: ComputePassEncoder, 
        groupIndex: u32, 
        group: ?BindGroup,
        dynamicOffsetCount: usize,
        dynamicOffsets: ?[*]const u32
    ) void;

    pub fn setBindGroup(
        computePassEncoder: ComputePassEncoder,
        groupIndex: u32,
        group: ?BindGroup,
    ) void {
        wgpuComputePassEncoderSetBindGroup(computePassEncoder, groupIndex, group, 0, null);
    }

    extern "c" fn wgpuComputePassEncoderDispatchWorkgroups(
        computePassEncoder: ComputePassEncoder,
        workgroupcountx: u32,
        workgroupcounty: u32,
        workgroupcountz: u32,
    ) void;
    pub fn dispatchWorkGroups(
        computePassEncoder: ComputePassEncoder,
        workgroupcountx: u32,
        workgroupcounty: u32,
        workgroupcountz: u32,
    ) void {
        wgpuComputePassEncoderDispatchWorkgroups(
            computePassEncoder, 
            workgroupcountx, 
            workgroupcounty, 
            workgroupcountz
        );
    }


    extern "c" fn wgpuComputePassEncoderEnd(computePassEncoder: ComputePassEncoder) void;
    pub fn end(computePassEncoder: ComputePassEncoder) void {
        wgpuComputePassEncoderEnd(computePassEncoder);
    }



};

