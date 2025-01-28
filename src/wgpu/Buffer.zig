const std = @import("std");
const log = std.log.scoped(.@"wgpu/Buffer");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const WGPUError = wgpu.WGPUError;

pub const Buffer = @This();
pub const BufferImpl = *opaque {};

_impl: BufferImpl,

/// https://gpuweb.github.io/gpuweb/#buffer-usage
pub const Usage = enum(wgpu.Flag) {
    None = 0x0000000000000000,
    /// The buffer can be mapped for reading. May only be combined with CopyDst.
    MapRead = 0x0000000000000001,
    /// The buffer can be mapped for writing. May only be combined with CopySrc.
    MapWrite = 0x0000000000000002,
    /// The buffer can be used as the source of a copy operation.
    CopySrc = 0x0000000000000004,
    /// The buffer can be used as the destination of a copy or write operation. 
    CopyDst = 0x0000000000000008,
    /// The buffer can be used as an index buffer. 
    Index = 0x0000000000000010,
    /// The buffer can be used as a vertex buffer.
    Vertex = 0x0000000000000020,
    /// The buffer can be used as a uniform buffer.
    Uniform = 0x0000000000000040,
    /// The buffer can be used as a storage buffer.
    Storage = 0x0000000000000080,
    /// The buffer can be used as to store indirect command arguments. 
    Indirect = 0x0000000000000100,
    /// The buffer can be used to capture query results.
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

/// Buffer need to be mapped in order to get mapped range.
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

const MapCallBackInfo = extern struct { 
    nextInChain: ?*const ChainedStruct = null,
    mode: wgpu.CallBackMode,
    callback: MapCallBack,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
};


const MapUserData1 = extern struct {
    status: wgpu.MapAsyncStatus = .Unknown
};

const MapCallBack = *const fn(
    status: wgpu.MapAsyncStatus,
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque
) callconv(.C) void;

/// Implementation of MapCallBack
fn onMapCallBack(
    status: wgpu.MapAsyncStatus,
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    _: ?*anyopaque
) callconv(.C) void {

    if (userdata1 == null) {
        log.err("didnt get any userdata", .{});
        return;
    }

    log.debug("BufferMap got message: {s}", .{message.toSlice()});

    var u1_data = @as(*MapUserData1, @ptrCast(@alignCast(userdata1.?)));
    u1_data.status = status;

}

extern "c" fn wgpuBufferMapAsync(buffer: BufferImpl, mode: wgpu.MapMode , offset: usize, size: usize, callbackInfo: MapCallBackInfo) wgpu.Future;

pub fn map(buffer: Buffer, mode: wgpu.MapMode, offset: usize, size: usize) WGPUError!void {

    // TODO: Check that buffer has correct flags MapWrite in usage, else throw err
    var userdata_1_impl = MapUserData1{};

    const callback_info = MapCallBackInfo{
        .mode = .WaitAnyOnly,
        .callback = onMapCallBack,
        .userdata1 = &userdata_1_impl,
        .userdata2 = null
    };
    _ = wgpuBufferMapAsync(buffer._impl, mode, offset, size, callback_info);

    switch (userdata_1_impl.status) {
        .Success => log.debug("successfully mapped buffer", .{}),
        .Aborted => {
            log.err("map buffer got aborted", .{});
            return WGPUError.FailedToMapBufferBecauseOfAbort;
        },
        .Error => {
            log.err("error occured when trying to map buffer", .{});
            return WGPUError.FailedToMapBufferBecauseOfError;
        },
        .InstanceDropped => {
            log.err("Failed to map buffer because of instance dropped", .{});
            return WGPUError.FailedToMapBufferBecauseOfDroppedInstance;
        },
        .Unknown => {
            log.err("failed to map buffer because of Unknown", .{});
            return WGPUError.FailedToMapBufferBecauseOfUnknown;
        },
        .Force32 => {
            log.err("failed to map buffer because of Force32", .{});
            return WGPUError.FailedToMapBufferBecauseOfForce32;
        }
    }

}

extern "c" fn wgpuBufferUnmap(buffer: BufferImpl) void;
pub fn unmap(buffer: Buffer) void {
    wgpuBufferUnmap(buffer._impl);
}
