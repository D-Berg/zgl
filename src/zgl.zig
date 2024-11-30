const std = @import("std");
pub const wgpu = @import("wgpu/wgpu.zig");

test "create instance" {

    const instance = try wgpu.Instance.Create(&.{});
    defer instance.Release();

    const adapter = try instance.RequestAdapter(&.{});
    defer adapter.Release();

    const info = adapter.GetInfo();
    info.logInfo();

    std.debug.print("instance = {}\n", .{instance});
    std.debug.print("adapter = {}\n", .{adapter});
    std.debug.print("backend = {s}\n", .{@tagName(info.backendType)});
}
