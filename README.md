# Zig Gaming Library
A simple game lib for mac, windows, linux and web with support for
crosscompilation to the mentioned platforms.

Purpose: For me to learn graphics programming.

### zig dependencies
- glfw
- wgpu-native
- emscripten(web)

## Goals 
- crosscompilation
- a high level api
- only zig as dependencie

### Idea of high level api for drawing shapes
```
fn drawFram() {
    var scene = zgl.Scene.init(allocator);
    defer scene.deinit();

    try scene.drawRectanle(.{ .x, .y, ...});
    try scene.drawCircle(...);
}
```

## Usage
See examples directory.

## BUGS

wgpu-native and emscripten both differ from webgpu-native header. Webgpu isn't 
completed yet but creating bindings proves tiresome.

One option is to use zig translate-c option but I quite like doing the bindings
manually for learning purposes. 

## Differences between wgpu-native and emscripten webgpu
- wgpuSurfaceCapabilities in emscripten doesn't have field usages.
- wgpuFrontFace enum values differs
- wgpuPrimitiveTopology enum values differs

## Documentation 

```sh
zig build docs -p ./
```
