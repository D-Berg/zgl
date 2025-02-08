const std = @import("std");
const log = std.log.scoped(.@"build");

pub fn build(b: *std.Build) void {

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zgl_dep = b.dependency("zgl", .{
        .target = target,
        .optimize = optimize
    });

    var examples_dir = std.fs.cwd().openDir("./", .{ .iterate = true }) catch {
        log.debug("failed to open examples dir", .{});
        return;
    };
    defer examples_dir.close();

    var dir_iterator = examples_dir.iterate();

    while (dir_iterator.next() catch return) |entry| {
        if (entry.kind != .directory) continue;
        
        log.debug("directory: {s}", .{entry.name});

        if (std.mem.eql(u8, entry.name, "triangle-web")) continue;
        if (std.mem.eql(u8, entry.name, "zig-out")) continue;
        if (std.mem.eql(u8, entry.name, ".zig-cache")) continue;

        const file = b.pathJoin(&.{ entry.name, "src", "main.zig"});
        log.debug("compiling {s}", .{file});

        const exe = b.addExecutable(.{
            .name = b.fmt("example_{s}", .{entry.name}),
            .root_source_file = b.path(file),
            .target = target,
            .optimize = optimize,
        });

        exe.root_module.addImport("zgl", zgl_dep.module("zgl"));

        b.installArtifact(exe);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        const run_step = b.step(
            b.fmt("run-{s}", .{entry.name}), 
            b.fmt("run example {s}", .{entry.name})
        );
        run_step.dependOn(&run_cmd.step);


    }
}
