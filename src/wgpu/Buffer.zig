const std = @import("std");
const log = std.log.scoped(.@"wgpu/Buffer");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;

pub const Buffer = @This();
pub const BufferImpl = *opaque {};

_impl: BufferImpl,

pub const Usage = enum(wgpu.Flag) {
    None = 0x0000000000000000,
    MapRead = 0x0000000000000001,
    MapWrite = 0x0000000000000002,
    CopySrc = 0x0000000000000004,
    CopyDst = 0x0000000000000008,
    Index = 0x0000000000000010,
    Vertex = 0x0000000000000020,
    Uniform = 0x0000000000000040,
    Storage = 0x0000000000000080,
    Indirect = 0x0000000000000100,
    QueryResolve = 0x0000000000000200,
};



pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: wgpu.StringView = .{ .data = "", .length = 0 },
    usage: wgpu.Flag = @intFromEnum(Usage.None),
    size: u64 = 0,
    mappedAtCreation: bool = false,
};

extern "c" fn wgpuBufferRelease(buffer: BufferImpl) void;
pub fn Release(buffer: Buffer) void {
    log.info("Released Buffer", .{});
    wgpuBufferRelease(buffer._impl);
}
