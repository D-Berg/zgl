const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

pub const CommandBuffer = opaque {
    extern "c" fn wgpuCommandBufferRelease(command_buffer: ?*const CommandBuffer) void;
    pub fn release(command_buffer: *const CommandBuffer) void {
        wgpuCommandBufferRelease(command_buffer);
    }
};
