const std = @import("std");
const wgpu = @import("zgl").wgpu;
const stdout = std.io.getStdOut().writer();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const instance = try wgpu.CreateInstance(null);
    defer instance.release();

    const adapters = try instance.EnumerateAdapters(allocator);
    defer allocator.free(adapters);

    for (adapters, 0..) |adapter, i| {
        const info = adapter.GetInfo();

        try stdout.print("Adapter({}) Info:\n{}", .{i, info});

        if (adapter.GetLimits()) |limits| {
            try stdout.print("Adapter({}) Limits:\n{}", .{i, limits});
        }

    }
}
