const std = @import("std");
const log = std.log.scoped(.@"wgpu/device");
const wgpu = @import("wgpu.zig");

const c = @import("../zgl.zig").c;

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
const ShaderModuleDescriptor = wgpu.ShaderModuleDescriptor;
const RenderPipeline = wgpu.RenderPipeline;
const RenderPipelineImpl = RenderPipeline.RenderPipelineImpl;
const Buffer = wgpu.Buffer;
const BufferDescriptor = wgpu.BufferDescriptor;
const ComputePipeline = wgpu.ComputePipeline;
const BindGroup = wgpu.BindGroup;
const SupportedFeatures = wgpu.SupportedFeatures;
const RenderPipelineDescriptor = wgpu.RenderPipelineDescriptor;

pub const Device= *opaque {
    extern "c" fn wgpuDeviceRelease(device: Device) void;
    pub fn release(device: Device) void {
        wgpuDeviceRelease(device);
        log.info("Released device", .{});
    }

    
    extern fn wgpuDeviceGetFeatures(device: Device, features: *SupportedFeatures) void;
    /// Members neeed to be freed by calling deinit
    pub fn GetFeatures(device: Device) wgpu.SupportedFeatures {
        
        var sup_features: SupportedFeatures = undefined;

        wgpuDeviceGetFeatures(device, &sup_features);

        return sup_features;
    }

    
    extern "c" fn wgpuDeviceGetLimits(device: Device, limits: *Limits) wgpu.Status;
    pub fn GetLimits(device: Device) !Limits {

        var limits: Limits = .{};
        const status = wgpuDeviceGetLimits(device, &limits);

        if (status == .Success) return limits else return error.FailedToGetDeviceLimits;
    }

    
    extern "c" fn wgpuDeviceGetQueue(device: Device) ?Queue;
    pub fn GetQueue(device: Device) WGPUError!Queue {
        const maybe_queue = wgpuDeviceGetQueue(device);

        if (maybe_queue) |queue| {
            log.info("Got Queue: {}", .{queue});
            return queue;
        } else {
            return error.FailedToGetQueue;
        }

    }

    
    extern "c" fn wgpuDeviceCreateCommandEncoder(device: Device, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoderImpl;
    // TODO: handle if wgpuDeviceCreateCommandEncoder returns null
    pub fn CreateCommandEncoder(device: Device, descriptor: ?*const CommandEncoder.Descriptor) CommandEncoder {

        const ce_inner = wgpuDeviceCreateCommandEncoder(device, descriptor);

        // log.debug("Created CommandEncoder: {}", .{ce_inner});
        
        return CommandEncoder{ ._inner = ce_inner };

    }


    extern "c" fn wgpuDevicePoll(device: Device, wait: u32, wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex) u32;
    /// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
    pub fn poll(device: Device, wait: bool, wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex) bool {
        const res = wgpuDevicePoll(device, @intFromBool(wait), wrappedSubmissionIndex);
        if (res == 0) return false else return true;
    }


    extern "c" fn wgpuDeviceCreateShaderModule(device: Device, descriptor: *const ShaderModuleDescriptor) ?ShaderModule;
    pub fn CreateShaderModule(device: Device, descriptor: *const ShaderModuleDescriptor) WGPUError!ShaderModule {
        const maybe_sm = wgpuDeviceCreateShaderModule(device, descriptor);

        if (maybe_sm) |shader_mod| {
            return shader_mod; 
        } else {
            return error.FailedToCreateShaderModule;
        }
    }

    
    // extern "c" fn wgpuDeviceCreateRenderPipeline(device: Device, descriptor: *const RenderPipeline.Descriptor) ?RenderPipelineImpl;
    pub fn CreateRenderPipeline(device: Device, descriptor: *const RenderPipelineDescriptor) WGPUError!RenderPipeline {

        const maybe_render_pipeline = c.wgpuDeviceCreateRenderPipeline(@ptrCast(device), &descriptor.ToExtern());

        if (maybe_render_pipeline) |render_pipeline| {
            log.info("Created RenderPipeline {}", .{render_pipeline});
            return @ptrCast(render_pipeline);
        } else {
            log.err("Failed to create RenderPipeline: got null", .{});
            return error.FailedToCreateRenderPipeline;
        }
    }

    
    extern "c" fn wgpuDeviceCreateComputePipeline(
        device: Device,
        descriptor: *const ComputePipeline.Descriptor
    ) ?ComputePipeline;

    pub fn CreateComputePipeline(
        device: Device,
        descriptor: *const ComputePipeline.Descriptor
    ) WGPUError!*ComputePipeline {
        const maybe_compute_pipeline = wgpuDeviceCreateComputePipeline(
            device, descriptor
        );

        if (maybe_compute_pipeline) |compute_pipeline| {
            log.info("Created ComputePipeline {}", .{compute_pipeline});
            return compute_pipeline;
        } else {
            return WGPUError.FailedToCreateComputePipeline;
        }
    }


    extern "c" fn wgpuDeviceCreateBuffer(
        device: Device, 
        descriptor: *const BufferDescriptor
    ) ?Buffer;

    pub fn CreateBuffer(
        device: Device, 
        descriptor: *const BufferDescriptor
    ) WGPUError!Buffer {

        const maybe_buffer = wgpuDeviceCreateBuffer(device, descriptor);

        if (maybe_buffer) |buffer| {
            log.info("Created Buffer {s}", .{descriptor.label.toSlice()});
            return buffer;
        } else {
            return WGPUError.FailedToCreateBuffer;
        }

    }

    
    extern "c" fn wgpuDeviceCreateBindGroup(device: Device, descriptor: *const BindGroup.Descriptor) ?BindGroup;
    pub fn CreateBindGroup(device: Device, descriptor: *const BindGroup.Descriptor) WGPUError!BindGroup {

        const maybe_bindgroup = wgpuDeviceCreateBindGroup(device, descriptor);

        if (maybe_bindgroup) |bindgroup| {
            log.info("Created BindGroup {s}", .{descriptor.label.toSlice()});
            return bindgroup;
        } else {
            log.err("Failed to create Bindgroup {s}", .{descriptor.label.toSlice()});
            return WGPUError.FailedToCreateBindGroup;
        }

    }

};

