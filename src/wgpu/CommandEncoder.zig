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

pub const CommandEncoder = *CommandEncoderImpl;
const CommandEncoderImpl = opaque {

    extern "c" fn wgpuCommandEncoderRelease(commandEncoder: CommandEncoder) void;
    pub fn release(commandEncoder: CommandEncoder) void {
        wgpuCommandEncoderRelease(commandEncoder);
        // log.debug("Released command encoder", .{});
    }


    // TODO: check if need updating
    extern "c" fn wgpuCommandEncoderInsertDebugMarker(commandEncoder: CommandEncoder, markerLabel: [*c]const u8) void;
    pub fn insertDebugMarker(commandEncoder: CommandEncoder, markerLabel: [*c]const u8) void {
        wgpuCommandEncoderInsertDebugMarker(commandEncoder, markerLabel);
        log.info("Insterted debug marker", .{});
    }



    // TODO: update
    extern "c" fn wgpuCommandEncoderFinish(
        commandEncoder: CommandEncoder, 
        descriptor: ?*const CommandBufferDescriptor
    ) ?CommandBuffer;
    pub fn finish(commandEncoder: CommandEncoder, descriptor: ?*const CommandBufferDescriptor) WGPUError!CommandBuffer {

        const maybe_command_buffer = wgpuCommandEncoderFinish(commandEncoder, descriptor);

        if (maybe_command_buffer) |command_buffer| {
            return command_buffer;
        } else {
            return WGPUError.FailedToFinishCommandEncoder;
        }

    }


    extern "c" fn wgpuCommandEncoderBeginRenderPass(
        commandEncoder: CommandEncoder, 
        descriptor: *const RenderPassDescriptor
    ) ?RenderPassEncoder;

    pub fn BeginRenderPass(
        commandEncoder: CommandEncoder, 
        descriptor: *const RenderPassDescriptor
    ) WGPUError!RenderPassEncoder {

        const maybe_render_pass_encoder = wgpuCommandEncoderBeginRenderPass(commandEncoder, descriptor);

        if (maybe_render_pass_encoder) |render_pass_encoder| {
            return render_pass_encoder; 
        } else {
            return error.FailedToBeginRenderPass;
        }
    }

    
    extern "c" fn wgpuCommandEncoderBeginComputePass(
        commandEncoder: CommandEncoder, 
        descriptor: ?*const ComputePassEncoderDescriptor
    ) ?ComputePassEncoder;

    pub fn beginComputePass(
        commandEncoder: CommandEncoder, 
        descriptor: ?*const ComputePassEncoderDescriptor
    ) WGPUError!ComputePassEncoder {

        const maybe_compute_pass_encoder = wgpuCommandEncoderBeginComputePass(
            commandEncoder, 
            descriptor
        );

        if (maybe_compute_pass_encoder) |compute_pass_encoder| {
            return compute_pass_encoder;
        } else {
            return WGPUError.FailedToCreateComputePassEncoder;
        }

    }

    extern "c" fn wgpuCommandEncoderCopyBufferToBuffer(
        commandEncoder: CommandEncoder,
        source: Buffer,
        sourceOffset: u64,
        destination: Buffer,
        destinationOffset: u64,
        size: usize
    ) void;

    pub fn copyBufferToBuffer(
        commandEncoder: CommandEncoder, 
        source: Buffer, 
        source_offset: u64, 
        destination: Buffer,
        destination_offset: u64,
        size: usize
    ) void {
        wgpuCommandEncoderCopyBufferToBuffer(
            commandEncoder,
            source, 
            source_offset,
            destination,
            destination_offset,
            size
        );  
    }

};













