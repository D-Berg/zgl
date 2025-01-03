const std = @import("std");
const builting = @import("builtin");
const log = std.log.scoped(.@"wgpu/adapter");
const Allocator = std.mem.Allocator;

const emscripten = std.os.emscripten;

const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const Device = wgpu.Device;
const DeviceImpl = Device.DeviceImpl;
const FeatureName = wgpu.FeatureName;
const BackendType = wgpu.BackendType;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const Limits = wgpu.Limits;

const Adapter = @This();
pub const AdapterImpl = *opaque {};

_inner: AdapterImpl,

pub const UserData = struct {
    adapterImpl: ?AdapterImpl  = null,
    requestEnded: bool = false,
};

extern "c" fn wgpuAdapterRelease(adapter: AdapterImpl) void;
pub fn Release(adapter: Adapter) void {
    wgpuAdapterRelease(adapter._inner);
    log.info("Released adapter", .{});
}


extern "c" fn wgpuAdapterRequestDevice(
    adapter: AdapterImpl, 
    descriptor: ?*const Device.Descriptor, 
    callbackInfo: RequestDeviceCallbackInfo
) wgpu.Future;
pub fn RequestDevice(adapter: Adapter, descriptor: ?*const Device.Descriptor) WGPUError!Device {
    
    log.info("Requesting device...", .{});

    var userdata = Device.UserData{};

    _ = wgpuAdapterRequestDevice(adapter._inner, descriptor, RequestDeviceCallbackInfo{
        .nextInChain = null,
        .mode = .WaitAnyOnly,
        .callback = &onDeviceRequestEnded,
        .userdata1 = &userdata,
        .userdata2 = null,
    });

    if (builting.target.os.tag == .emscripten) {
        while (!userdata.requestEnded) emscripten.emscripten_sleep(100);
    } else {
        if (!userdata.requestEnded) return error.FailedToRequestDevice;
    }

    if (userdata.deviceImpl) |dev_impl| {
        log.info("Got device: {}", .{dev_impl});
        return Device{ ._inner = dev_impl };
    } else {
        log.err("device was null", .{});
        return error.FailedToRequestDevice;
    }

}

const RequestDeviceCallback = fn(
    status: RequestDeviceStatus,
    deviceImpl: ?DeviceImpl,
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
) callconv(.C) void;

/// My user implementation of RequestDeviceCallback, not part of webgpu.h
fn onDeviceRequestEnded(
    status: RequestDeviceStatus, 
    deviceImpl: ?DeviceImpl, 
    message: wgpu.StringView,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque
) callconv(.C) void {

    _ = userdata2;

    var user_data = @as(*Device.UserData, @alignCast(@ptrCast(userdata1)));

    switch (status) {
        .Success => {
            user_data.deviceImpl = deviceImpl;
        }, 

        inline else => |case| {
            log.err("Could not get WebGPU device, status: {s}, message: {s}", .{@tagName(case), message.toSlice()});
        }

    }

    user_data.requestEnded = true;
}

const RequestDeviceCallbackInfo = extern struct {
    nextInChain: ?*const ChainedStruct,
    mode: wgpu.CallBackMode,
    callback: *const RequestDeviceCallback,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
};

extern fn wgpuAdapterGetLimits(adapter: AdapterImpl, limits: *SupportedLimits) u32;
pub fn GetLimits(adapter: Adapter) ?SupportedLimits {

    var limits = SupportedLimits{ .limits = .{} };
    
    const success = wgpuAdapterGetLimits(adapter._inner, &limits);
    if (success == 0) return null else return limits;
}


extern fn wgpuAdapterGetFeatures(adapter: AdapterImpl, features: *wgpu.SupportedFeatures) void;
pub fn GetFeatures(adapter: Adapter) wgpu.SupportedFeatures {
    var sup_features = wgpu.SupportedFeatures {
        .featureCount = 0,
        .features = undefined,
    };

    wgpuAdapterGetFeatures(adapter._inner, &sup_features);
    
    return sup_features;
}

const AdapterType = enum(u32) {
    DiscreteGPU = 0x00000001,
    IntegratedGPU = 0x00000002,
    CPU = 0x00000003,
    Unknown = 0x00000004,
    Force32 = 0x7FFFFFFF
};

const RequestDeviceStatus = enum(u32)  {
    Success = 0x00000001,
    InstanceDropped = 0x00000002,
    Error = 0x00000003,
    Unknown = 0x00000004,
    Force32 = 0x7FFFFFFF
};



const Info = extern struct {
    nextInChain: ?*const wgpu.ChainedStructOut = null,
    vendor: wgpu.StringView = undefined,
    architecture: wgpu.StringView = undefined,
    device: wgpu.StringView = undefined,
    description: wgpu.StringView = undefined,
    backendType: BackendType = .Null,
    adapterType: AdapterType = .Unknown,
    vendorID: u32 = 0,
    deviceID: u32 = 0,

    extern "c" fn wgpuAdapterInfoFreeMembers(info: Info) void;
    pub fn deinit(self: Info) void {
        wgpuAdapterInfoFreeMembers(self);
    }

    pub fn format(self: *const Info, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, self);
        }

        try writer.print("Adapter info:\n", .{});
        try writer.print("  - vendor: {s}\n", .{self.vendor.toSlice()});
        try writer.print("  - architecture: {s}\n", .{self.architecture.toSlice()});
        try writer.print("  - device: {s}\n", .{self.device.toSlice()});
        try writer.print("  - description: {s}\n", .{self.description.toSlice()});
        try writer.print("  - backendType: {s}\n", .{@tagName(self.backendType)});
        try writer.print("  - adapterType: {s}\n", .{@tagName(self.adapterType)});
        try writer.print("  - vendorID: {}\n", .{self.vendorID});
        try writer.print("  - deviceID: {}\n", .{self.deviceID});
    }

};

extern fn wgpuAdapterGetInfo(adapter: AdapterImpl, info: *Info) void;
pub fn GetInfo(adapter: Adapter) Info {

    var info = Info{};

    wgpuAdapterGetInfo(adapter._inner, &info);

    return info;
}
        

pub const SupportedLimits = extern struct {
    nextInChain: ?*const ChainedStructOut = null,
    limits: Limits,

    pub fn logLimits(slimits: *const SupportedLimits) void {

        const limits = slimits.limits;

        log.info("Adapter Limits:", .{});
        log.info(" - maxTextureDimension1D: {}", .{limits.maxTextureDimension1D});
        log.info(" - maxTextureDimension2D: {}", .{limits.maxTextureDimension2D});
        log.info(" - maxTextureDimension3D: {}", .{limits.maxTextureDimension3D});
        log.info(" - maxTextureArrayLayers: {}", .{limits.maxTextureArrayLayers});

    }
};



const SupportedAdapterFeatures = struct {
    allocator: std.mem.Allocator,
    features: []FeatureName,

    pub fn deinit(sfeatures: *const SupportedAdapterFeatures) void {
        sfeatures.allocator.free(sfeatures.features);
    }

    pub fn logFeautures(sfeatures: *const SupportedAdapterFeatures) void {

        log.info("Supported Adapter Features:", .{});
        for (sfeatures.features) |feature| {
            log.info(" - {s}", .{@tagName(feature)});
        }
    }
    
};
