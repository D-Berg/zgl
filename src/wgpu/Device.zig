const std = @import("std");
const log = std.log.scoped(.@"wgpu/device");
const wgpu = @import("wgpu.zig");
const Allocator = std.mem.Allocator;

const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const FeatureName = wgpu.FeatureName;
const RequiredLimits = wgpu.RequiredLimits;
const Queue = wgpu.Queue;
const UncapturedErrorCallbackInfo = wgpu.UncapturedErrorCallbackInfo;
const Limits = wgpu.Limits;
const CommandEncoder = wgpu.CommandEncoder;
const CommandEncoderImpl = CommandEncoder.CommandEncoderImpl;
const ShaderModule = wgpu.ShaderModule;
const ShaderModuleImpl = ShaderModule.ShaderModuleImpl;
const RenderPipeline = wgpu.RenderPipeline;
const RenderPipelineImpl = RenderPipeline.RenderPipelineImpl;
const Buffer = wgpu.Buffer;
const BufferImpl = Buffer.BufferImpl;
const ComputePipeline = wgpu.ComputePipeline;

const Device = @This();
///Used for calling c API
pub const DeviceImpl = *opaque {};

_inner: DeviceImpl,


extern "c" fn wgpuDeviceRelease(device: DeviceImpl) void;
pub fn Release(device: Device) void {
    wgpuDeviceRelease(device._inner);
    log.info("Released device", .{});
}

pub const Descriptor = struct {
    nextInChain: ?*const ChainedStruct = null,
    label: wgpu.StringView = .{ .data = "", .length = 0},
    requiredFeatureCount: usize = 0,
    requiredFeatures: ?[*]const FeatureName = null,
    requiredLimits: ?*const RequiredLimits = null,
    defaultQueue: Queue.Descriptor = .{
        .label = .{ .data = "", .length = 0},
        .nextInChain = null
    },
    deviceLostCallback: ?*const LostCallback = null,
    deviceLostUserdata: ?*anyopaque = null,
    uncapturedErrorCallbackInfo: ?UncapturedErrorCallbackInfo = null
};

pub const LostCallback = fn(
    reason: LostReason, 
    message: [*c]const u8,
    userdata: ?*anyopaque
) callconv(.C) void;

pub const LostReason = enum(u32) {
    Unknown = 0x00000001,
    Destroyed = 0x00000002,
    Force32 = 0x7FFFFFFF
};

pub const UserData = struct {
    deviceImpl: ?DeviceImpl = null,
    requestEnded: bool = false,        
};



extern fn wgpuDeviceGetFeatures(device: DeviceImpl, features: *wgpu.SupportedFeatures) void;
/// Members neeed to be freed by calling deinit
pub fn GetFeatures(device: Device) wgpu.SupportedFeatures {
    
    var sup_features = wgpu.SupportedFeatures{.features = undefined, .featureCount = undefined};

    wgpuDeviceGetFeatures(device._inner, &sup_features);

    return sup_features;
}


pub const SupportedLimits = extern struct {
    nextInChain: ?*const ChainedStructOut = null,
    limits: Limits,

    pub fn logLimits(slimits: *const SupportedLimits) void {

        const limits = slimits.limits;

        log.info("Device Limits:", .{});
        log.info(" - maxTextureDimension1D: {}", .{limits.maxTextureDimension1D});
        log.info(" - maxTextureDimension2D: {}", .{limits.maxTextureDimension2D});
        log.info(" - maxTextureDimension3D: {}", .{limits.maxTextureDimension3D});
        log.info(" - maxTextureArrayLayers: {}", .{limits.maxTextureArrayLayers});

    }
};

extern "c" fn wgpuDeviceGetLimits(device: DeviceImpl, limits: *SupportedLimits) u32;
pub fn GetLimits(device: Device) !SupportedLimits {

    var limits = SupportedLimits { .limits = .{} };
    const success = wgpuDeviceGetLimits(device._inner, &limits);

    if (success != 0) return limits else return error.FailedToGetDeviceLimits;
    
}

extern "c" fn wgpuDeviceGetQueue(device: DeviceImpl) ?*Queue;
pub fn GetQueue(device: Device) WGPUError!*Queue {
    const maybe_queue = wgpuDeviceGetQueue(device._inner);

    if (maybe_queue) |queue| {
        log.info("Got Queue: {}", .{queue});
        return queue;
    } else {
        return error.FailedToGetQueue;
    }

}


extern "c" fn wgpuDeviceCreateCommandEncoder(device: DeviceImpl, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoderImpl;

// TODO: handle if wgpuDeviceCreateCommandEncoder returns null
pub fn CreateCommandEncoder(device: Device, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder {

    const ce_inner = wgpuDeviceCreateCommandEncoder(device._inner, descriptor);

    // log.debug("Created CommandEncoder: {}", .{ce_inner});
    
    return CommandEncoder{ ._inner = ce_inner };

}

extern "c" fn wgpuDevicePoll(device: DeviceImpl, wait: u32, wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex) u32;
/// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
pub fn Poll(device: Device, wait: bool, wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex) bool {
    const res = wgpuDevicePoll(device._inner, @intFromBool(wait), wrappedSubmissionIndex);
    if (res == 0) return false else return true;
}

extern "c" fn wgpuDeviceCreateShaderModule(device: DeviceImpl, descriptor: *const ShaderModule.Descriptor) ?ShaderModuleImpl;
pub fn CreateShaderModule(device: Device, descriptor: *const ShaderModule.Descriptor) WGPUError!ShaderModule {
    const maybe_impl = wgpuDeviceCreateShaderModule(device._inner, descriptor);

    if (maybe_impl) |impl| return ShaderModule{ ._impl = impl } else return error.FailedToCreateShaderModule;
}

extern "c" fn wgpuDeviceCreateRenderPipeline(device: DeviceImpl, descriptor: *const RenderPipeline.Descriptor) ?RenderPipelineImpl;
pub fn CreateRenderPipeline(device: Device, descriptor: *const RenderPipeline.Descriptor) WGPUError!RenderPipeline {

    const maybe_impl = wgpuDeviceCreateRenderPipeline(device._inner, descriptor);

    if (maybe_impl) |impl| return RenderPipeline{ ._impl = impl } else return error.FailedToCreateRenderPipeline;

}

extern "c" fn wgpuDeviceCreateComputePipeline(
    device: DeviceImpl,
    descriptor: *const ComputePipeline.Descriptor
) ?*ComputePipeline;

pub fn CreateComputePipeline(
    device: Device,
    descriptor: *const ComputePipeline.Descriptor
) WGPUError!*ComputePipeline {
    const maybe_compute_pipeline = wgpuDeviceCreateComputePipeline(
        device._inner, descriptor
    );

    if (maybe_compute_pipeline) |compute_pipeline| {
        return compute_pipeline;
    } else {
        return WGPUError.FailedToCreateComputePipeline;
    }
}

extern "c" fn wgpuDeviceCreateBuffer(
    device: DeviceImpl, 
    descriptor: *const Buffer.Descriptor
) ?BufferImpl;

pub fn CreateBuffer(
    device: Device, 
    descriptor: *const Buffer.Descriptor
) WGPUError!Buffer {

    const maybe_impl = wgpuDeviceCreateBuffer(device._inner, descriptor);

    if (maybe_impl) |impl| {
        return Buffer { ._impl = impl };
    } else {
        return WGPUError.FailedToCreateBuffer;
    }

}

