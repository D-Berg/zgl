const wgpu = @import("wgpu.zig");
const ViewImpl = wgpu.Texture.ViewImpl;
const ChainedStruct = wgpu.ChainedStruct;
const LoadOp = wgpu.LoadOp;
const StoreOp = wgpu.StoreOp;
const Color = wgpu.Color;
const QuerySetImpl = wgpu.QuerySet.QuerySetImpl;
const DepthSlice = wgpu.DepthSlice;
const RenderPipeline = wgpu.RenderPipeline;
const RenderPipelineImpl = RenderPipeline.RenderPipelineImpl;
const Buffer = wgpu.Buffer;
const BindGroup = wgpu.BindGroup;


pub const EncoderImpl = *opaque {};

pub const ColorAttachment = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    view: ?ViewImpl = null,
    depthSlice: DepthSlice = .Undefined,
    resolveTarget: ?ViewImpl = null,
    loadOp: LoadOp,
    storeOp: StoreOp,
    clearValue: Color
};



pub const DepthStencilAttachment = extern struct {
    view: ViewImpl,
    depthLoadOp: LoadOp,
    depthStoreOp: StoreOp,
    depthClearValue: f32,
    depthReadOnly: bool,
    stencilLoadOp: LoadOp,
    stencilStoreOp: StoreOp,
    stencilClearValue: u32,
    stencilReadOnly: bool,
};


pub const TimestampWrites = extern struct {
    querySet: QuerySetImpl,
    beginningOfPassWriteIndex: u32,
    endOfPassWriteIndex: u32
};

pub const Descriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: wgpu.StringView = .{ .data = "", .length = 0 },
    colorAttachmentCount: usize = 0,
    colorAttachments: ?[*]const ColorAttachment = null,
    depthStencilAttachment: ?*const DepthStencilAttachment = null,
    occlusionQuerySet: ?QuerySetImpl = null,
    timestampWrites: ?*const TimestampWrites = null
};

// TODO: make methods lowercase since the return void
pub const Encoder = struct {
    _impl: EncoderImpl,

    extern "c" fn wgpuRenderPassEncoderEnd(renderPassEncoder: EncoderImpl) void;
    pub fn End(renderPassEncoder: Encoder) void {
        wgpuRenderPassEncoderEnd(renderPassEncoder._impl);
    }

    extern "c" fn wgpuRenderPassEncoderRelease(renderPassEncoder: EncoderImpl) void;
    pub fn Release(renderPassEncoder: Encoder) void {
        wgpuRenderPassEncoderRelease(renderPassEncoder._impl);
    }

    // TODO: start lowercase
    extern "c" fn wgpuRenderPassEncoderSetPipeline(renderPassEncoder: EncoderImpl, pipeline: RenderPipelineImpl) void;
    pub fn SetPipeline(renderPassEncoder: Encoder, pipeline: RenderPipeline) void {
        wgpuRenderPassEncoderSetPipeline(renderPassEncoder._impl, pipeline._impl);
    }

    
    extern "c" fn wgpuRenderPassEncoderSetBindGroup(
        renderPassEncoder: EncoderImpl, 
        groupIndex: u32, 
        group: ?*BindGroup, 
        dynamicOffsetCount: usize,
        dynamicOffsets: [*]const u32
    ) void;

    pub fn setBindGroup(
        renderPassEncoder: Encoder, 
        groupIndex: u32,
        group: ?*BindGroup,
        dynamicOffsets: []const u32
    ) void {

        wgpuRenderPassEncoderSetBindGroup(
            renderPassEncoder._impl, 
            groupIndex, 
            group, 
            dynamicOffsets.len, 
            @ptrCast(dynamicOffsets)
        );

    }

    extern "c" fn wgpuRenderPassEncoderDraw(renderPassEncoder: EncoderImpl, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void;

    pub fn Draw(renderPassEncoder: Encoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void {
        wgpuRenderPassEncoderDraw(renderPassEncoder._impl, vertexCount, instanceCount, firstVertex, firstInstance);
    }

    extern "c" fn wgpuRenderPassEncoderSetVertexBuffer(renderPassEncoder: EncoderImpl, slot: u32, buffer: ?Buffer.BufferImpl, offset: u64, size: u64) void;
    pub fn setVertexBuffer(renderPassEncoder: Encoder, slot: u32, buffer: ?Buffer, offset: u64) void {
        const buffer_impl: ?Buffer.BufferImpl = if (buffer) |b| b._impl else null;
        const size: u64 = if (buffer) |b| b.GetSize() else 0;
        wgpuRenderPassEncoderSetVertexBuffer(renderPassEncoder._impl, slot, buffer_impl, offset, size);
    }
};

