const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const log = std.log.scoped(.main);
const zgl = @import("zgl");
const wgpu = zgl.wgpu;
const glfw = zgl.glfw;
const builtin = @import("builtin");
const os_tag = builtin.os.tag;
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();
const emscripten = std.os.emscripten;

const WINDOW_WIDTH = 400;
const WINDOW_HEIGHT = 400;
const triange_shader = @embedFile("shaders/triangle.wgsl");

const App = struct {
    window: glfw.Window,
    instance: *const wgpu.Instance,
    surface: *const wgpu.Surface,
    adapter: *const wgpu.Adapter,
    device: *const wgpu.Device,
    queue: *const wgpu.Queue,
    shader_module: *const wgpu.ShaderModule,
    render_pipeline: *const wgpu.RenderPipeline,
    allocator: Allocator,

    fn init(allocator: Allocator) !App {
        try glfw.init();
        glfw.Window.hint(.{ .client_api = .NO_API, .resizable = true });
        const window = try glfw.Window.Create(WINDOW_WIDTH, WINDOW_HEIGHT, "My window");

        const instance = try wgpu.createInstance(null);

        const surface = try glfw.GetWGPUSurface(window, instance);

        const adapter = try instance.requestAdapter(&.{
            .compatible_surface = surface,
        });

        const surface_capabilities = surface.GetCapabilities(adapter);
        defer surface_capabilities.FreeMembers();

        surface_capabilities.logCapabilites();

        const device = try adapter.RequestDevice(null);

        const queue = try device.GetQueue();

        var surface_config = wgpu.SurfaceConfiguration{
            .device = device,
            .width = WINDOW_WIDTH,
            .height = WINDOW_HEIGHT,
            .usage = .RenderAttachment,
            .format = surface.GetPreferredFormat(adapter),
            .presentMode = .Undefined,
            .alphaMode = .Auto,
        };
        surface.configure(&surface_config);

        const wgsl_code = wgpu.ShaderSourceWGSL{
            .code = .fromSlice(triange_shader),
            .chain = .{ .next = null, .sType = .ShaderSourceWGSL },
        };

        const shader_module = try device.CreateShaderModule(
            &.{ .nextInChain = &wgsl_code.chain },
        );

        const blend_state = wgpu.BlendState{
            .color = .{
                .srcFactor = .One,
                .dstFactor = .Zero,
                .operation = .Add,
            },
            .alpha = .{
                .srcFactor = .One,
                .dstFactor = .OneMinusSrcAlpha,
                .operation = .Add,
            },
        };
        _ = blend_state;

        const zero: u32 = 0;

        const color_target = wgpu.ColorTargetState{
            .format = surface.GetPreferredFormat(adapter),
            .blend = null,
            .writeMask = .All,
        };

        const render_pipeline = try device.CreateRenderPipeline(&wgpu.RenderPipelineDescriptor{
            .vertex = wgpu.VertexState{
                .module = shader_module,
                .entryPoint = "vs_main",
            },
            .primitive = wgpu.PrimitiveState{
                .topology = .TriangleList,
                .stripIndexFormat = .Undefined,
                .frontFace = .CCW, //counter clockwise
                .cullMode = .None,
            },
            .fragment = &wgpu.FragmentState{
                .module = shader_module,
                .entryPoint = .fromSlice("fs_main"),
                .targetCount = 1,
                .targets = &[1]wgpu.ColorTargetState{color_target},
            },
            .multisample = wgpu.MultiSampleState{
                .count = 1,
                .mask = ~zero,
                .alphaToCoverageEnabled = false,
            },
        });

        return .{
            .window = window,
            .instance = instance,
            .surface = surface,
            .adapter = adapter,
            .device = device,
            .queue = queue,
            .shader_module = shader_module,
            .render_pipeline = render_pipeline,
            .allocator = allocator,
        };
    }

    fn deinit(self: *App) void {
        defer glfw.terminate();
        defer self.window.destroy();
        defer self.instance.release();
        defer self.surface.release();
        defer self.adapter.release();
        defer self.device.release();
        defer self.queue.release();
        defer self.shader_module.release();
        defer self.render_pipeline.Release();
    }

    fn c_loop(ctx: ?*anyopaque) callconv(.C) void {
        const self = @as(*App, @alignCast(@ptrCast(ctx)));

        self.loop() catch |err| {
            log.err("{s}", .{@errorName(err)});
            return;
        };
    }

    fn loop(self: *App) !void {
        const surface = self.surface;
        const device = self.device;
        const queue = self.queue;
        const render_pipeline = self.render_pipeline;

        const texture = try surface.GetCurrentTexture();
        defer texture.release();

        const view = try texture.CreateView(&wgpu.TextureViewDescriptor{
            .label = .fromSlice("Surface texture view"),
            .format = texture.GetFormat(),
            .dimension = .@"2D",
            .baseMipLevel = 0,
            .mipLevelCount = 1,
            .baseArrayLayer = 0,
            .arrayLayerCount = 1,
            .aspect = .All,
            .usage = .RenderAttachment,
        });
        defer view.release();

        const command_encoder = try device.CreateCommandEncoder(
            &.{ .label = .fromSlice("My command Encoder") },
        );

        const render_pass_color_attachement = wgpu.RenderPassColorAttachment{
            .view = view,
            .resolveTarget = null,
            .loadOp = .Clear,
            .storeOp = .Store,
            .clearValue = .{ .r = 0, .g = 0, .b = 0, .a = 1.0 },
            .depthSlice = .Undefined,
        };

        {
            const render_pass_encoder = try command_encoder.BeginRenderPass(
                &wgpu.RenderPassDescriptor{
                    .colorAttachmentCount = 1,
                    .colorAttachments = &[1]wgpu.RenderPassColorAttachment{
                        render_pass_color_attachement,
                    },
                    .depthStencilAttachment = null,
                    .occlusionQuerySet = null,
                    .timestampWrites = null,
                },
            );
            render_pass_encoder.setPipeline(render_pipeline);
            render_pass_encoder.draw(3, 1, 0, 0);

            render_pass_encoder.end();
            render_pass_encoder.release();
        }

        const command_buffer = try command_encoder.finish(&.{ .label = .fromSlice("cmd buffer") });
        command_encoder.release();

        queue.submit(&.{command_buffer});
        command_buffer.release();

        if (os_tag != .emscripten) {
            surface.present();
            _ = device.poll(false, null);
        }
    }

    fn shouldClose(self: App) bool {
        return self.window.ShouldClose();
    }
};

pub fn main() !void {
    try stdout.print("hello from zig\n", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var app = try App.init(allocator);
    defer app.deinit();

    log.debug("{s}", .{triange_shader});

    if (os_tag == .emscripten) {
        emscripten.emscripten_set_main_loop_arg(App.c_loop, &app, 0, @intFromBool(true));
    } else {
        while (!app.shouldClose()) {
            glfw.pollEvents();
            try App.loop(&app);
        }
    }
}
