const std = @import("std");
const log = std.log.scoped(.@"wgpu/BindGroup");
const wgpu = @import("wgpu.zig");
const StringView = wgpu.StringView;

pub const BindGroup = *opaque {
    extern "c" fn wgpuBindGroupSetLabel(bindGroup: BindGroup, label: StringView) void;
    pub fn setLabel(bindGroup: BindGroup, label: StringView) void {
        wgpuBindGroupSetLabel(bindGroup, label);
        log.debug("Label set to {s}", .{label.toSlice()});
    }

    extern "c" fn wgpuBindGroupAddRef(bindGroup: BindGroup) void;
    pub fn addRef(bindGroup: BindGroup) void {
        wgpuBindGroupAddRef(bindGroup);
        log.debug("Added reference to bindgroup", .{});
    }
    
    extern "c" fn wgpuBindGroupRelease(bindgroup: BindGroup) void;
    pub fn release(bindgroup: BindGroup) void {
        wgpuBindGroupRelease(bindgroup);
        log.info("Released BindGroup", .{});
    }
};
