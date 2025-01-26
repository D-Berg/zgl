const std = @import("std");
const zgl = @import("zgl");
const log = std.log;

const rand = std.crypto.random;

const glfw = zgl.glfw;
const wgpu = zgl.wgpu;

const RENDER_SIZE = 1;
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 800;

const GRID_SIZE = 16;

const square_shader = @embedFile("shaders/square.wgsl");

const Rectangle = struct {
    position: Position = .{ .x = 0, .y = 0},
    dimension: Dim = .{ .width = 400, .height = 400},
    color: Color = .{ .r = 0, .g = 1, .b = 0, .a = 1 },
};

const Position = struct {
    x: f32,
    y: f32
};

const Dim = struct {
    width: f32,
    height: f32,
};

const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32
};

var previous_key_state = std.EnumMap(glfw.Key, glfw.KeyState).initFull(glfw.KeyState.Released);

const MAX_SNAKE_LEN = 10;

const Snake = struct {
    positions: [MAX_SNAKE_LEN][2]f32,
    len: 1,
};

fn isKeyPressed(window: glfw.Window, key: glfw.Key) bool {
    var isPressed: bool = false;

    const just_pressed = glfw.GetKey(window, key);

    if (just_pressed == .Pressed and previous_key_state.get(key).? != .Pressed) {
        isPressed = true;
    }

    const prev = previous_key_state.getPtr(key).?;
    prev.* = just_pressed;

    return isPressed;

}

const Direction = enum {
    Up,
    Down,
    Left,
    Right
};

fn moveSnake(curr_pos_idx: *usize, snake: []u32, direction: Direction) void {

    switch (direction) {

        .Up => {
            if (curr_pos_idx.* + GRID_SIZE < snake.len - 1) {
                const next_pos = curr_pos_idx.* + GRID_SIZE;
                snake[next_pos] = @intFromBool(true);
                snake[curr_pos_idx.*]  = @intFromBool(false);

                curr_pos_idx.* = next_pos;
            } else {
                const next_pos = curr_pos_idx.* - (GRID_SIZE - 1) * GRID_SIZE;
                snake[next_pos] = @intFromBool(true);
                snake[curr_pos_idx.*]  = @intFromBool(false);

                curr_pos_idx.* = next_pos;

            }
        },
        .Down => {

            if (curr_pos_idx.* > GRID_SIZE - 1) {
                const next_pos = curr_pos_idx.* - GRID_SIZE;
                snake[next_pos] = @intFromBool(true);
                snake[curr_pos_idx.*]  = @intFromBool(false);

                curr_pos_idx.* = next_pos;
            } else {
                const next_pos = curr_pos_idx.* + (GRID_SIZE - 1) * GRID_SIZE;
                snake[next_pos] = @intFromBool(true);
                snake[curr_pos_idx.*]  = @intFromBool(false);

                curr_pos_idx.* = next_pos;
            }

        },
        .Left => {
            const next_pos = if (curr_pos_idx.* % GRID_SIZE == 0) 
                curr_pos_idx.* + GRID_SIZE - 1
            else 
                curr_pos_idx.* - 1;

            snake[next_pos] = @intFromBool(true);
            snake[curr_pos_idx.*] = @intFromBool(false);

            curr_pos_idx.* = next_pos;

        },
        .Right => {
            var next_pos = curr_pos_idx.* + 1;
            if (next_pos % GRID_SIZE == 0) {
                next_pos = curr_pos_idx.* + 1 - GRID_SIZE;
            }
            snake[next_pos] = @intFromBool(true);
            snake[curr_pos_idx.*] = @intFromBool(false);

            curr_pos_idx.* = next_pos;

        }
    }


    log.debug("pos: {}", .{curr_pos_idx.*});

}

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


    const window_array = [2]f32{ WINDOW_WIDTH, WINDOW_HEIGHT };

    const window_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("uniform buffer"),
        .usage = @intFromEnum(wgpu.Buffer.Usage.Uniform) | 
            @intFromEnum(wgpu.Buffer.Usage.CopyDst),
        .size = @sizeOf(@TypeOf(window_array))
    });
    defer window_buffer.Release();
    queue.WriteBuffer(window_buffer,0, f32, window_array[0..]);


    var rectangles: [MAX_SNAKE_LEN]Rectangle = undefined;
    for (0..rectangles.len) |i| rectangles[i] = Rectangle{};
    rectangles[1] = Rectangle{
        .position = .{ .x = 400, .y = 400},
        .dimension = .{ .width = 200, .height = 300 },
        .color = .{ .r = 1, .g = 0, .b = 0, .a = 1 },
    };
    const rectangles_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("rectangles buffer"),
        .usage = @intFromEnum(wgpu.Buffer.Usage.Storage) | 
            @intFromEnum(wgpu.Buffer.Usage.CopyDst),
        .size = @sizeOf(@TypeOf(rectangles)),
    });
    defer rectangles_buffer.Release();
    queue.WriteBuffer(rectangles_buffer, 0, Rectangle, rectangles[0..]);


    log.debug("{}", .{@sizeOf(@TypeOf(rectangles))});

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
            // .bufferCount = 1,
            // .buffers = &[1]wgpu.VertexBufferLayout {
            //     wgpu.VertexBufferLayout{
            //         .stepMode = .Vertex,
            //         .arrayStride = 2 * @sizeOf(f32),
            //         .attributeCount = 1,
            //         .attributes = &[1]wgpu.VertextAttribute{
            //             wgpu.VertextAttribute{
            //                 .format = .Float32x2,
            //                 .offset = 0,
            //                 .shaderLocation = 0
            //             }
            //         }
            //     }
            //
            // }
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
                .buffer = window_buffer._impl,
                .size = window_buffer.GetSize()
            },
            wgpu.BindGroup.Entry{
                .binding = 1,
                .buffer = rectangles_buffer._impl,
                .size = rectangles_buffer.GetSize()
            },
        }
    });
    defer bind_group.Release();


    var frame: usize = 0;
    // var curr_pos_idx: usize = rand.intRangeAtMost(usize, 0, GRID_SIZE * GRID_SIZE - 1);
    // var direction: Direction = .Right;
    while (!window.ShouldClose()) : (frame += 1) {
        glfw.pollEvents();

        { // update
            
            // if (isKeyPressed(window, .D) and direction != .Left) direction = .Right;
            //
            // if (isKeyPressed(window, .A) and direction != .Right) direction = .Left;
            //
            // if (isKeyPressed(window, .W) and direction != .Down) direction = .Up;
            //
            // if (isKeyPressed(window, .S) and direction != .Up) direction = .Down;
            //
            // if (frame % 10 == 0) moveSnake(&curr_pos_idx, &snake, direction);
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
                // rend_pass_enc.setVertexBuffer(0, vertex_buffer, 0);
                rend_pass_enc.setBindGroup(0, bind_group, &[_]u32{});
                rend_pass_enc.Draw(6, 2, 0, 0);
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
