const std = @import("std");
pub const wgpu = @import("wgpu/wgpu.zig");
pub const glfw = @import("glfw.zig");
// pub const c = @import("c");

test "test all" {
    std.testing.refAllDecls(@This());
}
