const std = @import("std");
const zgl = @import("zgl");
const wgpu = zgl.wgpu;
const glfw = zgl.glfw;

pub fn main() !void {

    glfw.Window.hint(.{ .resizable = false, .client_api = .NO_API });

    try glfw.init();
    defer glfw.terminate();

    const window: glfw.Window = try .Create(400, 400, "Camera");
    defer window.destroy();

    while (!window.ShouldClose()) {
        glfw.pollEvents();
    }

}
