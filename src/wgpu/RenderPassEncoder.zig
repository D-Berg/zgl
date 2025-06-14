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

pub const RenderPassEncoder = opaque {
    extern "c" fn wgpuRenderPassEncoderEnd(render_pass_encoder: ?*const RenderPassEncoder) void;
    pub fn end(render_pass_encoder: *const RenderPassEncoder) void {
        wgpuRenderPassEncoderEnd(render_pass_encoder);
    }

    extern "c" fn wgpuRenderPassEncoderRelease(renderPassEncoder: ?*const RenderPassEncoder) void;
    pub fn release(render_pass_encoder: *const RenderPassEncoder) void {
        wgpuRenderPassEncoderRelease(render_pass_encoder);
    }

    extern "c" fn wgpuRenderPassEncoderSetPipeline(
        render_pass_encoder: ?*const RenderPassEncoder,
        pipeline: *const RenderPipeline,
    ) void;
    pub fn setPipeline(
        render_pass_encoder: *const RenderPassEncoder,
        pipeline: *const RenderPipeline,
    ) void {
        wgpuRenderPassEncoderSetPipeline(render_pass_encoder, pipeline);
    }

    extern "c" fn wgpuRenderPassEncoderSetBindGroup(
        render_pass_encoder: ?*const RenderPassEncoder,
        group_index: u32,
        group: ?*const BindGroup,
        dynamic_offset_count: usize,
        dynamic_offsets: [*]const u32,
    ) void;

    pub fn setBindGroup(
        render_pass_encoder: *const RenderPassEncoder,
        group_index: u32,
        group: ?*const BindGroup,
        dynamic_offsets: []const u32,
    ) void {
        wgpuRenderPassEncoderSetBindGroup(
            render_pass_encoder,
            group_index,
            group,
            dynamic_offsets.len,
            @ptrCast(dynamic_offsets),
        );
    }

    extern "c" fn wgpuRenderPassEncoderDraw(
        render_pass_encoder: ?*const RenderPassEncoder,
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    ) void;

    pub fn draw(
        render_pass_encoder: *const RenderPassEncoder,
        vertex_count: u32,
        instance_count: u32,
        first_vertex: u32,
        first_instance: u32,
    ) void {
        wgpuRenderPassEncoderDraw(
            render_pass_encoder,
            vertex_count,
            instance_count,
            first_vertex,
            first_instance,
        );
    }

    extern "c" fn wgpuRenderPassEncoderSetVertexBuffer(
        render_pass_encoder: ?*const RenderPassEncoder,
        slot: u32,
        buffer: ?*const Buffer,
        offset: u64,
        size: u64,
    ) void;
    pub fn setVertexBuffer(
        render_pass_encoder: *const RenderPassEncoder,
        slot: u32,
        buffer: ?Buffer,
        offset: u64,
    ) void {
        const size: u64 = if (buffer) |b| b.getSize() else 0;
        wgpuRenderPassEncoderSetVertexBuffer(render_pass_encoder, slot, buffer, offset, size);
    }

    extern "c" fn wgpuRenderPassEncoderSetIndexBuffer(
        render_pass_encoder: ?*const RenderPassEncoder,
        buffer: ?*const Buffer,
        format: IndexFormat,
        offset: u64,
        size: u64,
    ) void;

    pub fn setIndexBuffer(
        render_pass_encoder: *const RenderPassEncoder,
        buffer: *const Buffer,
        format: IndexFormat,
        offset: u64,
    ) void {
        const size = buffer.getSize();

        wgpuRenderPassEncoderSetIndexBuffer(render_pass_encoder, buffer, format, offset, size);
    }

    extern "c" fn wgpuRenderPassEncoderDrawIndexed(
        render_pass_encoder: ?*const RenderPassEncoder,
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    ) void;

    pub fn drawIndexed(
        renderPassEncoder: *const RenderPassEncoder,
        index_count: u32,
        instance_count: u32,
        first_index: u32,
        base_vertex: i32,
        first_instance: u32,
    ) void {
        wgpuRenderPassEncoderDrawIndexed(
            renderPassEncoder,
            index_count,
            instance_count,
            first_index,
            base_vertex,
            first_instance,
        );
    }
};
