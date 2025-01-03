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

    extern "c" fn wgpuRenderPassEncoderSetPipeline(renderPassEncoder: EncoderImpl, pipeline: RenderPipelineImpl) void;
    pub fn SetPipeline(renderPassEncoder: Encoder, pipeline: RenderPipeline) void {
        wgpuRenderPassEncoderSetPipeline(renderPassEncoder._impl, pipeline._impl);
    }

    extern "c" fn wgpuRenderPassEncoderDraw(renderPassEncoder: EncoderImpl, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void;

    pub fn Draw(renderPassEncoder: Encoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) void {
        wgpuRenderPassEncoderDraw(renderPassEncoder._impl, vertexCount, instanceCount, firstVertex, firstInstance);
    }

    
};

