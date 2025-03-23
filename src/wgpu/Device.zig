const std = @import("std");
const log = std.log.scoped(.@"wgpu/device");
const wgpu = @import("wgpu.zig");

const c = @import("../zgl.zig").c;

const Allocator = std.mem.Allocator;

const WGPUError = wgpu.WGPUError;
const ChainedStruct = wgpu.ChainedStruct;
const ChainedStructOut = wgpu.ChainedStructOut;
const ComputePipelineDescriptor = wgpu.ComputePipelineDescriptor;
const FeatureName = wgpu.FeatureName;
const RequiredLimits = wgpu.RequiredLimits;
const Queue = wgpu.Queue;
const UncapturedErrorCallbackInfo = wgpu.UncapturedErrorCallbackInfo;
const Limits = wgpu.Limits;
const CommandEncoder = wgpu.CommandEncoder;
const ShaderModule = wgpu.ShaderModule;
const ShaderModuleDescriptor = wgpu.ShaderModuleDescriptor;
const RenderPipeline = wgpu.RenderPipeline;
const RenderPipelineImpl = RenderPipeline.RenderPipelineImpl;
const Buffer = wgpu.Buffer;
const BufferDescriptor = wgpu.BufferDescriptor;
const ComputePipeline = wgpu.ComputePipeline;
const BindGroup = wgpu.BindGroup;
const BindGroupDescriptor = wgpu.BindGroupDescriptor;
const SupportedFeatures = wgpu.SupportedFeatures;
const RenderPipelineDescriptor = wgpu.RenderPipelineDescriptor;
const CommandEncoderDescriptor = wgpu.CommandEncoderDescriptor;
const Texture = wgpu.Texture;
const TextureDescriptor = wgpu.TextureDescriptor;

pub const Device = *DeviceImpl;

const DeviceImpl = opaque {
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

    
    extern "c" fn wgpuDeviceCreateCommandEncoder(device: Device, descriptor: ?*const CommandEncoderDescriptor) ?CommandEncoder;
    pub fn CreateCommandEncoder(device: Device, descriptor: ?*const CommandEncoderDescriptor) WGPUError!CommandEncoder {

        const maybe_command_encoder = wgpuDeviceCreateCommandEncoder(device, descriptor);
        
        if (maybe_command_encoder) |command_encoder| {

            return command_encoder;

        } else {
            return WGPUError.FailedToCreateCommandEncoder;
        }

        

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
        descriptor: *const ComputePipelineDescriptor
    ) ?ComputePipeline;

    pub fn CreateComputePipeline(
        device: Device,
        descriptor: *const ComputePipelineDescriptor
    ) WGPUError!ComputePipeline {

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

    
    extern "c" fn wgpuDeviceCreateBindGroup(device: Device, descriptor: *const BindGroupDescriptor) ?BindGroup;
    pub fn CreateBindGroup(device: Device, descriptor: *const BindGroupDescriptor) WGPUError!BindGroup {

        const maybe_bindgroup = wgpuDeviceCreateBindGroup(device, descriptor);

        if (maybe_bindgroup) |bindgroup| {
            log.info("Created BindGroup {s}", .{descriptor.label.toSlice()});
            return bindgroup;
        } else {
            log.err("Failed to create Bindgroup {s}", .{descriptor.label.toSlice()});
            return WGPUError.FailedToCreateBindGroup;
        }

    }

    extern "c" fn wgpuDeviceCreateTexture(device: Device, descriptor: *const TextureDescriptor.ExternalStruct) ?Texture;
    pub fn CreateTexture(device: Device, descriptor: *const TextureDescriptor) WGPUError!Texture {

        const maybe_texture = wgpuDeviceCreateTexture(device, &descriptor.External());

        if (maybe_texture) |texture| {
            return texture;
        } else {
            @panic("failed to create texture");
            
        }

        

    }

};

test "Create Texture" {
    const instance = try wgpu.CreateInstance(null);
    defer instance.release();

    const adapter = try instance.RequestAdapter(null);
    defer adapter.release();
    
    const device = try adapter.RequestDevice(null);
    defer device.release();

    const texture = try device.CreateTexture(&.{
        .label = .fromSlice("test texture"),
        .format = .RGBA8Snorm,
        .mip_level_count = 1,
        .view_formats = &.{},
        .sample_count = 1,
        .dimension = .@"2D",
        .size = .{ 
            .width = 400,
            .height = 200,
            .depth_or_array_layers = 1
        },
        .usages = .{
            .CopySrc = true,
            .TextureBinding = true,
        },
    });
    defer texture.release();

}
