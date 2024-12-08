const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
//

// TODO: comptime check min version of zig and assert 0.14.0

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opt_str = switch (optimize) {
        .Debug => "debug",
        else => "release"
    };

    const os_str = switch (target.result.os.tag) {
        .macos,
        .windows,
        .linux,
        => |res| @tagName(res),
        else => @panic("Unsupported OS")
    };

    const arch_str = switch (target.result.cpu.arch) {
        .aarch64,
        .x86_64,
        => |res| @tagName(res),
        else => @panic("Unsupported arch")
    };

    const zgl = b.addModule("zgl", .{
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        // .strip = true
    });


    const glfw_dep = b.dependency("glfw", .{});
    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        // .strip = true
    });

    const wgpu_pkg_name = b.fmt("wgpu_{s}_{s}_{s}", .{os_str, arch_str, opt_str});

    const wgpu_native = b.dependency(wgpu_pkg_name, .{});

    switch (target.result.os.tag) {
        .macos => {
            zgl.linkFramework("Cocoa", .{});
            zgl.linkFramework("Metal", .{});
            zgl.linkFramework("QuartzCore", .{});

            glfw.linkSystemLibrary("objc");
            glfw.linkFramework("IOKit");
            glfw.linkFramework("CoreFoundation");
            glfw.linkFramework("Metal");
            glfw.linkFramework("AppKit");
            glfw.linkFramework("CoreServices");
            glfw.linkFramework("CoreGraphics");
            glfw.linkFramework("Foundation");

            glfw.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "platform.c",
                    "monitor.c",
                    "init.c",
                    "vulkan.c",
                    "input.c",
                    "context.c",
                    "window.c",
                    "osmesa_context.c",
                    "egl_context.c",
                    "null_init.c",
                    "null_monitor.c",
                    "null_window.c",
                    "null_joystick.c",
                    "posix_thread.c",
                    "posix_module.c",
                    "posix_poll.c",
                    "nsgl_context.m",
                    "cocoa_time.c",
                    "cocoa_joystick.m",
                    "cocoa_init.m",
                    "cocoa_window.m",
                    "cocoa_monitor.m",
                },
                .flags = &.{"-D_GLFW_COCOA"},
            });


            const metal_layer = b.addStaticLibrary(.{
                .name = "metal_layer",
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });

            metal_layer.addCSourceFiles(.{
                .files = &.{
                    "src/setup_metal_layer.m"
                }
            });
            metal_layer.linkFramework("Foundation");
            metal_layer.linkFramework("Cocoa");
            metal_layer.linkFramework("QuartzCore");
            metal_layer.addIncludePath(glfw_dep.path("include/GLFW"));
            zgl.linkLibrary(metal_layer);

        },
        .windows => {

            glfw.linkSystemLibrary("gdi32");
            glfw.linkSystemLibrary("user32");
            glfw.linkSystemLibrary("shell32");

            // Required by wgpu_native
            zgl.linkSystemLibrary("ole32", .{});
            zgl.linkSystemLibrary("user32", .{});
            zgl.linkSystemLibrary("kernel32", .{});
            zgl.linkSystemLibrary("userenv", .{});
            zgl.linkSystemLibrary("ws2_32", .{});
            zgl.linkSystemLibrary("oleaut32", .{});
            zgl.linkSystemLibrary("opengl32", .{});
            zgl.linkSystemLibrary("d3dcompiler_47", .{});
            zgl.link_libcpp = true;

            glfw.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "platform.c",
                    "monitor.c",
                    "init.c",
                    "vulkan.c",
                    "input.c",
                    "context.c",
                    "window.c",
                    "osmesa_context.c",
                    "egl_context.c",
                    "null_init.c",
                    "null_monitor.c",
                    "null_window.c",
                    "null_joystick.c",
                    "wgl_context.c",
                    "win32_thread.c",
                    "win32_init.c",
                    "win32_monitor.c",
                    "win32_time.c",
                    "win32_joystick.c",
                    "win32_window.c",
                    "win32_module.c",
                },
                .flags = &.{"-D_GLFW_WIN32"},
            });

        },

        .linux => {
            zgl.link_libcpp = true; // wgpu need cpp std lib
            
            glfw.addCSourceFiles(.{
                .root = glfw_dep.path("src"),
                .files = &.{
                    "platform.c",
                    "monitor.c",
                    "init.c",
                    "vulkan.c",
                    "input.c",
                    "context.c",
                    "window.c",
                    "osmesa_context.c",
                    "egl_context.c",
                    "null_init.c",
                    "null_monitor.c",
                    "null_window.c",
                    "null_joystick.c",
                    "posix_time.c",
                    "posix_thread.c",
                    "posix_module.c",
                    "egl_context.c",

                    // shared
                    "xkb_unicode.c",
                    "linux_joystick.c",
                    "posix_poll.c",

                    //X11 specific
                    "x11_init.c",
                    "x11_monitor.c",
                    "x11_window.c",
                    "glx_context.c",

                    //wayland
                    // "wl_init.c",
                    // "wl_monitor.c",
                    // "wl_window.c",
                },
                .flags = &.{"-D_GLFW_X11"},
            });
            // glfw.addIncludePath(b.path("wayland-headers/wayland"));
            // glfw.addIncludePath(b.path("wayland-headers/wayland-protocols"));
            glfw.addIncludePath(b.path("x11-headers/"));
            
            // b.addSearchPrefix("lib/x86_64-linux-gnu");
            const system_sdk = b.dependency("system_sdk", .{});
            // glfw.addLibraryPath(b.path("lib/x86_64-linux-gnu"));
            // glfw.addLibraryPath(system_sdk.path("linux/lib/x86_64-linux-gnu"));
            // glfw.linkSystemLibrary("X11");
            // zgl.linkSystemLibrary("X11", .{});
            zgl.addObjectFile(system_sdk.path("linux/lib/x86_64-linux-gnu/libX11.so"));
            // glfw.addObjectFile(b.path("lib/x86_64-linux-gnu/libX11.a"));

        },
        else => @panic("Unsupported OS")
    }

    zgl.addLibraryPath(wgpu_native.path("lib/"));
    zgl.linkSystemLibrary("wgpu_native", .{ 
        .preferred_link_mode = .static, 
        .needed = true,
        // .weak = true
    });

    zgl.linkLibrary(glfw);

    const mod_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true
    });
    mod_unit_tests.addLibraryPath(wgpu_native.path("lib/"));
    mod_unit_tests.linkSystemLibrary("wgpu_native");

    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
