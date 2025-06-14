const std = @import("std");
const log = std.log.scoped(.@"wgpu/BindGroup");
const wgpu = @import("wgpu.zig");
const StringView = wgpu.StringView;

pub const BindGroup = opaque {
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
