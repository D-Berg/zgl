const std = @import("std");
const builting = @import("builtin");
const log = std.log.scoped(.@"wgpu/adapter");
const Allocator = std.mem.Allocator;

const emscripten = std.os.emscripten;

const wgpu = @import("wgpu.zig");
const WGPUError = wgpu.WGPUError;
const Device = wgpu.Device;
const DeviceDescriptor = wgpu.DeviceDescriptor;
const FeatureName = wgpu.FeatureName;
const BackendType = wgpu.BackendType;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const Limits = wgpu.Limits;


pub const Adapter = *AdapterImpl;
const AdapterImpl = opaque {

    extern "c" fn wgpuAdapterRelease(adapter: Adapter) void;
    pub fn release(adapter: Adapter) void {
        wgpuAdapterRelease(adapter);
        log.info("Released adapter", .{});
    }

    const DeviceUserData = struct {
        device: ?Device = null,
        requestEnded: bool = false,        
    };

    
    // TODO: move to wgpu
    const RequestDeviceCallback = fn(
        status: RequestDeviceStatus,
        device: ?Device,
        message: wgpu.StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    ) callconv(.C) void;

    extern "c" fn wgpuAdapterRequestDevice(
        adapter: Adapter, 
        descriptor: ?*const DeviceDescriptor, 
        callbackInfo: RequestDeviceCallbackInfo
    ) wgpu.Future;
    pub fn RequestDevice(adapter: Adapter, descriptor: ?*const DeviceDescriptor) WGPUError!Device {
        
        log.info("Requesting device...", .{});

        var userdata = DeviceUserData{};

        _ = wgpuAdapterRequestDevice(adapter, descriptor, RequestDeviceCallbackInfo{
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

        if (userdata.device) |device| {
            log.info("Got device: {}", .{device});
            return device;
        } else {
            log.err("device was null", .{});
            return error.FailedToRequestDevice;
        }

    }

    // TODO: move to wgpu
    const RequestDeviceCallbackInfo = extern struct {
        nextInChain: ?*const ChainedStruct,
        mode: wgpu.CallBackMode,
        callback: *const RequestDeviceCallback,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque,
    };


    
    /// My user implementation of RequestDeviceCallback, not part of webgpu.h
    fn onDeviceRequestEnded(
        status: RequestDeviceStatus, 
        device: ?Device, 
        message: wgpu.StringView,
        userdata1: ?*anyopaque,
        userdata2: ?*anyopaque
    ) callconv(.C) void {

        _ = userdata2;

        var user_data = @as(*DeviceUserData, @alignCast(@ptrCast(userdata1)));

        switch (status) {
            .Success => {
                user_data.device = device;
            }, 

            inline else => |case| {
                log.err("Could not get WebGPU device, status: {s}, message: {s}", .{@tagName(case), message.toSlice()});
            }

        }

        user_data.requestEnded = true;

    }

    extern fn wgpuAdapterGetLimits(adapter: Adapter, limits: *Limits) wgpu.Status;
    /// Get the Supported Limits of the Adapter
    pub fn GetLimits(adapter: Adapter) ?Limits {

        var limits: Limits = .{};
        
        const status = wgpuAdapterGetLimits(adapter, &limits);

        switch (status) {
            .Success => {
                return limits;
            },
            inline else => |s| {
                log.err("Failed to get Adapter limits, got WGPUStatys: {s}", .{@tagName(s)});
                return null;
            }
        }
    }

    
    extern fn wgpuAdapterGetFeatures(adapter: Adapter, features: *wgpu.SupportedFeatures) void;

    // TODO: return a slice of features
    pub fn GetFeatures(adapter: Adapter) wgpu.SupportedFeatures {
        var sup_features = wgpu.SupportedFeatures {
            .featureCount = 0,
            .features = null,
        };

        wgpuAdapterGetFeatures(adapter, &sup_features);
        
        return sup_features;
    }

    // TODO: move to wgpu
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
    
    
    /// wgpuAdapterInfo
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

            // TODO: do type reflection maybe
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


    extern fn wgpuAdapterGetInfo(adapter: Adapter, info: *Info) void;
    pub fn GetInfo(adapter: Adapter) Info {

        var info = Info{};

        wgpuAdapterGetInfo(adapter, &info);

        return info;
    }


    
    // FIX:
    pub const SupportedLimits = extern struct {
        limits: Limits,

        pub fn logLimits(slimits: *const Limits) void {

            const limits = slimits.limits;

            inline for (@typeInfo(@TypeOf(limits)).@"struct".fields) |field|{
                log.info(" - {s}: {}", .{field.name, @field(limits, field.name)});
            }

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

};
