const std = @import("std");
pub const wgpu = @import("wgpu/wgpu.zig");

test "create instance" {

    const instance = try wgpu.Instance.Create(null);
    defer instance.Release();

    std.debug.print("instance = {}", .{instance});
}
