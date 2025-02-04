const wgpu = @import("wgpu.zig");
const ChainedStruct = wgpu.ChainedStruct;
const LoadOp = wgpu.LoadOp;
const StoreOp = wgpu.StoreOp;
const Color = wgpu.Color;
const QuerySet = wgpu.QuerySet;
const DepthSlice = wgpu.DepthSlice;
const RenderPipeline = wgpu.RenderPipeline;
const Buffer = wgpu.Buffer;
const BindGroup = wgpu.BindGroup;
const TextureView = wgpu.TextureView;
const IndexFormat = wgpu.IndexFormat;


pub const RenderPassEncoder = *RenderPassEncoderImpl;
const RenderPassEncoderImpl = opaque {
    extern "c" fn wgpuRenderPassEncoderEnd(renderPassEncoder: RenderPassEncoder) void;
    pub fn end(renderPassEncoder: RenderPassEncoder) void {
        wgpuRenderPassEncoderEnd(renderPassEncoder);
    }

    extern "c" fn wgpuRenderPassEncoderRelease(renderPassEncoder: RenderPassEncoder) void;
    pub fn release(renderPassEncoder: RenderPassEncoder) void {
        wgpuRenderPassEncoderRelease(renderPassEncoder);
    }

    // TODO: start lowercase
    extern "c" fn wgpuRenderPassEncoderSetPipeline(renderPassEncoder: RenderPassEncoder, pipeline: RenderPipeline) void;
    pub fn setPipeline(renderPassEncoder: RenderPassEncoder, pipeline: RenderPipeline) void {
        wgpuRenderPassEncoderSetPipeline(renderPassEncoder, pipeline);
    }

    
    extern "c" fn wgpuRenderPassEncoderSetBindGroup(
        renderPassEncoder: RenderPassEncoder, 
        groupIndex: u32, 
        group: ?*BindGroup, 
        dynamicOffsetCount: usize,
        dynamicOffsets: [*]const u32
    ) void;

    pub fn setBindGroup(
        renderPassEncoder: RenderPassEncoder, 
        groupIndex: u32,
        group: ?*BindGroup,
        dynamicOffsets: []const u32
    ) void {

        wgpuRenderPassEncoderSetBindGroup(
            renderPassEncoder, 
            groupIndex, 
            group, 
            dynamicOffsets.len, 
            @ptrCast(dynamicOffsets)
        );

    }

    extern "c" fn wgpuRenderPassEncoderDraw(
        renderPassEncoder: RenderPassEncoder, 
        vertexCount: u32, 
        instanceCount: u32, 
        firstVertex: u32, 
        firstInstance: u32
    ) void;

    pub fn draw(
        renderPassEncoder: RenderPassEncoder,
        vertexCount: u32, 
        instanceCount: u32, 
        firstVertex: u32, 
        firstInstance: u32
    ) void {
        wgpuRenderPassEncoderDraw(renderPassEncoder, vertexCount, instanceCount, firstVertex, firstInstance);
    }

    extern "c" fn wgpuRenderPassEncoderSetVertexBuffer(
        renderPassEncoder: RenderPassEncoder, 
        slot: u32, 
        buffer: ?Buffer, 
        offset: u64, 
        size: u64
    ) void;
    pub fn setVertexBuffer(renderPassEncoder: RenderPassEncoder, slot: u32, buffer: ?Buffer, offset: u64) void {
        const size: u64 = if (buffer) |b| b.getSize() else 0;
        wgpuRenderPassEncoderSetVertexBuffer(renderPassEncoder, slot, buffer, offset, size);
    }

    extern "c" fn wgpuRenderPassEncoderSetIndexBuffer(
        renderPassEncoder: RenderPassEncoder,
        buffer: Buffer,
        format: IndexFormat,
        offset: u64,
        size: u64
    ) void;
    
    pub fn setIndexBuffer(renderPassEncoder: RenderPassEncoder, buffer: Buffer, format: IndexFormat, offset: u64) void {

        const size = buffer.getSize();

        wgpuRenderPassEncoderSetIndexBuffer(renderPassEncoder, buffer, format, offset, size);

    }
    

};








