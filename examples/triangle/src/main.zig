const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const log = std.log.scoped(.main);
const zgl = @import("zgl");
const wgpu = zgl.wgpu;
const glfw = zgl.glfw;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const triange_shader = @embedFile("shaders/triangle.wgsl");

fn onDeviceLost(reason: wgpu.DeviceLostReason, message: [*c]const u8, user_data: ?*anyopaque) callconv(.C) void {
    _ = user_data;
    log.err("lost device. reason: {}, message: {s}", .{ reason, message });
}

fn onError(tpe: wgpu.ErrorType, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    log.err("WGPU encountered an error of type {s} with message: {s}", .{ @tagName(tpe), message });
}

fn onQueueWorkDone(status: wgpu.Queue.WorkDoneStatus, _: ?*anyopaque, _: ?*anyopaque) callconv(.C) void {
    // if (message != null) log.info("got a message: {s}", .{message});
    log.info("Queued work finished with status: {s}", .{@tagName(status)});
}

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    glfw.Window.hint(.{ .client_api = .NO_API, .resizable = false });
    const window = try glfw.Window.create(WINDOW_WIDTH, WINDOW_HEIGHT, "My window");
    defer window.destroy();

    // TODO: fix crash when supplying instance descriptor
    // thread '<unnamed>' panicked at src/lib.rs:655:17
    // Unsupported timed WaitAny features specified
    const instance = try wgpu.createInstance(null);
    defer instance.release();

    const surface = try glfw.getWGPUSurface(window, instance);
    defer surface.release();

    const adapter = try instance.requestAdapter(&.{});
    defer adapter.release();

    const surface_capabilities = surface.getCapabilities(adapter);
    defer surface_capabilities.freeMembers();

    surface_capabilities.logCapabilites();

    if (adapter.getLimits()) |limits| {
        log.info("Adapter Limits:\n{}", .{limits});
    }

    const adapter_features = adapter.getFeatures();
    defer adapter_features.freeMembers();

    log.info("adapter features:\n{}", .{adapter_features});

    const adapter_info = adapter.getInfo();
    defer adapter_info.freeMembers();

    log.info("{}", .{adapter_info});

    const device = try adapter.requestDevice(&.{
        .label = wgpu.StringView.fromSlice("My device"),
        .defaultQueue = .{ .label = wgpu.StringView.fromSlice("The default Queue") },
        .deviceLostCallback = &onDeviceLost,
        .uncapturedErrorCallbackInfo = .{ .callback = &onError },
    });
    defer device.release();

    const device_features = device.getFeatures();
    defer device_features.freeMembers();

    log.info("device deatures:{}\n", .{device_features});

    const device_limits = try device.getLimits();
    log.info("Device Limits:\n{}", .{device_limits});

    const queue = try device.getQueue();
    defer queue.release();

    // TODO: fix this function call
    // _ = queue.OnSubmittedWorkDone(.{
    //     .callback = &onQueueWorkDone,
    //     .userdata1 = null,
    //     .userdata2 = null
    // });

    var surface_config = wgpu.SurfaceConfiguration{
        .nextInChain = null,
        .device = device,
        .format = surface_capabilities.formats[0],
        .usage = .RenderAttachment,
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .presentMode = .Immediate,
        .alphaMode = .Auto,
    };

    surface.configure(&surface_config);
    defer surface.unconfigure();

    const wgsl_code = wgpu.ShaderSourceWGSL{
        .code = wgpu.StringView.fromSlice(triange_shader),
        .chain = .{ .sType = .ShaderSourceWGSL },
    };
    const shader_module = try device.createShaderModule(&.{ .nextInChain = &wgsl_code.chain });
    defer shader_module.release();

    const blend_state = wgpu.BlendState{
        .color = .{
            .srcFactor = .SrcAlpha,
            .dstFactor = .OneMinusSrcAlpha,
            .operation = .Add,
        },
        .alpha = .{
            .srcFactor = .Zero,
            .dstFactor = .One,
            .operation = .Add,
        },
    };
    const zero: u32 = 0;

    const color_target = wgpu.ColorTargetState{
        .format = surface_capabilities.formats[0],
        .blend = &blend_state,
        .writeMask = .All,
    };

    const render_pipeline = try device.createRenderPipeline(.{
        .vertex = .{
            .module = shader_module,
            .entry_point = "vs_main",
        },
        .primitive = .{
            .topology = .TriangleList,
            .stripIndexFormat = .Undefined,
            .frontFace = .CCW, //counter clockwise
            .cullMode = .None,
            .unclippedDepth = false,
        },
        .fragment = &wgpu.FragmentState{
            .module = shader_module,
            .entryPoint = wgpu.StringView.fromSlice("fs_main"),
            .targetCount = 1,
            .targets = &[1]wgpu.ColorTargetState{color_target},
        },
        .multi_sample = .{
            .count = 1,
            .mask = ~zero,
            .alphaToCoverageEnabled = false,
        },
    });
    defer render_pipeline.release();

    while (!window.shouldClose()) {
        glfw.pollEvents();

        const texture = surface.getCurrentTexture() catch |err| switch (err) {
            error.RecoverableTexture => {
                const size = try window.getSize();

                surface_config.width = size.width;
                surface_config.height = size.height;

                surface.configure(&surface_config);

                continue;
            },
            else => {
                return err;
            },
        };
        defer texture.release();

        const view = try texture.createView(&wgpu.TextureViewDescriptor{
            .label = wgpu.StringView.fromSlice("Surface texture view"),
            .format = texture.getFormat(),
            .dimension = .@"2D",
            .baseMipLevel = 0,
            .mipLevelCount = 1,
            .baseArrayLayer = 0,
            .arrayLayerCount = 1,
            .aspect = .All,
            .usage = surface_config.usage,
        });
        defer view.release();

        const command_encoder = try device.createCommandEncoder(&.{
            .label = wgpu.StringView.fromSlice("My command Encoder"),
        });

        const render_pass_color_attachement = wgpu.RenderPassColorAttachment{
            .view = view,
            .resolveTarget = null,
            .loadOp = .Clear,
            .storeOp = .Store,
            .clearValue = .{ .r = 0.9, .g = 0.1, .b = 0.2, .a = 1.0 },
            .depthSlice = .Undefined,
        };

        {
            const render_pass_encoder = try command_encoder.beginRenderPass(&.{
                .colorAttachmentCount = 1,
                .colorAttachments = &.{render_pass_color_attachement},
                .depthStencilAttachment = null,
                .occlusionQuerySet = null,
                .timestampWrites = null,
            });

            render_pass_encoder.setPipeline(render_pipeline);
            render_pass_encoder.draw(3, 1, 0, 0);

            render_pass_encoder.end();
            render_pass_encoder.release();
        }

        const command_buffer = try command_encoder.finish(&.{});
        command_encoder.release();

        queue.submit(&.{command_buffer});
        command_buffer.release();

        surface.present();

        _ = device.poll(false, null);
    }
}
