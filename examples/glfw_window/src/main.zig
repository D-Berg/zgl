const std = @import("std");
const glfw = @import("zgl").glfw;

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const window = try glfw.Window.create(500, 500, "AAAA WINDOOOW");
    defer window.destroy();

    while (!window.shouldClose()) {
        glfw.pollEvents();
    }
}
