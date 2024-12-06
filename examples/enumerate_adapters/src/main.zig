const std = @import("std");
const wgpu = @import("zgl").wgpu;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const instance = try wgpu.Instance.Create(&.{});
    defer instance.Release();

    const adapters = try instance.EnumerateAdapters(allocator);
    defer allocator.free(adapters);

    for (adapters) |adapter| {
        const info = adapter.GetInfo();

        info.logInfo();

        if (adapter.GetLimits()) |limits| {
            limits.logLimits();
        }

    }
}
