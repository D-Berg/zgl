const std = @import("std");
const log = std.log.scoped(.@"wgpu/queue");
const wgpu = @import("wgpu.zig");
const Adapter = wgpu.Adapter;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterStatus = wgpu.RequestAdapterStatus;
const CommandBuffer = wgpu.CommandBuffer;
const Buffer = wgpu.Buffer;

pub const Queue = *opaque {

    extern "c" fn wgpuQueueRelease(queue: Queue) void;
    pub fn release(queue: Queue) void {
        wgpuQueueRelease(queue);
        log.info("released queue", .{});

    }

    extern "c" fn wgpuQueueOnSubmittedWorkDone(
        queue: Queue, 
        callbackInfo: WorkDoneCallbackInfo, 
    ) wgpu.Future;
    /// set up a function to be called back once the queues work is done. Takes a pointet to a user defined func 
    /// wich need to match OnSubmittedWorkDoneCallback
    pub fn OnSubmittedWorkDone(queue: Queue, callbackInfo: WorkDoneCallbackInfo) wgpu.Future {
        return wgpuQueueOnSubmittedWorkDone(queue, callbackInfo);
    }
    pub const WorkDoneCallback = *const fn(
        status: WorkDoneStatus, 
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.C) void;

    pub const WorkDoneStatus = enum(u32) {
        Success = 0x00000001,
        InstanceDropped = 0x00000002,
        Error = 0x00000003,
        Unknown = 0x00000004,
        Force32 = 0x7FFFFFFF
    };
    
    pub const WorkDoneCallbackInfo = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        mode: wgpu.CallBackMode = .WaitAnyOnly,
        callback: WorkDoneCallback,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    };


    extern "c" fn wgpuQueueSubmit(queue: Queue, commandCount: usize, commands: [*]const CommandBuffer) void;
    pub fn submit(queue: Queue, commands: []const CommandBuffer) void {

        wgpuQueueSubmit(queue, commands.len, commands.ptr);

    }

    // WGPU_EXPORT void wgpuQueueWriteBuffer(WGPUQueue queue, WGPUBuffer buffer, uint64_t bufferOffset, void const * data, size_t size) WGPU_FUNCTION_ATTRIBUTE;
    extern "c" fn wgpuQueueWriteBuffer(
        queue: Queue, 
        buffer: Buffer, 
        bufferOffet: u64, 
        data: *const anyopaque, 
        size: usize
    ) void;

    // TODO: rename to writeBuffer
    pub fn WriteBuffer(
        queue: Queue, 
        buffer: Buffer, 
        buffer_offset: u64, 
        comptime T: type, 
        data: []const T
    ) void{
        wgpuQueueWriteBuffer(
            queue, 
            buffer, 
            buffer_offset, 
            data.ptr, 
            data.len * @sizeOf(T)
        );
    }

};
