const std = @import("std");
const wgpu = @import("zgl").wgpu;

pub fn main() !void {

    const instance = try wgpu.Instance.Create(&.{});
    defer instance.Release();

    const adapter = try instance.RequestAdapter(&.{});
    defer adapter.Release();

    const info = adapter.GetInfo();
    info.logInfo();

}

