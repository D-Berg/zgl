const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

const CommandBuffer = @This();
pub const CommandBufferImpl = *opaque {};

_inner: CommandBufferImpl,

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: [*]const u8 = "",
};

extern "c" fn wgpuCommandBufferRelease(commandBuffer: CommandBufferImpl) void;
pub fn Release(commandBuffer: CommandBuffer) void {
    wgpuCommandBufferRelease(commandBuffer._inner);
}
