const std = @import("std");
const log = std.log.scoped(.@"wgpu/BindGroup");
const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const StringView = wgpu.StringView;
const TextureView = wgpu.Texture.ViewImpl;
const Sampler = wgpu.Sampler;


pub const BindGroup = opaque {

    pub const Layout = opaque {

        extern "c" fn wgpuBindGroupLayoutRelease(layout: *Layout) void;
        pub fn Release(layout: *Layout) void {
            wgpuBindGroupLayoutRelease(layout);
        }
        
    };

    pub const Descriptor = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        label: StringView = .{ .data = "", .length = 0 },
        layout: ?*Layout = null, 
        entryCount: usize = 0,
        entries: ?[*]const Entry = null
    };

    pub const Entry = extern struct {
        nextInChain: ?*const ChainedStruct = null,
        binding: u32,
        buffer: ?wgpu.Buffer.BufferImpl = null,
        offset: u64 = 0,
        size: u64 = 0,
        sampler: ?*Sampler = null,
        textureView: ?TextureView = null,
    };

    extern "c" fn wgpuBindGroupRelease(bindgroup: *BindGroup) void;
    pub fn Release(bindgroup: *BindGroup) void {
        wgpuBindGroupRelease(bindgroup);
        log.info("Released BindGroup", .{});
    }

};
