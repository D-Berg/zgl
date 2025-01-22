
@binding(0) @group(0) var<uniform> grid: vec2f;

// If buffer isn't used one get the following error
// https://www.reddit.com/r/wgpu/comments/xhqxrk/number_of_bindings_in_bind_group_descriptor_2/
//Number of bindings in bind group descriptor (2) does not match the number of bindings defined in the bind group layout (1)
@binding(1) @group(0) var<storage> snake: array<u32>;


struct VertOut {
    @builtin(position) position: vec4f,
    @location(0) color: vec3f
}

@vertex
fn vs_main(
    @location(0) pos: vec2f,
    @builtin(instance_index) instance: u32
) -> VertOut {
    let i = f32(instance);



    let cell = vec2f(i % grid.x, floor(i / grid.x));
    let cell_offset = cell / grid * 2;
    let grid_pos = (pos + 1) /  grid - 1 + cell_offset;

    var output: VertOut;

    output.position = vec4f(grid_pos, 0, 1);

    let dark_grey = vec3f(27, 27, 27);
    let max = vec3f(255, 255, 255);

    if (snake[instance] == 1) {
        output.color = vec3f(1, 0, 0);
    } else {
        output.color = dark_grey / max;

    }

    return output; // (X, Y, Z, W)
}

@fragment
fn fs_main(@location(0) in_color: vec3f) -> @location(0) vec4f {
    return vec4f(in_color, 1);
}
