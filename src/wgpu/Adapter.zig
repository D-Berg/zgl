const std = @import("std");
const log = std.log.scoped(.@"wgpu/adapter");
const Allocator = std.mem.Allocator;


const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const Device = wgpu.Device;
const DeviceImpl = Device.DeviceImpl;
const FeatureName = wgpu.FeatureName;
const BackendType = wgpu.BackendType;
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
    callback: *const RequestDeviceCallback, 
    userdata: ?*anyopaque
) void;
pub fn RequestDevice(adapter: Adapter, descriptor: ?*const Device.Descriptor) WGPUError!Device {
    
    log.info("Requesting device...", .{});

    var userdata = Device.UserData{};

    wgpuAdapterRequestDevice(adapter._inner, descriptor, &onDeviceRequestEnded, &userdata);

    if (!userdata.requestEnded) return error.FailedToRequestDevice;

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
    message: [*c]const u8,
    userdata: ?*anyopaque
) callconv(.C) void;

/// My user implementation of RequestDeviceCallback, not part of webgpu.h
fn onDeviceRequestEnded(
    status: RequestDeviceStatus, 
    deviceImpl: ?DeviceImpl, 
    message: [*c]const u8,
    user_data_any: ?*anyopaque
) callconv(.C) void {

    var user_data = @as(*Device.UserData, @alignCast(@ptrCast(user_data_any)));

    switch (status) {
        .Success => {
            user_data.deviceImpl = deviceImpl;
        }, 

        inline else => |case| {
            
            log.err("Could not get WebGPU device, status: {s}, message: {s}", .{@tagName(case), message});

        }

    }

    user_data.requestEnded = true;
}

extern fn wgpuAdapterGetLimits(adapter: AdapterImpl, limits: *SupportedLimits) u32;
pub fn GetLimits(adapter: Adapter) ?SupportedLimits {

    var limits = SupportedLimits{ .limits = .{} };
    
    const success = wgpuAdapterGetLimits(adapter._inner, &limits);
    if (success == 0) return null else return limits;
}


extern fn wgpuAdapterEnumerateFeatures(adapter: AdapterImpl, features: [*c]FeatureName) usize;
pub fn GetFeatures(adapter: Adapter, allocator: Allocator) !SupportedAdapterFeatures {

    const featureCount = wgpuAdapterEnumerateFeatures(adapter._inner, null);
    
    const features = try allocator.alloc(FeatureName, featureCount);
    
    _ = wgpuAdapterEnumerateFeatures(adapter._inner, @ptrCast(features));

    return SupportedAdapterFeatures{ .allocator = allocator, .features = features };

}

const AdapterType = enum(u32) {
    DiscreteGPU = 0x00000000,
    IntegratedGPU = 0x00000001,
    CPU = 0x00000002,
    Unknown = 0x00000003,
    Force32 = 0x7FFFFFFF
};

const RequestDeviceStatus = enum(u32)  {
    Success = 0x00000000,
    Error = 0x00000001,
    Unknown = 0x00000002,
    Force32 = 0x7FFFFFFF
};



const Info = extern struct {
    nextInChain: ?*const wgpu.ChainedStructOut = null,
    vendor: [*c]const u8 = "",
    architecture: [*c]const u8 = "",
    device: [*c]const u8 = "",
    description: [*c]const u8 = "",
    backendType: BackendType = .Null,
    adapterType: AdapterType = .Unknown,
    vendorID: u32 = 0,
    deviceID: u32 = 0,

    pub fn logInfo(info: Info) void {
        log.info("Adapter info:", .{});
        log.info(" - vendor: {s}", .{info.vendor});
        log.info(" - architecture: {s}", .{info.architecture});
        log.info(" - device: {s}", .{info.device});
        log.info(" - description: {s}", .{info.description});
        log.info(" - backendType: {s}", .{@tagName(info.backendType)});
        log.info(" - adapterType: {s}", .{@tagName(info.adapterType)});
        log.info(" - vendorID: {}", .{info.vendorID});
        log.info(" - deviceID: {}", .{info.deviceID});

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
