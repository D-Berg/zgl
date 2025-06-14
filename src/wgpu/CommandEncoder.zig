const std = @import("std");
const log = std.log.scoped(.@"wgpu/command encoder");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const CommandBuffer = wgpu.CommandBuffer;
const RenderPassEncoder = wgpu.RenderPassEncoder;
const Buffer = wgpu.Buffer;
const ComputePassEncoder = wgpu.ComputePassEncoder;
const CommandBufferDescriptor = wgpu.CommandBufferDescriptor;
const ComputePassEncoderDescriptor = wgpu.ComputePassEncoderDescriptor;
const RenderPassDescriptor = wgpu.RenderPassDescriptor;

pub const CommandEncoder = opaque {
    extern "c" fn wgpuCommandEncoderRelease(command_encoder: ?*const CommandEncoder) void;
    pub fn release(command_encoder: *const CommandEncoder) void {
        wgpuCommandEncoderRelease(command_encoder);
        // log.debug("Released command encoder", .{});
    }

    // TODO: check if need updating
    extern "c" fn wgpuCommandEncoderInsertDebugMarker(
        command_encoder: ?*const CommandEncoder,
        marker_label: [*c]const u8,
    ) void;

    pub fn insertDebugMarker(
        command_encoder: *const CommandEncoder,
        marker_label: [*c]const u8,
    ) void {
        wgpuCommandEncoderInsertDebugMarker(command_encoder, marker_label);
        log.info("Insterted debug marker", .{});
    }

    // TODO: update
    extern "c" fn wgpuCommandEncoderFinish(
        command_encoder: ?*const CommandEncoder,
        descriptor: ?*const CommandBufferDescriptor,
    ) ?*const CommandBuffer;

    pub fn finish(
        command_encoder: *const CommandEncoder,
        descriptor: ?*const CommandBufferDescriptor,
    ) WGPUError!*const CommandBuffer {
        const maybe_command_buffer = wgpuCommandEncoderFinish(command_encoder, descriptor);

        if (maybe_command_buffer) |command_buffer| {
            return command_buffer;
        } else {
            return WGPUError.FailedToFinishCommandEncoder;
        }
    }

    extern "c" fn wgpuCommandEncoderBeginRenderPass(
        command_encoder: ?*const CommandEncoder,
        descriptor: *const RenderPassDescriptor,
    ) ?*const RenderPassEncoder;

    pub fn beginRenderPass(
        command_encoder: *const CommandEncoder,
        descriptor: *const RenderPassDescriptor,
    ) WGPUError!*const RenderPassEncoder {
        const maybe_render_pass_encoder = wgpuCommandEncoderBeginRenderPass(
            command_encoder,
            descriptor,
        );

        if (maybe_render_pass_encoder) |render_pass_encoder| {
            return render_pass_encoder;
        } else {
            return error.FailedToBeginRenderPass;
        }
    }

    extern "c" fn wgpuCommandEncoderBeginComputePass(
        command_encoder: ?*const CommandEncoder,
        descriptor: ?*const ComputePassEncoderDescriptor,
    ) ?*const ComputePassEncoder;

    pub fn beginComputePass(
        command_encoder: *const CommandEncoder,
        descriptor: ?*const ComputePassEncoderDescriptor,
    ) WGPUError!*const ComputePassEncoder {
        const maybe_compute_pass_encoder = wgpuCommandEncoderBeginComputePass(
            command_encoder,
            descriptor,
        );

        if (maybe_compute_pass_encoder) |compute_pass_encoder| {
            return compute_pass_encoder;
        } else {
            return WGPUError.FailedToCreateComputePassEncoder;
        }
    }

    extern "c" fn wgpuCommandEncoderCopyBufferToBuffer(
        command_encoder: ?*const CommandEncoder,
        source: ?*const Buffer,
        source_offset: u64,
        destination: ?*const Buffer,
        destination_offset: u64,
        size: usize,
    ) void;

    pub fn copyBufferToBuffer(
        command_encoder: *const CommandEncoder,
        source: *const Buffer,
        source_offset: u64,
        destination: *const Buffer,
        destination_offset: u64,
        size: usize,
    ) void {
        wgpuCommandEncoderCopyBufferToBuffer(
            command_encoder,
            source,
            source_offset,
            destination,
            destination_offset,
            size,
        );
    }
};
