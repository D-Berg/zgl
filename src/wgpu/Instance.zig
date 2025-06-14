const std = @import("std");
const log = std.log.scoped(.@"wgpu/instance");
const builtin = @import("builtin");

const wgpu = @import("wgpu.zig");
const Allocator = std.mem.Allocator;
const WGPUError = wgpu.WGPUError;
const Adapter = wgpu.Adapter;
const Surface = wgpu.Surface;
const SurfaceDescriptor = wgpu.SurfaceDescriptor;
const ChainedStruct = wgpu.ChainedStruct;
const RequestAdapterOptions = wgpu.RequestAdapterOptions;

pub const Instance = opaque {
    extern "c" fn wgpuInstanceRelease(instance: ?*const Instance) void;
    pub fn release(instance: *const Instance) void {
        wgpuInstanceRelease(instance);
        log.info("Released instance", .{});
    }

    const AdapterUserData = struct {
        adapter: ?*const Adapter = null,
        requestEnded: bool = false,
    };

    extern "c" fn wgpuInstanceRequestAdapter(
        instance: ?*const Instance,
        options: ?*const RequestAdapterOptions,
        callbackInfo: RequestAdapterCallbackInfo,
    ) wgpu.Future;

    pub fn requestAdapter(
        instance: *const Instance,
        options: ?*const RequestAdapterOptions,
    ) WGPUError!*const Adapter {
        log.info("Requesting adapter...", .{});
        var user_data = AdapterUserData{};

        // async
        _ = wgpuInstanceRequestAdapter(instance, options, .{
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

        if (user_data.adapter) |adapter| {
            log.info("Got adapter: {}", .{adapter});
            return adapter;
        } else {
            log.err("adapter was null", .{});
            return error.FailedToRequestAdapter;
        }
    }

    // TODO: Move to wgpu
    pub const RequestAdapterCallback = fn (
        status: wgpu.RequestAdapterStatus,
        adapter: ?*const Adapter,
        message: wgpu.StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.C) void;

    /// User implemention of RequestAdapterCallback
    fn onAdapterRequestEnded(
        status: wgpu.RequestAdapterStatus,
        adapter: ?*const Adapter,
        message: wgpu.StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.C) void {
        _ = userdata2;

        var user_data = @as(*AdapterUserData, @alignCast(@ptrCast(userdata1)));

        switch (status) {
            .Success => {
                user_data.adapter = adapter;
            },
            inline else => |status_val| {
                log.err("Request adapter status: {s}, message: {s}", .{ @tagName(status_val), message.toSlice() });
            },
        }

        user_data.requestEnded = true;
    }

    // TODO: Move to wgpu
    const RequestAdapterCallbackInfo = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        mode: wgpu.CallBackMode,
        callback: ?*const RequestAdapterCallback,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    };

    pub const EnumerateAdapterOptions = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        backends: wgpu.BackendType, // TODO: check if its the same as in wgpu.h
    };
    /// Defined in wgpu.h
    extern "c" fn wgpuInstanceEnumerateAdapters(
        instance: Instance,
        options: ?*const EnumerateAdapterOptions,
        adapters: ?[*]Adapter,
    ) usize;

    /// Result must be freed by caller.
    pub fn enumerateAdapters(instance: *const Instance, gpa: Allocator) ![]const Adapter {
        const adapter_count = wgpuInstanceEnumerateAdapters(instance, null, null);

        const adapters = try gpa.alloc(Adapter, adapter_count);

        _ = wgpuInstanceEnumerateAdapters(instance, null, adapters.ptr);

        return adapters;
    }

    extern "c" fn wgpuInstanceCreateSurface(
        instance: ?*const Instance,
        descriptor: *const SurfaceDescriptor,
    ) ?*const Surface;

    pub fn createSurface(
        instance: *const Instance,
        descriptor: *const SurfaceDescriptor,
    ) WGPUError!*const Surface {
        const maybe_surface = wgpuInstanceCreateSurface(instance, descriptor);

        if (maybe_surface) |surface| {
            log.info("Got surface: {}", .{surface});
            return surface;
        } else {
            return error.FailedToCreateSurface;
        }
    }
};
