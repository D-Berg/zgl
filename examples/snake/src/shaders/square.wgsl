
@binding(0) @group(0) var<uniform> grid: vec2f;
//@binding(1) @group(0) var<storage, read> snake: array<u32>;

@vertex
fn vs_main(
    @location(0) pos: vec2f,
    @builtin(instance_index) instance: u32
) -> @builtin(position) vec4f {
    let i = f32(instance);

    let cell = vec2f(i % grid.x, floor(i / grid.x));
    let cell_offset = cell / grid * 2;
    let grid_pos = (pos + 1) /  grid - 1 + cell_offset;

    return vec4f(grid_pos, 0, 1); // (X, Y, Z, W)
}

@fragment
fn fs_main() -> @location(0) vec4f {
    let dark_grey = vec3f(27, 27, 27);
    let max = vec3f(255, 255, 255);
    return vec4f(dark_grey / max, 1); // red
}
