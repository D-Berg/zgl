// If buffer isn't used one get the following error
// https://www.reddit.com/r/wgpu/comments/xhqxrk/number_of_bindings_in_bind_group_descriptor_2/
//Number of bindings in bind group descriptor (2) does not match the number of bindings defined in the bind group layout (1)
@binding(0) @group(0) var<uniform> window: vec2f;
@binding(1) @group(0) var<storage> rectangles: array<Rectangle>;


struct Rectangle {
    position: vec2f, // x, y
    dimension: vec2f, // width, height
    color: vec4f,

}
struct VertOut {
    @builtin(position) position: vec4f,
    @location(0) color: vec4f,
}

@vertex
fn vs_main(
    @builtin(vertex_index) vert_idx: u32, @builtin(instance_index) instance: u32
) -> VertOut {

    let max_color = vec4f(255, 255, 255, 1);
    const half = vec2f(2, 2);

    let w = window;
    let rec = rectangles[instance];
    let rec_pos = vec2f(2 * (rec.position.x / w.x) - 1,  1 - 2 * (rec.position.y / w.y));
    let rec_dim = (rec.dimension * 2) / w;

    let pos = array(
        // top triangle
        rec_pos, // top left
        vec2(rec_pos.x + rec_dim.x, rec_pos.y), // top right
        vec2f(rec_pos.x + rec_dim.x, rec_pos.y - rec_dim.y), // bot right


        // bot triangle
        rec_pos, // top left
        vec2f(rec_pos.x, rec_pos.y - rec_dim.y), // bot left,   
        vec2f(rec_pos.x + rec_dim.x, rec_pos.y - rec_dim.y), // bot right
    );
    var output: VertOut;
    output.position = vec4f(pos[vert_idx], 0, 1);
    output.color = rec.color;

    return output; // (X, Y, Z, W)
}

@fragment
fn fs_main(@location(0) color: vec4f) -> @location(0) vec4f {
    return color;
}
