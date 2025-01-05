const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const StringView = wgpu.StringView;
const QuerySet = wgpu.QuerySet;
const ComputePipeline = wgpu.ComputePipeline;
const BindGroup = wgpu.BindGroup;

pub const TimeStampWrites = extern struct {
    querySet: QuerySet.QuerySetImpl, 
    beginningOfPassWriteIndex: u32 = 0,
    endOfPassWriteIndex: u32 = 0
};

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{ .data = "", .length = 0 },
    timestampWrites: ?*const TimeStampWrites = null,
};

pub const Encoder = opaque { 
    extern "c" fn wgpuComputePassEncoderRelease(computePassEncoder: *Encoder) void;
    pub fn Release(encoder: *Encoder) void {
        wgpuComputePassEncoderRelease(encoder);
    }

    extern "c" fn wgpuComputePassEncoderSetPipeline(
        computePassEncoder: *Encoder, 
        pipeline: *ComputePipeline
    ) void;
    pub fn setPipeline(encoder: *Encoder, pipeline: *ComputePipeline) void {
        wgpuComputePassEncoderSetPipeline(encoder, pipeline);
    }

    extern "c" fn wgpuComputePassEncoderSetBindGroup(
        encoder: *Encoder, 
        groupIndex: u32, 
        group: ?*const BindGroup,
        dynamicOffsetCount: usize,
        dynamicOffsets: ?[*]const u32
    ) void;

    pub fn setBindGroup(
        encoder: *Encoder,
        groupIndex: u32,
        group: ?*const BindGroup,
    ) void {
        wgpuComputePassEncoderSetBindGroup(encoder, groupIndex, group, 0, null);
    }

    extern "c" fn wgpuComputePassEncoderDispatchWorkgroups(
        encoder: *Encoder,
        workgroupcountx: u32,
        workgroupcounty: u32,
        workgroupcountz: u32,
    ) void;

    pub fn dispatchWorkGroups(
        encoder: *Encoder,
        workgroupcountx: u32,
        workgroupcounty: u32,
        workgroupcountz: u32,
    ) void {
        wgpuComputePassEncoderDispatchWorkgroups(
            encoder, 
            workgroupcountx, 
            workgroupcounty, 
            workgroupcountz
        );
    }


    extern "c" fn wgpuComputePassEncoderEnd(encoder: *Encoder) void;
    pub fn end(encoder: *Encoder) void {
        wgpuComputePassEncoderEnd(encoder);
    }



};

