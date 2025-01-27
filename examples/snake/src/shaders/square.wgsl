struct Rectangle {
    position: vec2f, // x, y
    dimension: vec2f, // width, height
    color: vec4f,

}

struct VertIn {
    @location(0) pos: vec2f,
    @location(1) color: vec4f,
}

struct VertOut {
    @builtin(position) position: vec4f,
    @location(0) color: vec4f,
}

@vertex
fn vs_main(input: VertIn) -> VertOut {
//    let max_color = vec4f(255, 255, 255, 1);
//    const half = vec2f(2, 2);
//
//    let w = window;
//    let rec = rectangles[instance];
//    let rec_pos = vec2f(2 * (rec.position.x / w.x) - 1,  1 - 2 * (rec.position.y / w.y));
//    let rec_dim = (rec.dimension * 2) / w;
//
//    let pos = array(
//        // top triangle
//        rec_pos, // top left
//        vec2(rec_pos.x + rec_dim.x, rec_pos.y), // top right
//        vec2f(rec_pos.x + rec_dim.x, rec_pos.y - rec_dim.y), // bot right
//
//
//        // bot triangle
//        rec_pos, // top left
//        vec2f(rec_pos.x, rec_pos.y - rec_dim.y), // bot left,   
//        vec2f(rec_pos.x + rec_dim.x, rec_pos.y - rec_dim.y), // bot right
//    );
    var output: VertOut;
    output.position = vec4f(input.pos, 0, 1);
    output.color = input.color;


    return output; // (X, Y, Z, W)
}

@fragment
fn fs_main(@location(0) color: vec4f) -> @location(0) vec4f {
    return color;
}
