const std = @import("std");
const log = std.log.scoped(.@"wgpu/queue");
const wgpu = @import("wgpu.zig");
const Adapter = wgpu.Adapter;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterStatus = wgpu.RequestAdapterStatus;
const CommandBuffer = wgpu.CommandBuffer;
const Buffer = wgpu.Buffer;

pub const Queue = opaque {
    extern "c" fn wgpuQueueRelease(queue: ?*const Queue) void;
    pub fn release(queue: *const Queue) void {
        wgpuQueueRelease(queue);
        log.info("released queue", .{});
    }

    extern "c" fn wgpuQueueOnSubmittedWorkDone(
        queue: ?*const Queue,
        callbackInfo: WorkDoneCallbackInfo,
    ) wgpu.Future;
    /// set up a function to be called back once the queues work is done. Takes a pointet to a user defined func
    /// wich need to match OnSubmittedWorkDoneCallback
    pub fn onSubmittedWorkDone(queue: *const Queue, callback_info: WorkDoneCallbackInfo) wgpu.Future {
        return wgpuQueueOnSubmittedWorkDone(queue, callback_info);
    }
    pub const WorkDoneCallback = *const fn (
        status: WorkDoneStatus,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.C) void;

    pub const WorkDoneStatus = enum(u32) {
        Success = 0x00000001,
        InstanceDropped = 0x00000002,
        Error = 0x00000003,
        Unknown = 0x00000004,
        Force32 = 0x7FFFFFFF,
    };

    pub const WorkDoneCallbackInfo = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        mode: wgpu.CallBackMode = .WaitAnyOnly,
        callback: WorkDoneCallback,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    };

    extern "c" fn wgpuQueueSubmit(
        queue: ?*const Queue,
        commandCount: usize,
        commands: [*]const *const CommandBuffer,
    ) void;

    pub fn submit(queue: *const Queue, commands: []const *const CommandBuffer) void {
        wgpuQueueSubmit(queue, commands.len, commands.ptr);
    }

    extern "c" fn wgpuQueueWriteBuffer(
        queue: ?*const Queue,
        buffer: ?*const Buffer,
        buffer_offet: u64,
        data: *const anyopaque,
        size: usize,
    ) void;

    // TODO: rename to writeBuffer
    pub fn writeBuffer(queue: *const Queue, buffer: *const Buffer, buffer_offset: u64, comptime T: type, data: []const T) void {
        const size = data.len * @sizeOf(T);
        wgpuQueueWriteBuffer(queue, buffer, buffer_offset, data.ptr, size);

        log.debug("wrote {} bytes to buffer", .{size});
    }
};
