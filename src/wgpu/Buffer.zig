const std = @import("std");
const log = std.log.scoped(.@"wgpu/Buffer");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const WGPUError = wgpu.WGPUError;

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
    usage: wgpu.Flag = @intFromEnum(Usage.None), // TODO: take a [2]Usage
    size: u64 = 0,
    mappedAtCreation: bool = false,
};

extern "c" fn wgpuBufferRelease(buffer: BufferImpl) void;
pub fn Release(buffer: Buffer) void {
    log.info("Released Buffer", .{});
    wgpuBufferRelease(buffer._impl);
}


extern "c" fn wgpuBufferGetSize(buffer: BufferImpl) u64;
pub fn GetSize(buffer: Buffer) u64 {
    return wgpuBufferGetSize(buffer._impl);
}
extern "c" fn wgpuBufferGetMappedRange(buffer: BufferImpl, offset: usize, size: usize) ?*anyopaque;

pub fn GetMappedRange(buffer: Buffer, comptime T: type) WGPUError![]T {
    const size: usize = @intCast(buffer.GetSize());

    const maybe_ptr = wgpuBufferGetMappedRange(buffer._impl, 0, size);

    if (maybe_ptr) |ptr| {

        var range: []T = undefined;
        range.ptr = @alignCast(@ptrCast(ptr));
        range.len = size / @sizeOf(T);
        return range;

    } else {
        return WGPUError.FailedToGetBufferMappedRange;
    }

}

extern "c" fn wgpuBufferUnmap(buffer: BufferImpl) void;
pub fn unmap(buffer: Buffer) void {
    wgpuBufferUnmap(buffer._impl);
}
