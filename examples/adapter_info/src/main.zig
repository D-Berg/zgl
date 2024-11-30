const std = @import("std");
const wgpu = @import("zgl").wgpu;

pub fn main() !void {

    const instance = try wgpu.Instance.Create(null);
    defer instance.Release();

    const adapter = try instance.RequestAdapter(null);
    defer adapter.Release();

    adapter.GetInfo().logInfo();

}

