const std = @import("std");
const log = std.log.scoped(.@"wgpu/instance");
const builtin = @import("builtin");

const wgpu = @import("wgpu.zig");
const Allocator = std.mem.Allocator;
const WGPUError = wgpu.WGPUError;
const Adapter = wgpu.Adapter;
const AdapterImpl = Adapter.AdapterImpl;
const Surface = wgpu.Surface;
const SurfaceImpl = Surface.SurfaceImpl;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterOptions = wgpu.RequestAdapterOptions;

const Instance = @This();
const InstanceImpl = *opaque {};

_inner: InstanceImpl,

extern "c" fn wgpuCreateInstance(desc: ?*const Instance.Descriptor) ?InstanceImpl;
pub fn Create(descriptor: ?*const Descriptor) WGPUError!Instance {
    
    log.info("Creating instance...", .{});
    
    const maybe_instance = wgpuCreateInstance(descriptor);

    if (maybe_instance) |instance| {
        log.info("Got instance: {}", .{instance});
        return Instance { ._inner = instance };
    } else {
        log.err("Failed to Create Instance", .{});
        return error.FailedToCreateInstance;
    }

}


extern "c" fn wgpuInstanceRelease(instance: InstanceImpl) void;
pub fn Release(instance: Instance) void {
    wgpuInstanceRelease(instance._inner);
    log.info("Released instance", .{});
}

pub const Descriptor = extern struct {
    nextInChain: ?*const wgpu.ChainedStruct = null,
    timedWaitAnyEnable: bool = false,
    timedWaitAnyMaxCount: usize = 0
};

extern "c" fn wgpuInstanceRequestAdapter(
    instance: InstanceImpl, 
    options: ?*const RequestAdapterOptions, 
    callbackInfo: RequestAdapterCallbackInfo,
) wgpu.Future;
pub fn RequestAdapter(instance: Instance, options: ?*const RequestAdapterOptions) WGPUError!Adapter {

    log.info("Requesting adapter...", .{});
    var user_data = Adapter.UserData{};

    // async
    _ = wgpuInstanceRequestAdapter(instance._inner, options, .{
        .nextInChain = null,
        .mode = .AllowProcessEvents,
        .callback = &onAdapterRequestEnded,
        .userdata1 = &user_data,
        .userdata2 = null,
    });

    if (builtin.target.os.tag == .emscripten) {
        while (!user_data.requestEnded) std.os.emscripten.emscripten_sleep(100);
    } else {
        if (!user_data.requestEnded) return error.FailedToRequestAdapter;
    }


    log.info("Request adapter ended", .{});

    if (user_data.adapterImpl) |adapter_impl| {
        log.info("Got adapter: {}", .{adapter_impl});
        return Adapter{ ._inner = adapter_impl };
    } else {
        log.err("adapter was null", .{});
        return error.FailedToRequestAdapter;
    }


}

pub const RequestAdapterCallback = fn (
    status: wgpu.RequestAdapterStatus, 
    adapterImpl: ?AdapterImpl, 
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
) callconv(.C) void;


/// User implemention of RequestAdapterCallback
fn onAdapterRequestEnded(
    status: wgpu.RequestAdapterStatus, 
    adapterImpl: ?AdapterImpl, 
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
) callconv(.C) void {

    _ = userdata2;

    var user_data = @as(*Adapter.UserData, @alignCast(@ptrCast(userdata1)));

    switch (status) {
        .Success => {
            user_data.adapterImpl = adapterImpl;
        },
        inline else => |status_val| {

            log.err("Request adapter status: {s}, message: {s}", .{
                @tagName(status_val), message.toSlice()
            });

        }

    }

    user_data.requestEnded = true;

}


const RequestAdapterCallbackInfo = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    mode: wgpu.CallBackMode,
    callback: ?*const Instance.RequestAdapterCallback,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
};


pub const EnumerateAdapterOptions = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    backends: wgpu.BackendType // TODO: check if its the same as in wgpu.h
};
/// Defined wgpu.h
extern "c" fn wgpuInstanceEnumerateAdapters(
    instance: InstanceImpl, 
    options: ?*const EnumerateAdapterOptions, 
    adapters: ?[*]AdapterImpl
) usize;

/// Result must be freed by caller.
pub fn EnumerateAdapters(instance: Instance, allocator: Allocator) ![]const Adapter {

    const adapter_count = wgpuInstanceEnumerateAdapters(instance._inner, null, null);

    const adapters_impl = try allocator.alloc(AdapterImpl, adapter_count);
    defer allocator.free(adapters_impl);

    _ = wgpuInstanceEnumerateAdapters(instance._inner, null, adapters_impl.ptr);

    const adapters = try allocator.alloc(Adapter, adapter_count);

    for (adapters_impl, 0..) |impl, i| {
        adapters[i] = Adapter { ._inner = impl };
    }

    return adapters;
}

extern "c" fn wgpuInstanceCreateSurface(instance: InstanceImpl, descriptor: *const Surface.Descriptor) ?SurfaceImpl;
pub fn CreateSurface(instance: Instance, descriptor: *const Surface.Descriptor) WGPUError!Surface {

    const maybe_inner = wgpuInstanceCreateSurface(instance._inner, descriptor);

    if (maybe_inner) |inner| {
        log.info("Got surface: {}", .{inner} );
        return Surface { ._inner = inner };
    } else {
        return error.FailedToCreateSurface;
    }

}
