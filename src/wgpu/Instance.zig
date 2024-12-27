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
};

extern "c" fn wgpuInstanceRequestAdapter(
    instance: InstanceImpl, 
    options: ?*const wgpu.RequestAdapterOptions, 
    callback: *const Instance.RequestAdapterCallback,
    userdata: ?*anyopaque
) void;
pub fn RequestAdapter(instance: Instance, options: ?*const wgpu.RequestAdapterOptions) WGPUError!Adapter {

    log.info("Requesting adapter...", .{});
    var user_data = Adapter.UserData{};

    // async
    wgpuInstanceRequestAdapter(instance._inner, options, &onAdapterRequestEnded, &user_data);


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

const RequestAdapterCallback = fn (
    status: wgpu.RequestAdapterStatus, 
    adapterImpl: ?AdapterImpl, 
    message: [*c]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void;


/// User implemention of RequestAdapterCallback
fn onAdapterRequestEnded(
    status: wgpu.RequestAdapterStatus, 
    adapterImpl: ?AdapterImpl, 
    message: [*c]const u8,
    userdata: ?*anyopaque,
) callconv(.C) void {

    var user_data = @as(*Adapter.UserData, @alignCast(@ptrCast(userdata)));

    switch (status) {
        .Success => {
            user_data.adapterImpl = adapterImpl;
        },
        inline else => |status_val| {

            log.err("Request adapter status: {s}, message: {s}", .{
                @tagName(status_val), message
            });

        }

    }

    user_data.requestEnded = true;

}

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
