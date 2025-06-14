const std = @import("std");
const wgpu = @import("zgl").wgpu;

pub fn main() !void {
    const instance = try wgpu.createInstance(&.{});
    defer instance.release();

    const adapter = try instance.requestAdapter(&.{});
    defer adapter.release();

    const info = adapter.getInfo();

    std.debug.print("{}", .{info});
}
