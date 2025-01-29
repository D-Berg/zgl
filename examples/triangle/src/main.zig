const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const log = std.log.scoped(.@"main");
const zgl = @import("zgl");
const wgpu = zgl.wgpu;
const Surface = wgpu.Surface;
const glfw = zgl.glfw;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const triange_shader = @embedFile("shaders/triangle.wgsl");

fn onDeviceLost(reason: wgpu.Device.LostReason, message: [*c]const u8, user_data: ?*anyopaque) callconv(.C) void {
    _ = user_data;
    log.err("lost device. reason: {}, message: {s}", .{reason, message});
}

fn onError(tpe: wgpu.ErrorType, message: [*c]const u8, userdata: ?*anyopaque) callconv(.C) void {
    _ = userdata;
    log.err("WGPU encountered an error of type {s} with message: {s}", .{@tagName(tpe), message});
}

fn onQueueWorkDone(status: wgpu.Queue.WorkDoneStatus, _: ?*anyopaque, _: ?*anyopaque) callconv(.C) void {
    // if (message != null) log.info("got a message: {s}", .{message});
    log.info("Queued work finished with status: {s}", .{@tagName(status)});
}

pub fn main() !void {

    try glfw.init();
    defer glfw.terminate();

    glfw.Window.hint(.{ .client_api = .NO_API, .resizable = false });
    const window = try glfw.Window.Create(WINDOW_WIDTH, WINDOW_HEIGHT, "My window");
    defer window.destroy();

    // TODO: fix crash when supplying instance descriptor
    // thread '<unnamed>' panicked at src/lib.rs:655:17
    // Unsupported timed WaitAny features specified
    const instance = try wgpu.Instance.Create(null);     
    defer instance.Release();

    const surface = try glfw.GetWGPUSurface(window, instance);
    defer surface.Release();

    const adapter = try instance.RequestAdapter(&.{.compatibleSurface = surface._inner});
    defer adapter.release();

    const surface_capabilities = surface.GetCapabilities(adapter);
    defer surface_capabilities.FreeMembers();

    surface_capabilities.logCapabilites();

    if (adapter.GetLimits()) |limits| {
        limits.logLimits();
    }

    const adapter_features = adapter.GetFeatures();
    defer adapter_features.deinit();

    log.info("adapter features:\n{}", .{adapter_features});

    const adapter_info = adapter.GetInfo();
    defer adapter_info.deinit();

    log.info("{}", .{adapter_info});

    const device = try adapter.RequestDevice(&.{ 
        .label = wgpu.StringView.fromSlice("My device"), 
        .defaultQueue = .{.label = wgpu.StringView.fromSlice("The default Queue") },
        .deviceLostCallback = &onDeviceLost,
        .uncapturedErrorCallbackInfo = .{.callback = &onError}

    });
    defer device.Release();

    const device_features = device.GetFeatures();
    defer device_features.deinit(); 

    log.info("device deatures:{}\n", .{device_features});

    const device_limits = try device.GetLimits();
    device_limits.logLimits();

    const queue = try device.GetQueue();
    defer queue.Release();

    // TODO: fix this function call
    // _ = queue.OnSubmittedWorkDone(.{
    //     .callback = &onQueueWorkDone,
    //     .userdata1 = null,
    //     .userdata2 = null
    // });

    var surface_config = Surface.Configuration{
        .nextInChain = null,
        .device = device._inner,
        .format = surface_capabilities.formats[0],
        .usage = .RenderAttachment,
        .width = WINDOW_WIDTH,
        .height = WINDOW_HEIGHT,
        .presentMode = .Immediate,
        .alphaMode = .Auto,
    };


    surface.Configure(&surface_config);
    defer surface.Unconfigure();

    const wgsl_code = wgpu.ShaderSourceWGSL {
        .code = wgpu.StringView.fromSlice(triange_shader),
        .chain = .{ .sType = .ShaderSourceWGSL }
    };
    const shader_module = try device.CreateShaderModule(&.{
        .nextInChain = &wgsl_code.chain
    });
    defer shader_module.Release();

    const blend_state = wgpu.BlendState{
        .color = .{ 
            .srcFactor = .SrcAlpha,
            .dstFactor = .OneMinusSrcAlpha,
            .operation = .Add,
        },
        .alpha = .{
            .srcFactor = .Zero,
            .dstFactor = .One,
            .operation = .Add
        }
    };
    const zero: u32 = 0;

    const color_target = wgpu.ColorTargetState{
        .format = surface_capabilities.formats[0],
        .blend = &blend_state,
        .writeMask = .All
    };
    
    const render_pipeline = try device.CreateRenderPipeline(&wgpu.RenderPipeline.Descriptor{
        .vertex = .{
            .module = shader_module._impl,
            .entryPoint = wgpu.StringView.fromSlice("vs_main"),
        },
        .primitive = .{
            .topology = .TriangleList,
            .stripIndexFormat = .Undefined,
            .frontFace = .CCW, //counter clockwise
            .cullMode = .None,
            .unclippedDepth = false
        },
        .fragment = &wgpu.FragmentState{
            .module = shader_module._impl,    
            .entryPoint = wgpu.StringView.fromSlice("fs_main"),
            .targetCount = 1,
            .targets = &[1]wgpu.ColorTargetState{ color_target }
        },
        .multisample = .{
            .count = 1,
            .mask = ~zero,
            .alphaToCoverageEnabled = false
        },
    });
    defer render_pipeline.Release();


    while (!window.ShouldClose()) {

        glfw.pollEvents();

        const texture = surface.GetCurrentTexture() catch |err| switch (err){
            error.RecoverableTexture => {

                const size = try window.GetSize();

                surface_config.width = size.width;
                surface_config.height = size.height;

                surface.Configure(&surface_config);

                continue;

            },
            else => {
                return err;
            }

        };
        defer texture.Release();

        const view = try texture.CreateView(&wgpu.Texture.View.Descriptor{
            .label = wgpu.StringView.fromSlice("Surface texture view"),
            .format = texture.GetFormat(),
            .dimension = .@"2D",
            .baseMipLevel = 0,
            .mipLevelCount = 1,
            .baseArrayLayer = 0,
            .arrayLayerCount = 1,
            .aspect = .All,
            .usage = surface_config.usage
        });
        defer view.Release();

        const command_encoder = device.CreateCommandEncoder(&.{ 
            .label = wgpu.StringView.fromSlice("My command Encoder")
        });

        const render_pass_color_attachement = wgpu.RenderPass.ColorAttachment {
            .view = view._impl,
            .resolveTarget = null,
            .loadOp = .Clear,
            .storeOp = .Store,
            .clearValue = .{ .r = 0.9, .g = 0.1, .b = 0.2, .a = 1.0 },
            .depthSlice = .Undefined,
        };

        {
            const render_pass_encoder = try command_encoder.BeginRenderPass(&.{
                .colorAttachmentCount = 1,
                .colorAttachments = &.{render_pass_color_attachement},
                .depthStencilAttachment = null,
                .occlusionQuerySet = null,
                .timestampWrites = null,
            });

            render_pass_encoder.SetPipeline(render_pipeline);
            render_pass_encoder.Draw(3, 1, 0, 0);

            render_pass_encoder.End();
            render_pass_encoder.Release();
        }

        const command_buffer = command_encoder.Finish(&.{});
        command_encoder.Release();

        queue.Submit(&.{command_buffer});
        command_buffer.Release();

        surface.Present();

        _ = device.Poll(false, null);  
    }
    
}
