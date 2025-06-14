const std = @import("std");
const zgl = @import("zgl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zgl_dep = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .emscripten) {
        const lib = b.addStaticLibrary(.{
            .name = "triangle",
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target,
        });

        lib.root_module.addImport("zgl", zgl_dep.module("zgl"));
        const emsdk = zgl_dep.builder.dependency("emsdk", .{});

        const link_step = zgl.emLinkStep(b, lib, emsdk);
        b.getInstallStep().dependOn(&link_step.step);

        b.installArtifact(lib);
    } else {
        const exe = b.addExecutable(.{
            .name = "triangle",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .strip = true,
        });

        exe.root_module.addImport("zgl", zgl_dep.module("zgl"));

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);

        run_cmd.step.dependOn(b.getInstallStep());

        // This allows the user to pass arguments to the application in the build
        // command itself, like this: `zig build run -- arg1 arg2 etc`
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }

        // This creates a build step. It will be visible in the `zig build --help` menu,
        // and can be selected like this: `zig build run`
        // This will evaluate the `run` step rather than the default, which is "install".
        const run_step = b.step("run", "Run the app");
        run_step.dependOn(&run_cmd.step);

        const exe_unit_tests = b.addTest(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

        // Similar to creating the run step earlier, this exposes a `test` step to
        // the `zig build --help` menu, providing a way for the user to request
        // running the unit tests.
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }
}
