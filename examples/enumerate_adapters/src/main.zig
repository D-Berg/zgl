const std = @import("std");
const wgpu = @import("zgl").wgpu;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    const instance = try wgpu.createInstance(null);
    defer instance.release();

    const adapters = try instance.enumerateAdapters(allocator);
    defer allocator.free(adapters);

    for (adapters, 0..) |adapter, i| {
        const info = adapter.getInfo();

        try stdout.print("Adapter({}) Info:\n{}", .{ i, info });

        if (adapter.getLimits()) |limits| {
            try stdout.print("Adapter({}) Limits:\n{}", .{ i, limits });
        }
    }
}
