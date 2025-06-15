const std = @import("std");
const log = std.log.scoped(.@"wgpu/BindGroup");
const wgpu = @import("wgpu.zig");

const StringView = wgpu.StringView;

pub const BindGroup = opaque {
    pub const Descriptor = struct {
        next_in_chain: ?*const wgpu.ChainedStruct = null,
        label: []const u8 = "",
        layout: ?*const wgpu.BindGroupLayout = null,
        entries: []const BindGroup.Entry = &[_]BindGroup.Entry{},

        pub const External = extern struct {
            next_in_chain: ?*const wgpu.ChainedStruct = null,
            label: StringView = .{},
            layout: ?*const wgpu.BindGroupLayout = null,
            entry_count: usize = 0, // TODO: use slice
            entries: ?[*]const BindGroup.Entry = null,
        };
    };

    pub const Entry = extern struct {
        next_in_chain: ?*const wgpu.ChainedStruct = null,
        binding: u32,
        buffer: ?*const wgpu.Buffer = null,
        offset: u64 = 0,
        size: u64 = 0,
        sampler: ?*const wgpu.Sampler = null,
        texture_view: ?*const wgpu.TextureView = null,
    };

    extern "c" fn wgpuBindGroupSetLabel(bindGroup: ?*const BindGroup, label: StringView) void;
    pub fn setLabel(bind_group: *const BindGroup, label: StringView) void {
        wgpuBindGroupSetLabel(bind_group, label);
        log.debug("Label set to {s}", .{label.toSlice()});
    }

    extern "c" fn wgpuBindGroupAddRef(bind_group: ?*const BindGroup) void;
    pub fn addRef(bind_group: *const BindGroup) void {
        wgpuBindGroupAddRef(bind_group);
        log.debug("Added reference to bindgroup", .{});
    }

    extern "c" fn wgpuBindGroupRelease(bind_group: ?*const BindGroup) void;
    pub fn release(bind_group: *const BindGroup) void {
        wgpuBindGroupRelease(bind_group);
        log.info("Released BindGroup", .{});
    }
};
