const std = @import("std");
const log = std.log.scoped(.@"wgpu/queue");
const wgpu = @import("wgpu.zig");
const Adapter = wgpu.Adapter;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterStatus = wgpu.RequestAdapterStatus;
const CommandBuffer = wgpu.CommandBuffer;
const CommandBufferImpl = CommandBuffer.CommandBufferImpl;
const Buffer = wgpu.Buffer;
const BufferImpl = Buffer.BufferImpl;

pub const Queue = opaque {
    pub const Descriptor = struct {
        nextInChain: ?ChainedStruct = null,
        label: [*c]const u8 = ""
    };

    extern "c" fn wgpuQueueRelease(queue: *Queue) void;
    pub fn Release(queue: *Queue) void {
        wgpuQueueRelease(queue);
        log.info("released queue", .{});

    }

    extern "c" fn wgpuQueueOnSubmittedWorkDone(
        queue: *Queue, 
        callback: OnSubmittedWorkDoneCallback, 
        userdata: ?*anyopaque
    ) void;
    /// set up a function to be called back once the queues work is done. Takes a pointet to a user defined func 
    /// wich need to match OnSubmittedWorkDoneCallback
    pub fn OnSubmittedWorkDone(queue: *Queue, callback: OnSubmittedWorkDoneCallback, userdata: ?*anyopaque) void {
        wgpuQueueOnSubmittedWorkDone(queue, callback, userdata);
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



    extern "c" fn wgpuQueueSubmit(queue: *Queue, commandCount: usize, commands: [*]const CommandBufferImpl) void;
    pub fn Submit(queue: *Queue, commands: []const CommandBuffer) void {
        // log.info("Submitting commands...", .{});
        const commandCount = commands.len;

        const impl_slice = @as([]const CommandBufferImpl, @ptrCast(commands));

        wgpuQueueSubmit(queue, commandCount, impl_slice.ptr);
        // log.info("Commands Submitted", .{});
    }

    // WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size) WGPU_FUNCTION_ATTRIBUTE;
    extern "c" fn wgpuQueueWriteBuffer(
        queue: *Queue, 
        buffer: BufferImpl, 
        bufferOffet: u64, 
        data: *const anyopaque, 
        size: usize
    ) void;

    pub fn WriteBuffer(
        queue: *Queue, 
        buffer: Buffer, 
        buffer_offset: u64, 
        comptime T: type, 
        data: []const T
    ) void{
        wgpuQueueWriteBuffer(
            queue, 
            buffer._impl, 
            buffer_offset, 
            data.ptr, 
            data.len
        );
    }

};
