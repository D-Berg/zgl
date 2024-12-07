const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

pub const Buffer = @This();
pub const BufferImpl = *opaque {};

_impl: BufferImpl,

pub const Usage = enum(u32) {
    WGPUBufferUsage_None = 0x00000000,
    WGPUBufferUsage_MapRead = 0x00000001,
    WGPUBufferUsage_MapWrite = 0x00000002,
    WGPUBufferUsage_CopySrc = 0x00000004,
    WGPUBufferUsage_CopyDst = 0x00000008,
    WGPUBufferUsage_Index = 0x00000010,
    WGPUBufferUsage_Vertex = 0x00000020,
    WGPUBufferUsage_Uniform = 0x00000040,
    WGPUBufferUsage_Storage = 0x00000080,
    WGPUBufferUsage_Indirect = 0x00000100,
    WGPUBufferUsage_QueryResolve = 0x00000200,
    WGPUBufferUsage_Force32 = 0x7FFFFFFF
};

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: ?[*]const u8 = null,
    usage: u32,
    size: u64,
    mappedAtCreation: bool,
};

