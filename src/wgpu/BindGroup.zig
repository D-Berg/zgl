const std = @import("std");
const log = std.log.scoped(.@"wgpu/BindGroup");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const StringView = wgpu.StringView;
const TextureView = wgpu.Texture.ViewImpl;
const Sampler = wgpu.Sampler;
const BindGroupLayout = wgpu.BindGroupLayout;


pub const BindGroup = opaque {




    extern "c" fn wgpuBindGroupRelease(bindgroup: *BindGroup) void;
    pub fn Release(bindgroup: *BindGroup) void {
        wgpuBindGroupRelease(bindgroup);
        log.info("Released BindGroup", .{});
    }

};
