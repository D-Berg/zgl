const std = @import("std");
const zgl = @import("zgl");
const log = std.log;
const glfw = zgl.glfw;
const wgpu = zgl.wgpu;
const rand = std.crypto.random;
const assert = std.debug.assert;

const StringView = wgpu.StringView;

const sprite_code = @embedFile("shaders/sprite.wgsl");
const update_sprite_code = @embedFile("shaders/UpdateSprites.wgsl");

const NUM_PARTICLES = 3000;
const PARTICLES_PER_GROUP = 64;


const RENDER_SCALE = 2;
const WIDTH = 600;
const HEIGHT = 600;

const SimParams = struct {
    delta_t: f32 = 0.04,
    rule1_distance: f32 = 0.10,
    rule2_distance: f32 = 0.025,
    rule3_distance: f32 = 0.025,
    rule1_scale: f32 = 0.02,
    rule2_scale: f32 = 0.05,
    rule3_scale: f32 = 0.005
};

pub fn main() !void {


    try glfw.init();
    defer glfw.terminate();

    glfw.Window.hint(.{ .client_api = .NO_API, .resizable = false});
    const window = try glfw.Window.Create(WIDTH, HEIGHT, "Compute Boids");
    defer window.destroy();

    const instance = try wgpu.CreateInstance(null);
    defer instance.release();

    const surface = try glfw.GetWGPUSurface(window, instance);
    defer surface.release();


    const adapter = try instance.RequestAdapter(null);
    defer adapter.release();

    const adapter_features = adapter.GetFeatures();
    defer adapter_features.deinit();

    log.info("adapter features:\n{}", .{adapter_features});

    var hasTimeStampQuery = false;
    for (adapter_features.toSlice()) |feature| {
        if (feature == .TimestampQuery) {
            hasTimeStampQuery = true;
            break;
        }
    }

    const surface_capabilities = surface.GetCapabilities(adapter);
    defer surface_capabilities.FreeMembers();

    surface_capabilities.logCapabilites();

    const device = try adapter.RequestDevice(null);
    defer device.release();

    const queue = try device.GetQueue();
    defer queue.release();

    const prefered_format = surface_capabilities.formats[0];
    const surface_config = wgpu.SurfaceConfiguration{
        .device = device,
        .format = prefered_format,
        .width = RENDER_SCALE * WIDTH,
        .height = RENDER_SCALE * HEIGHT,
        .usage = .RenderAttachment,
        .alphaMode = .Auto,
        .presentMode = .Fifo
    };
    surface.configure(&surface_config);
    defer surface.unconfigure();

    
    // Render Pipeline =======================================================
    const sprite_wgsl = wgpu.ShaderSourceWGSL{
        .code = wgpu.StringView.fromSlice(sprite_code),
        .chain = .{ .sType = .ShaderSourceWGSL }
    };

    const sprite_shader_module = try device.CreateShaderModule(&.{
        .nextInChain = &sprite_wgsl.chain
    });
    defer sprite_shader_module.release();

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


    const color_target = wgpu.ColorTargetState{
        .format = prefered_format,
        .blend = &blend_state,
        .writeMask = .All
    };

    const render_pipeline = try device.CreateRenderPipeline(&wgpu.RenderPipelineDescriptor{
        .vertex = .{
            .module = sprite_shader_module,
            .entryPoint = "vs_main",
            .buffers = &[2]wgpu.VertexBufferLayout{
                // instanced particles buffer
                wgpu.VertexBufferLayout {
                    .arrayStride = 4 * 4,
                    .stepMode = .Instance,
                    .attributeCount = 2,
                    .attributes = &[2]wgpu.VertextAttribute{
                        // instance position
                        .{
                            .shaderLocation = 0,
                            .offset = 0,
                            .format = .Float32x2
                        },
                        // instance velocity
                        .{
                            .shaderLocation = 1,
                            .offset = 2 * 4,
                            .format = .Float32x2
                        }
                    }
                },
                // vertex buffer
                .{
                    .arrayStride = 2 * 4,
                    .stepMode = .Vertex,
                    .attributeCount = 1,
                    .attributes = &[1]wgpu.VertextAttribute{
                        .{
                            .shaderLocation = 2,
                            .offset = 0,
                            .format = .Float32x2
                        }
                    }

                }
            }
        },
        .multisample = .{ 
            .mask = ~@as(u32, 0),
            .count = 1,
            .alphaToCoverageEnabled = false
        },
        .fragment = &.{
            .module = sprite_shader_module,    
            .entryPoint = StringView.fromSlice("fs_main"),
            .targetCount = 1,
            .targets = &[1]wgpu.ColorTargetState{ color_target }
        },
        .primitive = .{ 
            .topology = .TriangleList,
        }
    });
    defer render_pipeline.Release();
    // =======================================================================

    // Compute Pipeline ======================================================
    const update_sprite_wgsl_desc = wgpu.ShaderSourceWGSL{
        .code = StringView.fromSlice(update_sprite_code),
        .chain = .{ .sType = .ShaderSourceWGSL }
    };
    const update_sprite_shader_module = try device.CreateShaderModule(&.{
        .nextInChain = &update_sprite_wgsl_desc.chain
    });
    defer update_sprite_shader_module.release();
    //
    const compute_pipeline = try device.CreateComputePipeline(&.{
        .compute = .{
            .module = update_sprite_shader_module,
            .entryPoint = StringView.fromSlice("main")
        }
    });
    defer compute_pipeline.release();
    // =======================================================================



    // Storage for timestap query
    const query_set: wgpu.QuerySet = undefined;
    _ = query_set;
    // timestamps are resolved into this buffer
    const resolve_buffer: wgpu.Buffer = undefined;
    _ = resolve_buffer;

    const vertex_buffer_data = [_]f32{
        -0.01, -0.02, 0.01,
        -0.02, 0.0, 0.02
    };

    const sprite_vertex_buffer = try device.CreateBuffer(&.{
        .label = StringView.fromSlice("sprite buff"),
        .usage = @intFromEnum(wgpu.BufferUsage.Vertex),
        .size = @sizeOf(@TypeOf(vertex_buffer_data)),
        .mappedAtCreation = true
    });
    defer sprite_vertex_buffer.release();

    const sprite_range = try sprite_vertex_buffer.getMappedRange(f32, 0, @sizeOf(@TypeOf(vertex_buffer_data)));
    assert(sprite_range.len == vertex_buffer_data.len);
    for (0..sprite_range.len) |i| {
        sprite_range[i] = vertex_buffer_data[i];
    }
    sprite_vertex_buffer.unmap();

    
    const sim_param_buffer = try device.CreateBuffer(&.{
        .label = StringView.fromSlice("sim params"),
        .size = @sizeOf(SimParams),
        .usage = @intFromEnum(wgpu.BufferUsage.Uniform) | 
            @intFromEnum(wgpu.BufferUsage.CopyDst)
    });
    defer sim_param_buffer.release();

    const sim_params = SimParams{};
    queue.WriteBuffer(
        sim_param_buffer, 
        0, 
        f32, 
        &[_]f32{
            sim_params.delta_t,
            sim_params.rule1_distance,
            sim_params.rule2_distance,
            sim_params.rule3_distance,
            sim_params.rule1_scale,
            sim_params.rule2_scale,
            sim_params.rule3_scale,
        }
    );

    var initial_particle_data = [_]f32{0} ** (4 * NUM_PARTICLES);
    for (0..NUM_PARTICLES) |i| {
        initial_particle_data[4 * i + 0] = 2 * (rand.float(f32) - 0.5); // x-pos
        initial_particle_data[4 * i + 1] = 2 * (rand.float(f32) - 0.5); // y-pos
        // setting them to 0 fixes stuck boids
        initial_particle_data[4 * i + 2] = 0; // 2 * (rand.float(f32) - 0.5) * 0.1;
        initial_particle_data[4 * i + 3] = 0; //2 * (rand.float(f32) - 0.5) * 0.1;

    }

    var particle_buffers: [2]wgpu.Buffer = undefined;

    for (0..particle_buffers.len) |i| {
        particle_buffers[i] = try device.CreateBuffer(&.{
            .label = StringView.fromSlice("particle_buffer"),
            .size = @sizeOf(@TypeOf(initial_particle_data)),
            .usage = @intFromEnum(wgpu.BufferUsage.Vertex) | 
                @intFromEnum(wgpu.BufferUsage.Storage),
            .mappedAtCreation = true
        });
        log.debug("created particle buffer {}", .{i});

        const range = try particle_buffers[i].getMappedRange(f32, 0, @sizeOf(@TypeOf(initial_particle_data)));
        log.debug("got range for particle buffer {}", .{i});

        assert(range.len == initial_particle_data.len);

        log.debug("setting values of particle buffer {}...", .{i});
        for (0..range.len) |r_idx| {
            range[r_idx] = initial_particle_data[r_idx];
        }

        particle_buffers[i].unmap();
    }

    defer for (particle_buffers) |buffer| buffer.release();

    log.debug("getting BindGroupLayout", .{});
    const layout = try compute_pipeline.GetBindGroupLayout(0);
    defer layout.release();


    var bind_groups: [2]wgpu.BindGroup = undefined;
    for (0..bind_groups.len) |i| {
        bind_groups[i] = try device.CreateBindGroup(&.{
            .layout = layout,
            .entryCount = 3,
            .entries = &[3]wgpu.BindGroupEntry{
                wgpu.BindGroupEntry{
                    .binding = 0,
                    .buffer = sim_param_buffer,
                    .size = sim_param_buffer.getSize()
                },
                wgpu.BindGroupEntry{
                    .binding = 1,
                    .buffer = particle_buffers[i],
                    .offset = 0,
                    .size = particle_buffers[i].getSize(),
                },
                wgpu.BindGroupEntry{
                    .binding = 2,
                    .buffer = particle_buffers[(i + 1) % 2],
                    .offset = 0,
                    .size = particle_buffers[(i + 2) % 2].getSize()
                }
            },
        });
    }
    defer for (bind_groups) |bind_group| bind_group.release();

    var t: usize = 0;
    // var timer = try  std.time.Timer.start();
    // var elapsed_sec: f64 = 0;
    // var fps: f64 = 0;
    // var running: bool = true;
    //
    // const thread = try std.Thread.spawn(.{}, printFPS, .{&fps, &running});
    // defer thread.join();
    //
    log.debug("Beginning loop", .{});
    while (!window.ShouldClose()) : (t += 1) {
        // const dt = timer.lap();
        // const dt_s = @as(f64, @floatFromInt(dt)) / 
        //     @as(f64, @floatFromInt(std.time.ns_per_s));

        // elapsed_sec += dt_s;
        // fps = 1 / (dt_s);

        
        glfw.pollEvents();

        const texture = try surface.GetCurrentTexture();
        defer texture.release();

        const view = try texture.CreateView(&.{
            .format = texture.GetFormat(),
            .dimension = .@"2D",
            .baseMipLevel = 0,
            .mipLevelCount = 1,
            .baseArrayLayer = 0,
            .arrayLayerCount = 1,
            .aspect = .All,
            .usage = surface_config.usage,
        });
        defer view.release();


        const command_encoder = try device.CreateCommandEncoder(&.{});
        defer command_encoder.release();
        
        {
            const comp_pass_enc = try command_encoder.beginComputePass(&.{});
            defer comp_pass_enc.release();

            comp_pass_enc.setPipeline(compute_pipeline);
            comp_pass_enc.setBindGroup(0, bind_groups[t % 2]);
            comp_pass_enc.dispatchWorkGroups(NUM_PARTICLES/64, 1, 1);
            comp_pass_enc.end();
        }

        {

            const render_pass_desc = wgpu.RenderPassDescriptor{
                .colorAttachmentCount = 1,
                .colorAttachments = &[1]wgpu.RenderPassColorAttachment {
                    wgpu.RenderPassColorAttachment {
                        .clearValue = .{ .r = 0, .g = 0, .b = 0, .a = 1},
                        .loadOp = .Clear,
                        .storeOp = .Store,
                        .view = view
                    },
                },
            };

            const rend_pass_enc = try command_encoder.BeginRenderPass(&render_pass_desc);
            defer rend_pass_enc.release();

            rend_pass_enc.setPipeline(render_pipeline);
            rend_pass_enc.setVertexBuffer(0, particle_buffers[(t + 1) % 2], 0);
            rend_pass_enc.setVertexBuffer(1, sprite_vertex_buffer, 0);
            rend_pass_enc.draw(3, NUM_PARTICLES, 0, 0);
            rend_pass_enc.end();
        }


        const command_buffer = try command_encoder.finish(&.{});
        defer command_buffer.release();

        queue.submit(&.{ command_buffer });

        surface.present();
        _ = device.poll(false, null);

        // std.Thread.sleep(8 * std.time.ns_per_ms);
    }

    // running = false;

}


fn printFPS(fps: *const f64, running: *const bool) void {
    while (running.*) {
        std.debug.print("fps = {d:3}\n", .{fps.*}); 
        std.Thread.sleep(1 * std.time.ns_per_s);
    }
}
