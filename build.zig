const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
//

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
        .strip = true
    });


    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .strip = true
    });

    const wgpu_pkg_name = b.fmt("wgpu_{s}_{s}_{s}", .{os_str, arch_str, opt_str});

    const wgpu_native = b.dependency(wgpu_pkg_name, .{});

    const glfw_src_dir = "glfw/src/";
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
                .files = &.{
                    glfw_src_dir ++ "platform.c",
                    glfw_src_dir ++ "monitor.c",
                    glfw_src_dir ++ "init.c",
                    glfw_src_dir ++ "vulkan.c",
                    glfw_src_dir ++ "input.c",
                    glfw_src_dir ++ "context.c",
                    glfw_src_dir ++ "window.c",
                    glfw_src_dir ++ "osmesa_context.c",
                    glfw_src_dir ++ "egl_context.c",
                    glfw_src_dir ++ "null_init.c",
                    glfw_src_dir ++ "null_monitor.c",
                    glfw_src_dir ++ "null_window.c",
                    glfw_src_dir ++ "null_joystick.c",
                    glfw_src_dir ++ "posix_thread.c",
                    glfw_src_dir ++ "posix_module.c",
                    glfw_src_dir ++ "posix_poll.c",
                    glfw_src_dir ++ "nsgl_context.m",
                    glfw_src_dir ++ "cocoa_time.c",
                    glfw_src_dir ++ "cocoa_joystick.m",
                    glfw_src_dir ++ "cocoa_init.m",
                    glfw_src_dir ++ "cocoa_window.m",
                    glfw_src_dir ++ "cocoa_monitor.m",
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
            zgl.linkLibrary(metal_layer);

        },
        .windows => @panic("unimplemented"),
        .linux => {
            zgl.link_libcpp = true; // wgpu need cpp std lib
            
            glfw.addCSourceFiles(.{
                .files = &.{
                    glfw_src_dir ++ "platform.c",
                    glfw_src_dir ++ "monitor.c",
                    glfw_src_dir ++ "init.c",
                    glfw_src_dir ++ "vulkan.c",
                    glfw_src_dir ++ "input.c",
                    glfw_src_dir ++ "context.c",
                    glfw_src_dir ++ "window.c",
                    glfw_src_dir ++ "osmesa_context.c",
                    glfw_src_dir ++ "egl_context.c",
                    glfw_src_dir ++ "null_init.c",
                    glfw_src_dir ++ "null_monitor.c",
                    glfw_src_dir ++ "null_window.c",
                    glfw_src_dir ++ "null_joystick.c",
                    glfw_src_dir ++ "posix_time.c",
                    glfw_src_dir ++ "posix_thread.c",
                    glfw_src_dir ++ "posix_module.c",
                    glfw_src_dir ++ "egl_context.c",

                    //wayland specific
                    glfw_src_dir ++ "xkb_unicode.c",
                    glfw_src_dir ++ "linux_joystick.c",
                    glfw_src_dir ++ "posix_poll.c",
                    glfw_src_dir ++ "wl_init.c",
                    glfw_src_dir ++ "wl_monitor.c",
                    glfw_src_dir ++ "wl_window.c",
                },
                .flags = &.{"-D_GLFW_WAYLAND"},
            });
            glfw.addIncludePath(b.path("wayland-headers/wayland"));
            glfw.addIncludePath(b.path("wayland-headers/wayland-protocols"));
            glfw.addIncludePath(b.path("x11-headers/"));

        },
        else => @panic("Unsupported OS")
    }

    zgl.addLibraryPath(wgpu_native.path("lib/"));
    zgl.linkSystemLibrary("wgpu_native", .{ 
        .preferred_link_mode = .static, 
        .needed = true
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
