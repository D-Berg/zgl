const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const log = std.log.scoped(.@"main");
const zgl = @import("zgl");
const wgpu = zgl.wgpu;
const glfw = zgl.glfw;
const builtin = @import("builtin");
const os_tag = builtin.os.tag;
const Allocator = std.mem.Allocator;

const stdout = std.io.getStdOut().writer();
const emscripten = std.os.emscripten;

const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 600;
const triange_shader = @embedFile("shaders/triangle.wgsl");

const App = struct {
    window: glfw.Window,
    instance: wgpu.Instance,
    surface: wgpu.Surface,
    adapter: wgpu.Adapter,
    device: wgpu.Device,
    queue: *wgpu.Queue,
    shader_module: wgpu.ShaderModule,
    render_pipeline: wgpu.RenderPipeline, 
    allocator: Allocator,

    fn init(allocator: Allocator) !App {

        try glfw.init();
        glfw.Window.hint(.{ .client_api = .NO_API, .resizable = true });
        const window = try glfw.Window.Create(WINDOW_WIDTH, WINDOW_HEIGHT, "My window");

        const instance = try wgpu.Instance.Create(null);

        const surface = try glfw.GetWGPUSurface(window, instance);


        const adapter = try instance.RequestAdapter(&.{
            .compatibleSurface = surface._inner,
        });


        const surface_capabilities = surface.GetCapabilities(adapter);
        defer surface_capabilities.FreeMembers();

        surface_capabilities.logCapabilites();

        const device = try adapter.RequestDevice(null);

        const queue = try device.GetQueue();

        var surface_config = wgpu.Surface.Configuration{
            .device = device._inner,
            .width = WINDOW_WIDTH,
            .height = WINDOW_HEIGHT,
            .usage = .RenderAttachment,
            .format = surface.GetPreferredFormat(adapter),
            .presentMode = .Undefined,
            .alphaMode = .Auto
        };
        surface.Configure(&surface_config);

        const code_desc = wgpu.ShaderModule.WGSLDescriptor{
            .code = triange_shader,
            .chain = .{ .next = null, .sType = .ShaderModuleWGSLDescriptor }
        };
        const shader_module = try device.CreateShaderModule(&.{
            .nextInChain = &code_desc.chain
        });

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
            .format = surface.GetPreferredFormat(adapter),
            .blend = &blend_state,
            .writeMask = .All
        };

        const render_pipeline = try device.CreateRenderPipeline(&.{
            .vertex = .{
                .module = shader_module._impl,
                .entryPoint = "vs_main",
            },
            .primitive = .{
                .topology = .TriangleList,
                .stripIndexFormat = .Undefined,
                .frontFace = .CCW, //counter clockwise
                .cullMode = .None,
            },
            .fragment = &.{
                .module = shader_module._impl,    
                .entryPoint = "fs_main",
                .targetCount = 1,
                .targets = &[1]wgpu.ColorTargetState{ color_target }
            },
            .multisample = .{
                .count = 1,
                .mask = ~zero,
                .alphaToCoverageEnabled = false
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
        defer self.instance.Release();
        defer self.surface.Release();
        defer self.adapter.Release();
        defer self.device.Release();
        defer self.queue.Release();
        defer self.shader_module.Release();
        defer self.render_pipeline.Release();

    }

    fn loop(ctx: ?*anyopaque) callconv(.C) void {
        const self = @as(*App, @alignCast(@ptrCast(ctx)));

        const surface = self.surface;
        const device = self.device;
        const queue = self.queue;
        const render_pipeline = self.render_pipeline;

        const texture = surface.GetCurrentTexture() catch {
            @panic("failed to get texture");
        };
        defer texture.Release();

        const view = texture.CreateView(&.{
            .label = "Surface texture view",
            .format = texture.GetFormat(),
            .dimension = .@"2D",
            .baseMipLevel = 0,
            .mipLevelCount = 1,
            .baseArrayLayer = 0,
            .arrayLayerCount = 1,
            .aspect = .All,
        }) catch { 
            @panic("failed to get view");
        };
        defer view.Release();


        const command_encoder = device.CreateCommandEncoder(&.{ .label = "My command Encoder" });

        const render_pass_color_attachement = wgpu.RenderPass.ColorAttachment {
            .view = view._impl,
            .resolveTarget = null,
            .loadOp = .Clear,
            .storeOp = .Store,
            .clearValue = .{ .r = 0.9, .g = 0.1, .b = 0.2, .a = 1.0 },
            .depthSlice = .Undefined,
        };

        {
            const render_pass_encoder = command_encoder.BeginRenderPass(&.{
                .colorAttachmentCount = 1,
                .colorAttachments = &.{render_pass_color_attachement},
                .depthStencilAttachment = null,
                .occlusionQuerySet = null,
                .timestampWrites = null,
            }) catch {
                @panic("Failed to get render pass encoder");
            };

            render_pass_encoder.SetPipeline(render_pipeline);
            render_pass_encoder.Draw(3, 1, 0, 0);

            render_pass_encoder.End();
            render_pass_encoder.Release();
        }


        const command_buffer = command_encoder.Finish(&.{.label = "cmd buffer"});
        command_encoder.Release();

        queue.Submit(&.{command_buffer});
        command_buffer.Release();

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

    if (os_tag == .emscripten) {
        emscripten.emscripten_set_main_loop_arg(App.loop, &app, 0, @intFromBool(true));
    } else {
        while (!app.shouldClose()) {
            glfw.pollEvents();
        }
    }
    
}

