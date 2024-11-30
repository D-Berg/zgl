const std = @import("std");
const log = std.log.scoped(.@"wgpu/queue");
const wgpu = @import("wgpu.zig");
const Adapter = wgpu.Adapter;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterStatus = wgpu.RequestAdapterStatus;
const CommandBuffer = wgpu.CommandBuffer;
const CommandBufferImpl = CommandBuffer.CommandBufferImpl;

const Queue = @This();
pub const QueueImpl = *opaque {};

_inner: QueueImpl,

pub const Descriptor = struct {
    nextInChain: ?ChainedStruct = null,
    label: [*c]const u8 = ""
};

extern "c" fn wgpuQueueRelease(queue: QueueImpl) void;
pub fn Release(queue: Queue) void {
    wgpuQueueRelease(queue._inner);
    log.info("released queue", .{});

}

extern "c" fn wgpuQueueOnSubmittedWorkDone(
    queue: QueueImpl, 
    callback: OnSubmittedWorkDoneCallback, 
    userdata: ?*anyopaque
) void;
/// set up a function to be called back once the queues work is done. Takes a pointet to a user defined func 
/// wich need to match OnSubmittedWorkDoneCallback
pub fn OnSubmittedWorkDone(queue: Queue, callback: OnSubmittedWorkDoneCallback, userdata: ?*anyopaque) void {
    wgpuQueueOnSubmittedWorkDone(queue._inner, callback, userdata);
}

pub const OnSubmittedWorkDoneCallback = *const fn(
    status: WorkDoneStatus, 
    message: [*c]const u8, 
    userdata: ?*anyopaque
) callconv(.C) void;

pub const WorkDoneStatus = enum(u32) {
    Success = 0x00000000,
    Error = 0x00000001,
    Unknown = 0x00000002,
    DeviceLost = 0x00000003,
    Force32 = 0x7FFFFFFF
};



extern "c" fn wgpuQueueSubmit(queue: QueueImpl, commandCount: usize, commands: [*]const CommandBufferImpl) void;
pub fn Submit(queue: Queue, commands: []const CommandBufferImpl) void {
    // log.info("Submitting commands...", .{});
    const commandCount = commands.len;
    wgpuQueueSubmit(queue._inner, commandCount, commands.ptr);
    // log.info("Commands Submitted", .{});
}
