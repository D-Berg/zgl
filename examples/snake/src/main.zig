const std = @import("std");
const zgl = @import("zgl");
const log = std.log;

const PI = std.math.pi;
const rand = std.crypto.random;

const glfw = zgl.glfw;
const wgpu = zgl.wgpu;

const RENDER_SIZE = 1; // increases render resolution
const WINDOW_WIDTH = 800;
const WINDOW_HEIGHT = 800;

const GRID_SIZE = 32;
const MAX_RGB_VAL = 255;

const square_shader = @embedFile("shaders/square.wgsl");

const Rectangle = struct {
    position: Position = .{ .x = 0, .y = 0},
    dimension: Dim = .{ .width = 400, .height = 400},
    color: Color = .{ .r = 0, .g = 255, .b = 0, .a = 1 },
};

const Circle = struct {
    center: Position,
    radius: f32,
    color: Color,
    segments: usize
};

const Position = struct {
    x: f32,
    y: f32,

    fn Random() Position {

        const position = Position {
            .x = @as(f32, @floatFromInt(rand.intRangeAtMost(u32, 0, 800 / GRID_SIZE - 1) * GRID_SIZE)),
            .y = @as(f32, @floatFromInt(rand.intRangeAtMost(u32, 0, 800 / GRID_SIZE - 1) * GRID_SIZE))
        };

        return position;
    }
};

const Dim = struct {
    width: f32,
    height: f32,
};

const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: f32,

    fn getArray(self: Color) [4]f32 {

        var color_buffer: [4]f32 = undefined;
        const color_fields = @typeInfo(@TypeOf(self)).@"struct".fields;
        inline for (color_fields, 0..) |field, i| {
            const col_val = @field(self, field.name);

            color_buffer[i] = if (i != color_fields.len - 1) 
                @as(f32, @floatFromInt(col_val)) / MAX_RGB_VAL
            else 
                col_val;
        } 

        return color_buffer;

    }
};

var previous_key_state = std.EnumMap(glfw.Key, glfw.KeyState).initFull(glfw.KeyState.Released);

const MAX_SNAKE_LEN = GRID_SIZE * GRID_SIZE;

const Snake = struct {
    positions: [MAX_SNAKE_LEN]Position = [1]Position{ .{ .x = 0, .y = 0 }} ** MAX_SNAKE_LEN,
    old_positions: [MAX_SNAKE_LEN]Position = undefined,
    len: usize = 10,
    direction: Direction,
    allow_move: bool = true,


    fn move(snake: *Snake) void {
        defer snake.allow_move = true;

        @memcpy(snake.old_positions[0..snake.len], snake.positions[0..snake.len]);


        switch (snake.direction) {
            .Up => snake.positions[0].y -= GRID_SIZE,
            .Down => snake.positions[0].y += GRID_SIZE,
            .Left => snake.positions[0].x -= GRID_SIZE,
            .Right => snake.positions[0].x += GRID_SIZE
        }

        if (snake.positions[0].y > WINDOW_HEIGHT) {
            snake.positions[0].y = 0;
        }

        if (snake.positions[0].y < 0) {
            snake.positions[0].y = WINDOW_HEIGHT - 32;
        }

        if (snake.positions[0].x > WINDOW_WIDTH) {
            snake.positions[0].x = 0;
        }

        if (snake.positions[0].x < 0) {
            snake.positions[0].x = WINDOW_WIDTH - 32;
        }

        std.debug.assert(snake.len > 0);
        std.debug.assert(snake.len < MAX_SNAKE_LEN);
        for (1..snake.len + 1) |i| {
            // snake.positions[i].x += d_x;
            snake.positions[i] = snake.old_positions[i - 1];
        }

    }
};

const Food = struct {
    position: Position,

    fn spawn() Food {
        
        const position = Position.Random();

        log.debug("Food pos = {any}", .{position});
    
        return Food {
            .position = position
        };

    }
};

fn isKeyPressed(window: glfw.Window, key: glfw.Key) bool {
    var isPressed: bool = false;

    const just_pressed = glfw.GetKey(window, key);

    if (just_pressed == .Pressed and previous_key_state.get(key).? != .Pressed) {
        isPressed = true;
    }

    const prev = previous_key_state.getPtr(key).?;
    prev.* = just_pressed;

    if (isPressed) log.debug("pressed {s}", .{@tagName(key)});
    return isPressed;

}

const Direction = enum(u2) {
    Up,
    Down,
    Left,
    Right,

    fn Random() Direction {
        return @enumFromInt(rand.int(u2));
    }
};


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
    defer adapter.release();

    if (adapter.GetLimits()) |limits| limits.logLimits();

    const device = try adapter.RequestDevice(null);
    defer device.Release();

    const device_limits = try device.GetLimits();
    device_limits.logLimits();

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
            .buffers = &[1]wgpu.VertexBufferLayout {
                wgpu.VertexBufferLayout{
                    .stepMode = .Vertex,
                    .arrayStride = 6 * @sizeOf(f32), // 2 pos + 4 col
                    .attributeCount = 2,
                    .attributes = &[2]wgpu.VertextAttribute{
                        wgpu.VertextAttribute { // position
                            .format = .Float32x2,
                            .offset = 0,
                            .shaderLocation = 0
                        },
                        wgpu.VertextAttribute { // color
                            .format = .Float32x4,
                            .offset = 2 * @sizeOf(f32),
                            .shaderLocation = 1
                        }
                    }
                }

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

    const vertex_buffer = try device.CreateBuffer(&.{
        .label = wgpu.StringView.fromSlice("vertex buffer"),
        .size = device_limits.limits.maxBufferSize,
        .usage = @intFromEnum(wgpu.Buffer.Usage.Vertex) | 
            @intFromEnum(wgpu.Buffer.Usage.CopyDst)
    });
    defer vertex_buffer.Release();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const arena_allocator = arena.allocator();


    // Game initilisation
    var isPaused: bool = true;

    const inital_direction = Direction.Random();
    var snake = Snake{.direction = inital_direction};
    std.debug.assert(snake.positions.len == MAX_SNAKE_LEN);
    snake.len = 1;
    snake.positions[0] = Position.Random();
    
    log.debug("inital_direction = {}", .{snake.direction});
    log.debug("head pos = {}", .{snake.positions[0]});

    // for (0..snake.len) |i| {
    //     snake.positions[i].x += @floatFromInt(i * GRID_SIZE);
    //     log.debug("snake pos ({}) = {}", .{i, snake.positions[i]});
    // }


    var frame: usize = 0;
    var food = Food.spawn();

    while (!window.ShouldClose()) : ({_ = arena.reset( .retain_capacity ); frame += 1;}) {
        glfw.pollEvents();

        { // update
            if (!isPaused) {

                if (isKeyPressed(window, .D) and snake.direction != .Left and snake.allow_move) {
                    snake.direction = .Right;
                    snake.allow_move = false;
                }
                if (isKeyPressed(window, .A) and snake.direction != .Right and snake.allow_move) {
                    snake.direction = .Left;
                    snake.allow_move = false;
                }
                if (isKeyPressed(window, .W) and snake.direction != .Down and snake.allow_move) {
                    snake.direction = .Up;
                    snake.allow_move = false;
                }
                if (isKeyPressed(window, .S) and snake.direction != .Up and snake.allow_move) {
                    snake.direction = .Down;
                    snake.allow_move = false;
                }

                if (frame % 10 == 0) snake.move();

                const head_pos = snake.positions[0];
                for (1..snake.len) |i| {
                    const body_pos = snake.positions[i];
                    if (head_pos.x == body_pos.x and head_pos.y == body_pos.y) {
                        isPaused = true;
                    }
                }


                if (head_pos.x == food.position.x and head_pos.y == food.position.y) {
                    snake.len += 1;
                    food = Food.spawn();
                }

                if (isKeyPressed(window, .P)) {
                    log.debug("pausing the game", .{});
                    isPaused = true;
                }

            } 

            if (isPaused) {
                if (isKeyPressed(window, .P)) {
                    isPaused = false;
                    log.debug("isPaused = {}", .{isPaused});
                }
                
                // reset 
                if (isKeyPressed(window, .R)) {
                    log.debug("resetting game", .{});
                    isPaused = false;
                    snake.len = 1;
                    food = Food.spawn();
                    snake.positions[0] = Position.Random();
                    snake.direction = Direction.Random();

                    
                    // reset vertex data to 0
                    const zeros = try arena_allocator.alloc(f32, vertex_buffer.GetSize()/@sizeOf(f32));
                    @memset(zeros, 0);
                    queue.WriteBuffer(vertex_buffer, 0, f32, zeros);
                }
            }
            
        }

        { // draw and render

            // draw ==========================================================
            var vertices = std.ArrayList(f32).init(arena_allocator);
            std.debug.assert(vertices.items.len == 0);

            // draw grid brackround
            for (0..GRID_SIZE) |i| {

                for (0..GRID_SIZE) |j| {
                    const color = if ((i + j) % 2 == 0) 
                        Color {.r = 85, .g = 85,.b = 85, .a = 1}
                    else Color {.r = 64, .g = 64,.b = 64, .a = 1};

                    try drawRectangle(&vertices, Rectangle{ 
                        .position = .{ 
                            .x = @as(f32, @floatFromInt(i * GRID_SIZE)), 
                            .y = @as(f32, @floatFromInt(j * GRID_SIZE)) 
                        },
                        .dimension = .{ .width = GRID_SIZE, .height = GRID_SIZE },
                        .color = color

                    });
                }
            }

            // draw head
            try drawRectangle(&vertices, Rectangle{
                .position = snake.positions[0],
                .dimension = .{ .width = GRID_SIZE, .height = GRID_SIZE },
                .color = .{ .r = 0, .g = 0, .b = 255, .a = 1},
            });

            // draw body
            for (1..snake.len) |i| {
                try drawRectangle(&vertices, Rectangle{
                    .position = snake.positions[i],
                    .dimension = .{ .width = GRID_SIZE, .height = GRID_SIZE }, 
                    .color = .{ .r = 255, .g = 0, .b = 0, .a = 1},
                });
            }
            
            // draw food
            try drawRectangle(&vertices, Rectangle{
                .position = food.position,
                .dimension = .{ .width = GRID_SIZE, .height = GRID_SIZE },
                .color = .{ .r = 0, .g = 255, .b = 0, .a = 1 }
            });

            std.debug.assert(vertices.items.len < device_limits.limits.maxBufferSize);
            queue.WriteBuffer(vertex_buffer, 0, f32, vertices.items);
            

            // render ========================================================
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
                rend_pass_enc.Draw(@intCast(vertices.items.len), 1, 0, 0);
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


fn drawRectangle(vertices: *std.ArrayList(f32), rec: Rectangle) !void {

    const color_buffer = rec.color.getArray();

    // TODO : have one buffer, size of all the data and appendSlice once

    const w_width = WINDOW_WIDTH;
    const w_height = WINDOW_HEIGHT;
    const pos = [2]f32{
        2 * (rec.position.x / w_width) - 1,
        1 - 2 * (rec.position.y / w_height)
    };

    const dim = [2]f32{
        2 * rec.dimension.width / w_width,
        2 * rec.dimension.height / w_height
    };

    
    // triangle 1
    try vertices.appendSlice(&pos); // top left
    try vertices.appendSlice(&color_buffer);


    try vertices.appendSlice(&[_]f32{pos[0] + dim[0], pos[1]}); // top right
    try vertices.appendSlice(&color_buffer);

    try vertices.appendSlice(&[_]f32{pos[0] + dim[0], pos[1] - dim[1]}); //bot right
    try vertices.appendSlice(&color_buffer);

    // triangle 2
    try vertices.appendSlice(&pos); // top left
    try vertices.appendSlice(&color_buffer);


    try vertices.appendSlice(&[_]f32{pos[0], pos[1] - dim[1]}); // bot left
    try vertices.appendSlice(&color_buffer);

    try vertices.appendSlice(&[_]f32{pos[0] + dim[0], pos[1] - dim[1]}); // bot right
    try vertices.appendSlice(&color_buffer);

}

fn drawCircle(vertices: *std.ArrayList(f32), circle: Circle) !void {

    const color_buffer = circle.color.getArray();

    const step_size = 2 * PI / @as(f32, @floatFromInt(circle.segments));

    const r = 2 * circle.radius / std.math.sqrt(
        WINDOW_WIDTH * WINDOW_WIDTH + WINDOW_HEIGHT + WINDOW_HEIGHT
    );

    for (0..circle.segments + 1) |segment| {
        const seg_f32 = @as(f32, @floatFromInt(segment));

        const angles = [2]f32{
            step_size * seg_f32, 
            step_size * (seg_f32 + 1)
        };
        
        // center
        try vertices.appendSlice(&[_]f32{ 0, 0 });
        try vertices.appendSlice(&color_buffer); 


        try vertices.appendSlice(&[_]f32{ 
            r * @cos(angles[0]), 
            r * @sin(angles[0])
        });
        try vertices.appendSlice(&color_buffer);

        
        try vertices.appendSlice(&[_]f32{ 
            r * @cos(angles[1]), 
            r * @sin(angles[1])
        });
        try vertices.appendSlice(&color_buffer);



    }

    // try vertices.appendSlice(&[_]f32{ 0, 0});
    // try vertices.appendSlice(&color_buffer);
    //
    // try vertices.appendSlice(&[_]f32{ 1, 0});
    // try vertices.appendSlice(&color_buffer);
    //
    // try vertices.appendSlice(&[_]f32{ 0, 1});
    // try vertices.appendSlice(&color_buffer);

    // try vertices.appendSlice(&[_]f32{ -1, 0});
    // try vertices.appendSlice(&color_buffer);
    //
    // try vertices.appendSlice(&[_]f32{ 0, -1});
    // try vertices.appendSlice(&color_buffer);
    //
    // try vertices.appendSlice(&[_]f32{ 1, 0});
    // try vertices.appendSlice(&color_buffer);


// 0.0,  0.0,  // Center
//     1.0,  0.0,  // Right
//     0.0,  1.0,  // Top
//    -1.0,  0.0,  // Left
//     0.0, -1.0,  // Bottom
//     1.0,  0.0,  // Close circle (repeat first vertex)

}
