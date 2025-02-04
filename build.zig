const std = @import("std");
const log = std.log.scoped(.@"build");

const OptimizeMode = std.builtin.OptimizeMode;
const Target = std.Build.ResolvedTarget;
const Module = std.Build.Module;
const Dependency = std.Build.Dependency;
const Compile = std.Build.Step.Compile;
// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
//
//

// TODO: comptime check min version of zig and assert 0.14.0

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    log.debug("target = {s}-{s}-{s}", .{
        @tagName(target.result.cpu.arch),
        @tagName(target.result.os.tag),
        @tagName(target.result.abi)
        
    });

    const zgl = b.addModule("zgl", .{
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        // .strip = true
    });

    if (!target.result.isWasm()) {
        buildNative(b, zgl, target, optimize);
    }

    // TODO:: find out standard way to expose a lib/package for others
    const lib = b.addStaticLibrary(.{
        .name = "zgl",
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const install_docs = b.addInstallDirectory(.{
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs"
    });

    const docs_step = b.step("docs", "Install docs into zig-out/docs");
    docs_step.dependOn(&install_docs.step);

}

///https://github.com/floooh/sokol-zig/blob/master/build.zig#L409
pub fn emLinkStep(b: *std.Build, lib: *Compile, emsdk: *Dependency) *std.Build.Step.InstallDir {

    // setup emsdk if not already done
    if (setupEmsdk(b, emsdk)) |emsdk_setup| {
        lib.step.dependOn(&emsdk_setup.step);
    }

    const emsdk_include_path = emsdk.path(b.pathJoin(&.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    lib.addSystemIncludePath(emsdk_include_path);
    // const emsdk_lib_path = emsdk.path(b.pathJoin(&.{ "upstream", "emscripten", "cache", "sysroot", "lib", "wasm32-emscripten" }));

    const emcc_path = emsdk.path(b.pathJoin(&.{"upstream", "emscripten", "emcc"})).getPath(b);
    const emcc = b.addSystemCommand(&.{emcc_path});

    emcc.setName("emcc");
    // emcc.addArg("-sVERBOSE=1");

    // emcc.addArg(b.fmt("-L{s}", .{emsdk_lib_path.getPath(b)}));

    const optimize = lib.root_module.optimize.?;
    if (optimize == .Debug) {
        emcc.addArgs(&.{ 
            // "-O0", 
            // "-sSAFE_HEAP=1", 
            // "-sSTACK_OVERFLOW_CHECK=1" 
        });
        emcc.addArg("-sASSERTIONS=0");
    } else {
        if (optimize == .ReleaseSmall) {
            emcc.addArg("-Oz");
        } else {
            emcc.addArg("-O3");
        }
    }

    emcc.addArgs(&.{
        "-sUSE_GLFW=3",
        "-sUSE_WEBGPU=1",
        "-sUSE_OFFSET_CONVERTER",
        "-sASYNCIFY", // needed for emscripten_sleep
        "-sALLOW_MEMORY_GROWTH"
    });

    emcc.addArtifactArg(lib);
    
    emcc.addArg("-o");

    const out_file = emcc.addOutputFileArg(b.fmt("{s}.html", .{lib.name}));

    const install = b.addInstallDirectory(.{
        .source_dir = out_file.dirname(),
        .install_dir = .prefix,
        .install_subdir = "web"
    });

    install.step.dependOn(&emcc.step);

    return install;

}


/// Setup emsdk if it is not already done.
/// runs ('emsdk install + activate')
fn setupEmsdk(b: *std.Build, emsdk: *Dependency) ?*std.Build.Step.Run {
    const dot_emsc_path = emsdk.path(".emscripten").getPath(b);
    const dot_emsc_exists = !std.meta.isError(std.fs.accessAbsolute(dot_emsc_path, .{}));

    if (!dot_emsc_exists) {
        const emsdk_install = createEmsdkStep(b, emsdk);
        emsdk_install.addArgs(&.{ "install", "latest" });

        const emsdk_activate = createEmsdkStep(b, emsdk);
        emsdk_activate.addArgs(&.{ "activate", "latest" });

        emsdk_activate.step.dependOn(&emsdk_install.step);

        return emsdk_activate;
    } else {
        return null;
    }

}

fn createEmsdkStep(b: *std.Build, emsdk: *std.Build.Dependency) *std.Build.Step.Run {
    if (b.graph.host.result.os.tag == .windows) {
        return b.addSystemCommand(&.{emsdk.path("emsdk.bat").getPath(b)});
    } else {
        return b.addSystemCommand(&.{emsdk.path("emsdk").getPath(b)});
    }
}


// TODO: build lib and link it to module
fn buildNative(b: *std.Build, zgl: *Module, target: Target, optimize: OptimizeMode) void {

    zgl.link_libc = true;

    const DisplayServer = enum {
        X11,
        Wayland
    };
    const display_server = b.option(
        DisplayServer, 
        "DisplayServer", 
        "Choose linux display server, (X11 or Wayland)"
    ) orelse .X11;

    const options = b.addOptions();
    options.addOption(DisplayServer, "DisplayServer", display_server);

    const glfw_dep = b.dependency("glfw", .{});
    const glfw = b.addStaticLibrary(.{
        .name = "glfw",
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .use_llvm = true
        // .strip = true
    });

    zgl.addOptions("zgl_options", options);

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
            zgl.linkSystemLibrary("propsys", .{});
            zgl.linkSystemLibrary("api-ms-win-core-winrt-error-l1-1-0", .{});
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

            const flag = switch(display_server) {
                .X11 => "-D_GLFW_X11",
                .Wayland => "-D_GLFW_WAYLAND"
            };
            
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

                },
                .flags = &.{ flag },
            });

            const x11_headers = b.dependency("x11_headers", .{});
            glfw.addIncludePath(x11_headers.path(""));

            // glfw.addIncludePath(glfw_dep.path("deps"));

            switch (display_server) {
                .X11 => {
                    glfw.addCSourceFiles(.{
                        .root = glfw_dep.path("src"),
                        .files = &.{
                            "x11_init.c",
                            "x11_monitor.c",
                            "x11_window.c",
                            "glx_context.c",
                        },
                        .flags = &.{ flag }
                    });
                },

                .Wayland => {
                    glfw.addCSourceFiles(.{
                        .root = glfw_dep.path("src"),
                        .files = &.{
                            "wl_init.c",
                            "wl_monitor.c",
                            "wl_window.c",
                        },
                        .flags = &.{ flag }
                    });
                    glfw.addIncludePath(b.path("wayland-headers/wayland"));
                    glfw.addIncludePath(b.path("wayland-headers/wayland-protocols"));
                }
            }
            

        },

        else => @panic("Unsupported OS")
    }

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
        else => @panic("Unsupported archiwdj")
    };
    const wgpu_pkg_name = b.fmt("wgpu_{s}_{s}_{s}", .{os_str, arch_str, opt_str});

    const wgpu_native = b.dependency(wgpu_pkg_name, .{});

    // TODO: look into using addObjectFile instead
    zgl.addLibraryPath(wgpu_native.path("lib/"));
    zgl.linkSystemLibrary("wgpu_native", .{ 
        .preferred_link_mode = .static, 
        .needed = true,
        // .weak = true
    });

    // const translate_c = b.addTranslateC(.{
    //     .root_source_file = b.path("include/c.h"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // const translate_c_mod = translate_c.createModule();
    // translate_c.addIncludePath(glfw_dep.path("include"));
    // translate_c.addIncludePath(wgpu_native.path("include"));

    // zgl.addImport("c", translate_c_mod);

    zgl.linkLibrary(glfw);

    const mod_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/zgl.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true
    });
    // mod_unit_tests.root_module.addImport("c", translate_c_mod);
    mod_unit_tests.addLibraryPath(wgpu_native.path("lib/"));
    mod_unit_tests.linkSystemLibrary("wgpu_native");

    const run_mod_unit_tests = b.addRunArtifact(mod_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_mod_unit_tests.step);
}
