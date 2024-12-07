const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

pub const Buffer = @This();
pub const BufferImpl = *opaque {};

_impl: BufferImpl,

pub const Usage = enum(u32) {
    None = 0x00000000,
    MapRead = 0x00000001,
    MapWrite = 0x00000002,
    CopySrc = 0x00000004,
    CopyDst = 0x00000008,
    Index = 0x00000010,
    Vertex = 0x00000020,
    Uniform = 0x00000040,
    Storage = 0x00000080,
    Indirect = 0x00000100,
    QueryResolve = 0x00000200,
    Force32 = 0x7FFFFFFF
};

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: ?[*]const u8 = null,
    usage: u32,
    size: u64,
    mappedAtCreation: bool,
};

extern "c" fn wgpuBufferRelease(buffer: BufferImpl) void;
pub fn Release(buffer: Buffer) void {
    wgpuBufferRelease(buffer._impl);
}
