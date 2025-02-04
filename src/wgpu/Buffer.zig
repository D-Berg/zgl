const std = @import("std");
const log = std.log.scoped(.@"wgpu/Buffer");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const WGPUError = wgpu.WGPUError;

pub const Buffer = *BufferImpl;
const BufferImpl = opaque {
    //WGPU_EXPORT void wgpuBufferDestroy(WGPUBuffer buffer) WGPU_FUNCTION_ATTRIBUTE;
    //WGPU_EXPORT void const * wgpuBufferGetConstMappedRange(WGPUBuffer buffer, size_t offset, size_t size) WGPU_FUNCTION_ATTRIBUTE;
    //WGPU_EXPORT WGPUBufferMapState wgpuBufferGetMapState(WGPUBuffer buffer) WGPU_FUNCTION_ATTRIBUTE;

    extern "c" fn wgpuBufferGetMappedRange(buffer: Buffer, offset: usize, size: usize) ?*anyopaque;
    /// Buffer need to be mapped in order to get mapped range.
    /// returns a slice T which can be used to write data to the GPU buffer
    pub fn getMappedRange(buffer: Buffer, comptime T: type, offset: usize, size: usize) WGPUError![]T {

        // TODO: check that buffer is mapped
    
        const maybe_ptr = wgpuBufferGetMappedRange(buffer, offset, size);

        if (maybe_ptr) |ptr| {

            var range: []T = undefined;
            range.ptr = @alignCast(@ptrCast(ptr));
            range.len = size / @sizeOf(T);
            return range;

        } else {
            return WGPUError.FailedToGetBufferMappedRange;
        }

    }

    extern "c" fn wgpuBufferGetSize(buffer: Buffer) u64;
    pub fn getSize(buffer: Buffer) u64 {
        return wgpuBufferGetSize(buffer);
    }


    
    //WGPU_EXPORT WGPUBufferUsage wgpuBufferGetUsage(WGPUBuffer buffer) WGPU_FUNCTION_ATTRIBUTE;


    extern "c" fn wgpuBufferMapAsync(
        buffer: Buffer, 
        mode: wgpu.MapMode, 
        offset: usize, 
        size: usize, 
        callbackInfo: BufferMapCallBackInfo
    ) wgpu.Future;
    /// Syncronous version of mapAsync
    pub fn map(buffer: Buffer, mode: wgpu.MapMode, offset: usize, size: usize) WGPUError!void {

        // TODO: Check that buffer has correct flags MapWrite in usage, else throw err
        var userdata_1_impl = MapUserData1{};

        const callback_info = BufferMapCallBackInfo{
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

    // WGPU_EXPORT void wgpuBufferSetLabel(WGPUBuffer buffer, WGPUStringView label) WGPU_FUNCTION_ATTRIBUTE;

    
    extern "c" fn wgpuBufferUnmap(buffer: Buffer) void;
    pub fn unmap(buffer: Buffer) void {
        wgpuBufferUnmap(buffer);
    }

    
    //WGPU_EXPORT void wgpuBufferAddRef(WGPUBuffer buffer) WGPU_FUNCTION_ATTRIBUTE;
    
    extern "c" fn wgpuBufferRelease(buffer: Buffer) void;
    pub fn release(buffer: Buffer) void {
        wgpuBufferRelease(buffer);
        log.info("Released Buffer", .{});
    }


};








const BufferMapCallBackInfo = extern struct { 
    nextInChain: ?*const ChainedStruct = null,
    mode: wgpu.CallBackMode,
    callback: BufferMapCallBack,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
};


const MapUserData1 = extern struct {
    status: wgpu.MapAsyncStatus = .Unknown
};

const BufferMapCallBack = *const fn(
    status: wgpu.MapAsyncStatus,
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque
) callconv(.C) void;

/// Implementation of BufferMapCallBack
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

