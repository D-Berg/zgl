const std = @import("std");
pub const wgpu = @import("wgpu/wgpu.zig");
pub const glfw = @import("glfw.zig");

test "test all" {
    std.testing.refAllDecls(@This());
}
