const std = @import("std");
const log = std.log.scoped(.@"wgpu/device");
const wgpu = @import("wgpu.zig");

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
const SupportedFeatures = wgpu.SupportedFeatures;
const CommandEncoderDescriptor = wgpu.CommandEncoderDescriptor;
const Texture = wgpu.Texture;
const TextureDescriptor = wgpu.TextureDescriptor;

pub const Device = opaque {
    extern "c" fn wgpuDeviceRelease(device: ?*const Device) void;
    pub fn release(device: *const Device) void {
        wgpuDeviceRelease(device);
        log.info("Released device", .{});
    }

    extern fn wgpuDeviceGetFeatures(device: ?*const Device, features: *SupportedFeatures) void;
    /// Members neeed to be freed by calling `freeMembers`.
    pub fn getFeatures(device: *const Device) wgpu.SupportedFeatures {
        var sup_features: SupportedFeatures = undefined;

        wgpuDeviceGetFeatures(device, &sup_features);

        return sup_features;
    }

    extern "c" fn wgpuDeviceGetLimits(device: ?*const Device, limits: *Limits) wgpu.Status;
    pub fn getLimits(device: *const Device) !Limits {
        var limits: Limits = .{};
        const status = wgpuDeviceGetLimits(device, &limits);

        if (status == .Success) return limits else return error.FailedToGetDeviceLimits;
    }

    extern "c" fn wgpuDeviceGetQueue(device: ?*const Device) ?*const Queue;
    pub fn getQueue(device: *const Device) WGPUError!*const Queue {
        const maybe_queue = wgpuDeviceGetQueue(device);

        if (maybe_queue) |queue| {
            log.info("Got Queue: {}", .{queue});
            return queue;
        } else {
            return error.FailedToGetQueue;
        }
    }

    extern "c" fn wgpuDeviceCreateCommandEncoder(
        device: ?*const Device,
        descriptor: ?*const CommandEncoderDescriptor,
    ) ?*const CommandEncoder;
    pub fn createCommandEncoder(
        device: *const Device,
        descriptor: ?*const CommandEncoderDescriptor,
    ) WGPUError!*const CommandEncoder {
        const maybe_command_encoder = wgpuDeviceCreateCommandEncoder(device, descriptor);

        if (maybe_command_encoder) |command_encoder| {
            return command_encoder;
        } else {
            return WGPUError.FailedToCreateCommandEncoder;
        }
    }

    extern "c" fn wgpuDevicePoll(
        device: ?*const Device,
        wait: u32,
        wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex,
    ) u32;
    /// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
    pub fn poll(
        device: *const Device,
        wait: bool,
        wrappedSubmissionIndex: ?*const wgpu.WrappedSubmissionIndex,
    ) bool {
        const res = wgpuDevicePoll(device, @intFromBool(wait), wrappedSubmissionIndex);
        if (res == 0) return false else return true;
    }

    extern "c" fn wgpuDeviceCreateShaderModule(
        device: ?*const Device,
        descriptor: *const ShaderModuleDescriptor,
    ) ?*const ShaderModule;
    pub fn createShaderModule(
        device: *const Device,
        descriptor: *const ShaderModuleDescriptor,
    ) WGPUError!*const ShaderModule {
        const maybe_sm = wgpuDeviceCreateShaderModule(device, descriptor);

        if (maybe_sm) |shader_mod| {
            return shader_mod;
        } else {
            return error.FailedToCreateShaderModule;
        }
    }

    extern "c" fn wgpuDeviceCreateRenderPipeline(
        device: ?*const Device,
        descriptor: *const wgpu.RenderPipeline.Descriptor.External,
    ) ?*const RenderPipeline;

    pub fn createRenderPipeline(
        device: *const Device,
        descriptor: wgpu.RenderPipeline.Descriptor,
    ) WGPUError!*const RenderPipeline {
        const extern_descriptor = wgpu.RenderPipeline.Descriptor.External{
            .next_in_chain = descriptor.next_in_chain,
            .label = .fromSlice(descriptor.label),
            .layout = descriptor.layout,
            .vertex = wgpu.VertexState.External{
                .next_in_chain = descriptor.vertex.next_in_chain,
                .module = descriptor.vertex.module,
                .entry_point = .fromSlice(descriptor.vertex.entry_point),
                .constant_count = descriptor.vertex.constants.len,
                .constants = if (descriptor.vertex.constants.len > 0)
                    descriptor.vertex.constants.ptr
                else
                    null,
                // .buffer_count = descriptor.vertex.buffers.len,
            },
            .primitive = descriptor.primitive,
            .depth_stencil = descriptor.depth_stencil,
            .multi_sample = descriptor.multi_sample,
            .fragment = descriptor.fragment,
        };
        const maybe_render_pipeline = wgpuDeviceCreateRenderPipeline(
            device,
            &extern_descriptor,
        );

        if (maybe_render_pipeline) |render_pipeline| {
            log.info("Created RenderPipeline {}", .{render_pipeline});
            return @ptrCast(render_pipeline);
        } else {
            log.err("Failed to create RenderPipeline: got null", .{});
            return error.FailedToCreateRenderPipeline;
        }
    }

    extern "c" fn wgpuDeviceCreateComputePipeline(
        device: ?*const Device,
        descriptor: *const ComputePipelineDescriptor,
    ) ?*const ComputePipeline;

    pub fn createComputePipeline(
        device: *const Device,
        descriptor: *const ComputePipelineDescriptor,
    ) WGPUError!*const ComputePipeline {
        const maybe_compute_pipeline = wgpuDeviceCreateComputePipeline(device, descriptor);

        if (maybe_compute_pipeline) |compute_pipeline| {
            log.info("Created ComputePipeline {}", .{compute_pipeline});
            return compute_pipeline;
        } else {
            return WGPUError.FailedToCreateComputePipeline;
        }
    }

    extern "c" fn wgpuDeviceCreateBuffer(
        device: ?*const Device,
        descriptor: *const BufferDescriptor,
    ) ?*const Buffer;

    pub fn createBuffer(
        device: *const Device,
        descriptor: *const BufferDescriptor,
    ) WGPUError!*const Buffer {
        const maybe_buffer = wgpuDeviceCreateBuffer(device, descriptor);

        if (maybe_buffer) |buffer| {
            log.info("Created Buffer {s}", .{descriptor.label.toSlice()});
            return buffer;
        } else {
            return WGPUError.FailedToCreateBuffer;
        }
    }

    extern "c" fn wgpuDeviceCreateBindGroup(
        device: ?*const Device,
        descriptor: *const wgpu.BindGroup.Descriptor.External,
    ) ?*const BindGroup;
    pub fn CreateBindGroup(
        device: *const Device,
        descriptor: *const wgpu.BindGroup.Descriptor,
    ) WGPUError!*const BindGroup {
        const maybe_bindgroup = wgpuDeviceCreateBindGroup(device, &wgpu.BindGroup.Descriptor.External{
            .next_in_chain = descriptor.next_in_chain,
            .entries = if (descriptor.entries.len > 0) descriptor.entries.ptr else null,
            .entry_count = descriptor.entries.len,
            .label = wgpu.StringView.fromSlice(descriptor.label),
        });

        if (maybe_bindgroup) |bindgroup| {
            log.info("Created BindGroup {s}", .{descriptor.label});
            return bindgroup;
        } else {
            log.err("Failed to create Bindgroup {s}", .{descriptor.label});
            return WGPUError.FailedToCreateBindGroup;
        }
    }

    extern "c" fn wgpuDeviceCreateTexture(
        device: *const Device,
        descriptor: *const TextureDescriptor.ExternalStruct,
    ) ?*const Texture;
    pub fn createTexture(
        device: *const Device,
        descriptor: *const TextureDescriptor,
    ) WGPUError!*const Texture {
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
        .size = .{ .width = 400, .height = 200, .depth_or_array_layers = 1 },
        .usages = .{
            .CopySrc = true,
            .TextureBinding = true,
        },
    });
    defer texture.release();
}
