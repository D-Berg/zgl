const std = @import("std");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
//

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});


    const zgl = b.addModule("zgl", .{
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    if (target.result.os.tag == .linux) zgl.link_libcpp = true;

    const opt = switch (optimize) {
        .Debug => "debug",
        else => "release"
    };

    const os = switch (target.result.os.tag) {
        .macos,
        .windows,
        .linux,
        => |res| @tagName(res),
        else => @panic("Unsupported OS")
    };

    const arch = switch (target.result.cpu.arch) {
        .aarch64,
        .x86_64,
        => |res| @tagName(res),
        else => @panic("Unsupported arch")
    };

    const wgpu_pkg_name = b.fmt("wgpu_{s}_{s}_{s}", .{os, arch, opt});

    const wgpu_native = b.dependency(wgpu_pkg_name, .{});

    if (target.result.os.tag == .macos) {
        zgl.linkFramework("Cocoa", .{});
        zgl.linkFramework("Metal", .{});
        zgl.linkFramework("QuartzCore", .{});
    }

    zgl.addLibraryPath(wgpu_native.path("lib/"));
    zgl.linkSystemLibrary("wgpu_native", .{ 
        .preferred_link_mode = .static, 
        .needed = true
    });

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
