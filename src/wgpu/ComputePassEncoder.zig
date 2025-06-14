const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const StringView = wgpu.StringView;
const QuerySet = wgpu.QuerySet;
const ComputePipeline = wgpu.ComputePipeline;
const BindGroup = wgpu.BindGroup;

const ComputePassEncoder = opaque {
    extern "c" fn wgpuComputePassEncoderRelease(
        compute_pass_encoder: ?*const ComputePassEncoder,
    ) void;
    pub fn release(compute_pass_encoder: *const ComputePassEncoder) void {
        wgpuComputePassEncoderRelease(compute_pass_encoder);
    }

    extern "c" fn wgpuComputePassEncoderSetPipeline(
        compute_pass_encoder: ?*const ComputePassEncoder,
        pipeline: ComputePipeline,
    ) void;
    pub fn setPipeline(
        compute_pass_encoder: *const ComputePassEncoder,
        pipeline: ComputePipeline,
    ) void {
        wgpuComputePassEncoderSetPipeline(compute_pass_encoder, pipeline);
    }

    extern "c" fn wgpuComputePassEncoderSetBindGroup(
        compute_pass_encoder: ?*const ComputePassEncoder,
        group_index: u32,
        group: ?BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: ?[*]const u32,
    ) void;

    pub fn setBindGroup(
        compute_pass_encoder: *const ComputePassEncoder,
        group_index: u32,
        group: ?*const BindGroup,
    ) void {
        wgpuComputePassEncoderSetBindGroup(
            compute_pass_encoder,
            group_index,
            group,
            0,
            null,
        );
    }

    extern "c" fn wgpuComputePassEncoderDispatchWorkgroups(
        compute_pass_encoder: ?*const ComputePassEncoder,
        work_group_count_x: u32,
        work_group_count_y: u32,
        work_group_count_z: u32,
    ) void;
    pub fn dispatchWorkGroups(
        compute_pass_encoder: *const ComputePassEncoder,
        work_group_count_x: u32,
        work_group_count_y: u32,
        work_group_count_z: u32,
    ) void {
        wgpuComputePassEncoderDispatchWorkgroups(
            compute_pass_encoder,
            work_group_count_x,
            work_group_count_y,
            work_group_count_z,
        );
    }

    extern "c" fn wgpuComputePassEncoderEnd(compute_pass_ncoder: ?*const ComputePassEncoder) void;
    pub fn end(compute_pass_encoder: *const ComputePassEncoder) void {
        wgpuComputePassEncoderEnd(compute_pass_encoder);
    }
};
