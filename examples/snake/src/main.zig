const std = @import("std");
const zgl = @import("zgl");

const glfw = zgl.glfw;
const wgpu = zgl.wgpu;

const RENDER_SIZE = 2;
const WINDOW_WIDTH = 768 + 32;
const WINDOW_HEIGHT = 768 + 32;

const GRID_SIZE = 32;

const square_shader = @embedFile("shaders/square.wgsl");


var previous_key_state = std.EnumMap(glfw.Key, glfw.KeyState).initFull(glfw.KeyState.Released);

pub fn main() !void {

    try glfw.init();
    defer glfw.terminate();

    glfw.Window.hint(.{ .resizable = false, .client_api = .NO_API });

    const window = try glfw.Window.Create(WINDOW_WIDTH, WINDOW_HEIGHT, "Snake");
    defer window.destroy();


    const instance = try wgpu.Instance.Create(null);
    defer instance.Release();

    const surface = try glfw.GetWGPUSurface(window, instance);
    defer surface.Release();

    const adapter = try instance.RequestAdapter(&.{.compatibleSurface = surface._inner});
    defer adapter.Release();

    const device = try adapter.RequestDevice(null);
    defer device.Release();

    const queue = try device.GetQueue();
    defer queue.Release();

    const surface_pref_format = surface.GetPreferredFormat(adapter);

    const surface_conf = wgpu.Surface.Configuration{
        .device = device._inner,
        .format = surface_pref_format,
        .width = RENDER_SIZE * WINDOW_WIDTH,
        .height = RENDER_SIZE * WINDOW_HEIGHT,
        .presentMode = .Fifo,
        .alphaMode = .Auto,
        .usage = .RenderAttachment,
    };

    surface.Configure(&surface_conf);
    defer surface.Unconfigure();

    const square_vertices = [12]f32 {
        // X, Y
        -0.8, -0.8, // Triangle 1 (Blue)
        0.8, -0.8,
        0.8,  0.8,

        -0.8, -0.8, // Triangle 2 (Red)
        0.8,  0.8,
        -0.8,  0.8,
    };

    const vertex_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("vertex_buffer"),
        .usage = @intFromEnum(wgpu.Buffer.Usage.Vertex) |
            @intFromEnum(wgpu.Buffer.Usage.CopyDst),
        .size = @sizeOf(@TypeOf(square_vertices)) 
    });
    defer vertex_buffer.Release();

    queue.WriteBuffer(vertex_buffer, 0, f32, square_vertices[0..]);

    const uniform_array = [2]f32{ GRID_SIZE, GRID_SIZE };

    const uniform_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("uniform buffer"),
        .usage = @intFromEnum(wgpu.Buffer.Usage.Uniform) | 
            @intFromEnum(wgpu.Buffer.Usage.CopyDst),
        .size = @sizeOf(@TypeOf(uniform_array))
    });
    defer uniform_buffer.Release();


    var snake: [GRID_SIZE * GRID_SIZE]u32 = undefined;
    for (0..snake.len) |i| snake[i] = @intFromBool(false);
    snake[0] = @intFromBool(true); // set head to active

    const snake_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("snake buffer"),
        .usage = @intFromEnum(wgpu.Buffer.Usage.Storage) | 
            @intFromEnum(wgpu.Buffer.Usage.CopyDst),
        .size = @sizeOf(@TypeOf(snake)),
    });
    defer snake_buffer.Release();

    queue.WriteBuffer(uniform_buffer,0, f32, uniform_array[0..]);
    queue.WriteBuffer(snake_buffer, 0, u32, snake[0..]);


    const shader_code = wgpu.ShaderSourceWGSL{
        .code = wgpu.StringView.fromSlice(square_shader),
        .chain = .{ .sType = .ShaderSourceWGSL }
    };

    const shader = try device.CreateShaderModule(&.{ .nextInChain = &shader_code.chain });
    defer shader.Release();

    const render_pipeline = try device.CreateRenderPipeline(&wgpu.RenderPipeline.Descriptor{
        .label = wgpu.StringView.fromSlice("render pipe"),
        .vertex = .{
            .module = shader._impl,
            .entryPoint = wgpu.StringView.fromSlice("vs_main"),
            .bufferCount = 1,
            .buffers = &[1]wgpu.VertexBufferLayout{
                // grid?
                wgpu.VertexBufferLayout{
                    .stepMode = .Vertex,
                    .arrayStride = 2 * @sizeOf(f32),
                    .attributeCount = 1,
                    .attributes = &[1]wgpu.VertextAttribute{
                        wgpu.VertextAttribute{
                            .format = .Float32x2,
                            .offset = 0,
                            .shaderLocation = 0
                        },
                    }
                },
            }
        },
        .multisample = .{
            .mask = ~@as(u32, 0),
            .count = 1,
            .alphaToCoverageEnabled = false,
        },
        .fragment = &wgpu.FragmentState{
            .module = shader._impl,
            .entryPoint = wgpu.StringView.fromSlice("fs_main"),
            .targetCount = 1,
            .targets = &[1]wgpu.ColorTargetState{ 
                wgpu.ColorTargetState{
                    .format = surface_pref_format,
                    .writeMask = .All,
                    .blend = &wgpu.BlendState{
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
                    }
                },
            },
        },
        .primitive = .{ 
            .topology = .TriangleList,
        }
        
    });
    defer render_pipeline.Release();


    const layout = try render_pipeline.GetBindGroupLayout(0);
    defer layout.Release();

    const bind_group = try device.CreateBindGroup(&.{
        .label = wgpu.StringView.fromSlice("bind group"),
        .layout = layout,
        .entryCount = 2,
        .entries = &[2]wgpu.BindGroup.Entry {
            wgpu.BindGroup.Entry{
                .binding = 0,
                .buffer = uniform_buffer._impl,
                .size = uniform_buffer.GetSize()
            },
            wgpu.BindGroup.Entry{
                .binding = 1,
                .buffer = snake_buffer._impl,
                .size = snake_buffer.GetSize()
            },
        }
    });
    defer bind_group.Release();


    var i: usize = 0;
    while (!window.ShouldClose()) {
        glfw.pollEvents();

        { // update
            
            if (i == snake.len) {
                i = 0; // wouldnt wanna overflow right
                @memset(&snake, 0);
            }
            snake[i] = @intFromBool(true);

            const just_pressed = glfw.GetKey(window, .D);

            if (just_pressed == .Pressed and previous_key_state.get(.D).? != .Pressed) {
                i += 1;
            }

            const prev = previous_key_state.getPtr(.D).?;
            prev.* = just_pressed;

            queue.WriteBuffer(snake_buffer, 0, u32, snake[0..]);
        }

        { // Render
            const texture = try surface.GetCurrentTexture();
            defer texture.Release();

            const view = try texture.CreateView(&.{
                .format = surface_pref_format,
                .dimension = .@"2D",
                .baseMipLevel = 0,
                .mipLevelCount = 1,
                .baseArrayLayer = 0,
                .arrayLayerCount = 1,
                .usage = surface_conf.usage,
                .aspect = .All,
            });
            defer view.Release();

            const command_encoder = device.CreateCommandEncoder(&.{});
            defer command_encoder.Release();
            
            {

                const render_pass_desc = wgpu.RenderPass.Descriptor{
                    .colorAttachmentCount = 1,
                    .colorAttachments = &[1]wgpu.RenderPass.ColorAttachment{
                        wgpu.RenderPass.ColorAttachment{
                            .clearValue = .{ .r = 0, .g = 0, .b = 0, .a = 1},
                            .loadOp = .Clear,
                            .storeOp = .Store,
                            .view = view._impl
                        },
                    },
                };

                const rend_pass_enc = try command_encoder.BeginRenderPass(&render_pass_desc);
                defer rend_pass_enc.Release();

                rend_pass_enc.SetPipeline(render_pipeline);
                rend_pass_enc.setVertexBuffer(0, vertex_buffer, 0);
                rend_pass_enc.setBindGroup(0, bind_group, &[_]u32{});

                rend_pass_enc.Draw(6, GRID_SIZE * GRID_SIZE, 0, 0);
                rend_pass_enc.End();
            }


            const command_buffer = command_encoder.Finish(&.{});
            defer command_buffer.Release();

            queue.Submit(&[1]wgpu.CommandBuffer{ command_buffer });

            surface.Present();
            _ = device.Poll(false, null);

        }
    }

}
