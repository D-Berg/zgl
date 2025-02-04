const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

pub const CommandBuffer = *CommandBufferImpl;
const CommandBufferImpl = opaque {

    extern "c" fn wgpuCommandBufferRelease(commandBuffer: CommandBuffer) void;
    pub fn release(commandBuffer: CommandBuffer) void {
        wgpuCommandBufferRelease(commandBuffer);
    }

};


