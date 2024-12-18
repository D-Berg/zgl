const std = @import("std");
const zgl = @import("zgl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zgl_dep = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize,
    });

    if (target.result.isWasm()) {

        const lib = b.addStaticLibrary(.{
            .name = "triangle",
            .root_source_file = b.path("src/main.zig"),
            .optimize = optimize,
            .target = target
        });

        lib.root_module.addImport("zgl", zgl_dep.module("zgl"));
        const emsdk = zgl_dep.builder.dependency("emsdk", .{});

        const link_step = zgl.emLinkStep(b, lib, emsdk);
        b.getInstallStep().dependOn(&link_step.step);

    } else {
        @panic("not yet supported for this example");
    }
}

