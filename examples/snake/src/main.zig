const std = @import("std");
const zgl = @import("zgl");

const glfw = zgl.glfw;
const wgpu = zgl.wgpu;

const RENDER_SIZE = 2;
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 640;

pub fn main() !void {


    try glfw.init();
    defer glfw.terminate();

    glfw.Window.hint(.{ .resizable = false, .client_api = .NO_API });

    const window = try glfw.Window.Create(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake");
    defer window.destroy();


    const instance = try wgpu.Instance.Create(null);
    defer instance.Release();

    const surface = try glfw.GetWGPUSurface(window, instance);
    defer surface.Release();

    const adapter = try instance.RequestAdapter(&.{.compatibleSurface = surface._inner});
    defer adapter.Release();

    const device = try adapter.RequestDevice(null);
    defer device.Release();

    const surface_pref_format = surface.GetPreferredFormat(adapter);

    const surface_conf = wgpu.Surface.Configuration{
        .device = device._inner,
        .format = surface_pref_format,
        .width = RENDER_SIZE * WINDOW_WIDTH,
        .height = RENDER_SIZE * WINDOW_HEIGHT,
        .presentMode = .Fifo,
        .alphaMode = .Auto,
    };

    surface.Configure(&surface_conf);
    defer surface.Unconfigure();

    while (!window.ShouldClose()) {
        glfw.pollEvents();


        // surface.Present();
        _ = device.Poll(false, null);
    }

}
