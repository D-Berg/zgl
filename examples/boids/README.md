# Compute Boids

Note: Memory leak is causes by wgpu-native on affects all examples.

Implemented in zig based on [webgpu-samples](https://github.com/webgpu/webgpu-samples).
Currently only works on native until emscripten headers match wgpu-native.

## Build and Run

```{zig}
zig build run -Doptimize=ReleaseSafe
```

On mac prepend `MTL_HUD_ENABLED=1` to show metal stats.
