const std = @import("std");
const log = std.log.scoped(.@"wgpu/command encoder");
const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const CommandBuffer = wgpu.CommandBuffer;
const CommandBufferImpl = CommandBuffer.CommandBufferImpl;
const RenderPass = wgpu.RenderPass;
const Buffer = wgpu.Buffer;
const BufferImpl = Buffer.BufferImpl;

const CommandEncoder = @This();
pub const CommandEncoderImpl = *opaque {};

_inner: CommandEncoderImpl,

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: [*]const u8 = "",
}; 

extern "c" fn wgpuCommandEncoderRelease(commandEncoder: CommandEncoderImpl) void;
pub fn Release(commandEncoder: CommandEncoder) void {
    wgpuCommandEncoderRelease(commandEncoder._inner);
    // log.debug("Released command encoder", .{});
}


extern "c" fn wgpuCommandEncoderInsertDebugMarker(commandEncoder: CommandEncoderImpl, markerLabel: [*c]const u8) void;
pub fn InsertDebugMarker(commandEncoder: CommandEncoder, markerLabel: [*c]const u8) void {
    wgpuCommandEncoderInsertDebugMarker(commandEncoder._inner, markerLabel);
    log.info("Insterted debug marker", .{});
}


extern "c" fn wgpuCommandEncoderFinish(commandEncoder: CommandEncoderImpl, descriptor: ?*const CommandBuffer.Descriptor) CommandBufferImpl;
pub fn Finish(commandEncoder: CommandEncoder, descriptor: ?*const CommandBuffer.Descriptor) CommandBuffer {

    const cb_inner = wgpuCommandEncoderFinish(commandEncoder._inner, descriptor);
    // log.info("Finished", .{});
    return CommandBuffer{ ._inner = cb_inner };

}



extern "c" fn wgpuCommandEncoderBeginRenderPass(commandEncoder: CommandEncoderImpl, descriptor: *const RenderPass.Descriptor) ?RenderPass.EncoderImpl;
pub fn BeginRenderPass(commandEncoder: CommandEncoder, descriptor: *const RenderPass.Descriptor) WGPUError!RenderPass.Encoder {
    const maybe_impl = wgpuCommandEncoderBeginRenderPass(commandEncoder._inner, descriptor);

    if (maybe_impl) |impl| return RenderPass.Encoder{ ._impl = impl } else return error.FailedToBeginRenderPass;
}


extern "c" fn wgpuCommandEncoderCopyBufferToBuffer(
    encoder: CommandEncoderImpl,
    source: BufferImpl,
    sourceOffset: u64,
    destination: BufferImpl,
    destinationOffset: u64,
    size: usize
) void;

pub fn CopyBufferToBuffer(
    encoder: CommandEncoder, 
    source: Buffer, 
    source_offset: u64, 
    destination: Buffer,
    destination_offset: u64,
    size: usize
) void {
    wgpuCommandEncoderCopyBufferToBuffer(
        encoder._inner,
        source._impl, 
        source_offset,
        destination._impl,
        destination_offset,
        size
    );  
}
