//! https://webgpu-native.github.io/webgpu-headers/webgpu_8h_source.html
const std = @import("std");
const log = std.log.scoped(.@"wgpu");
const Allocator = std.mem.Allocator;

/// If you want to import submodules lazily, define them as functions returning their types or namespaces.
/// Example usage in your code: `const Instance = wgpu.lazyInstance();`
pub fn lazyInstance() type {
    return @import("Instance.zig");
}

pub fn lazyAdapter() type {
    return @import("Adapter.zig");
}

pub fn lazyDevice() type {
    return @import("Device.zig");
}

pub fn lazyQueue() type {
    // `Queue` is also exported from `Queue.zig`;  
    // return the entire file or the single type. 
    return @import("Queue.zig");
}

pub fn lazySurface() type {
    return @import("Surface.zig");
}

pub fn lazyCommandEncoder() type {
    return @import("CommandEncoder.zig");
}

pub fn lazyCommandBuffer() type {
    return @import("CommandBuffer.zig");
}

pub fn lazyTexture() type {
    return @import("Texture.zig");
}

pub fn lazyRenderPass() type {
    return @import("RenderPass.zig");
}

pub fn lazyQuerySet() type {
    return @import("QuerySet.zig");
}

pub fn lazyShaderModule() type {
    return @import("ShaderModule.zig");
}

pub fn lazyPipelineLayout() type {
    return @import("PipelineLayout.zig");
}

pub fn lazyRenderPipeline() type {
    return @import("RenderPipeline.zig");
}

pub fn lazyBuffer() type {
    return @import("Buffer.zig");
}

pub fn lazyComputePipeline() type {
    return @import("ComputePipeline.zig");
}

/// Common error type returned by various WebGPU operations.
pub const WGPUError = error {
    FailedToCreateInstance,
    FailedToRequestDevice,
    FailedToRequestAdapter,
    FailedToGetDeviceLimits,
    FailedToGetQueue,
    UnsuccessfulSurfaceGetCurrentTextureStatus,
    FailedToGetTextureView,
    FailedToBeginRenderPass,
    FailedToCreateShaderModule,
    FailedToCreateRenderPipeline,
    FailedToCreateSurface,
    FailedToCreateBuffer,
    FailedToCreateComputePipeline,
};

/// Used for specifying numeric constants (push constants, specialization constants, etc.).
pub const ConstantEntry = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    key: [*]const u8,
    value: f64,
};

/// Describes how vertex data is stepped: per-vertex, per-instance, or no usage.
pub const VertexStepMode = enum(u32) {
    Vertex = 0x00000000,
    Instance = 0x00000001,
    VertexBufferNotUsed = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Available vertex formats describing how data is laid out for the GPU.
pub const VertexFormat = enum(u32) {
    Undefined = 0x00000000,
    Uint8x2 = 0x00000001,
    Uint8x4 = 0x00000002,
    Sint8x2 = 0x00000003,
    Sint8x4 = 0x00000004,
    Unorm8x2 = 0x00000005,
    Unorm8x4 = 0x00000006,
    Snorm8x2 = 0x00000007,
    Snorm8x4 = 0x00000008,
    Uint16x2 = 0x00000009,
    Uint16x4 = 0x0000000A,
    Sint16x2 = 0x0000000B,
    Sint16x4 = 0x0000000C,
    Unorm16x2 = 0x0000000D,
    Unorm16x4 = 0x0000000E,
    Snorm16x2 = 0x0000000F,
    Snorm16x4 = 0x00000010,
    Float16x2 = 0x00000011,
    Float16x4 = 0x00000012,
    Float32 = 0x00000013,
    Float32x2 = 0x00000014,
    Float32x3 = 0x00000015,
    Float32x4 = 0x00000016,
    Uint32 = 0x00000017,
    Uint32x2 = 0x00000018,
    Uint32x3 = 0x00000019,
    Uint32x4 = 0x0000001A,
    Sint32 = 0x0000001B,
    Sint32x2 = 0x0000001C,
    Sint32x3 = 0x0000001D,
    Sint32x4 = 0x0000001E,
    Force32 = 0x7FFFFFFF,
};

/// Describes a single attribute (format, offset, and shader location) within a vertex buffer.
pub const VertextAttribute = extern struct {
    format: VertexFormat,
    offset: u64,
    shaderLocation: u32,
};

/// Describes the layout of a single vertex buffer (stride, stepping mode, and attribute list).
pub const VertexBufferLayout = extern struct {
    arrayStride: u64,
    stepMode: VertexStepMode,
    attributeCount: usize,
    attributes: [*]const VertextAttribute,
};

/// Describes the vertex stage of a rendering pipeline.
pub const VertexState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule.ShaderModuleImpl,
    entryPoint: ?[*]const u8 = null,

    constantCount: usize = 0,
    constants: ?[*]const ConstantEntry = null,

    bufferCount: usize = 0,
    buffers: ?[*]const VertexBufferLayout = null,
};

/// Describes a programmable shader stage (like vertex or fragment).
pub const ProgrammableStageDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule.ShaderModuleImpl,
    entryPoint: ?[*]const u8 = null,
    constantCount: usize = 0,
    constants: ?[*]const ConstantEntry = null,
};

/// Various topologies describing how the GPU interprets vertex data.
pub const PrimitiveTopology = enum(u32) {
    Undefined = 0x00000000,
    PointList = 0x00000001,
    LineList = 0x00000002,
    LineStrip = 0x00000003,
    TriangleList = 0x00000004,
    TriangleStrip = 0x00000005,
    Force32 = 0x7FFFFFFF,
};

/// Index data formats used for triangle/line lists, or undefined if none is used.
pub const IndexFormat = enum(u32) {
    Undefined = 0x00000000,
    Uint16 = 0x00000001,
    Uint32 = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Defines which side of a triangle is considered the front face.
pub const FrontFace = enum(u32) {
    Undefined = 0x00000000,
    CCW = 0x00000001,
    CW = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Defines whether to cull (discard) front- or back-facing triangles.
pub const CullMode = enum(u32) {
    None = 0x00000000,
    Front = 0x00000001,
    Back = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Describes the primitive state of a render pipeline (topology, culling, front face, etc.).
pub const PrimitiveState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    topology: PrimitiveTopology = .Undefined,
    stripIndexFormat: IndexFormat = .Undefined,
    frontFace: FrontFace = .Undefined,
    cullMode: CullMode = .None,
};

/// Comparison functions used for depth or stencil tests.
pub const CompareFunction = enum(u32) {
    Undefined = 0x00000000,
    Never = 0x00000001,
    Less = 0x00000002,
    LessEqual = 0x00000003,
    Greater = 0x00000004,
    GreaterEqual = 0x00000005,
    Equal = 0x00000006,
    NotEqual = 0x00000007,
    Always = 0x00000008,
    Force32 = 0x7FFFFFFF,
};

/// Operations performed on stencil values.
pub const StencilOperation = enum(u32) {
    Keep = 0x00000000,
    Zero = 0x00000001,
    Replace = 0x00000002,
    Invert = 0x00000003,
    IncrementClamp = 0x00000004,
    DecrementClamp = 0x00000005,
    IncrementWrap = 0x00000006,
    DecrementWrap = 0x00000007,
    Force32 = 0x7FFFFFFF,
};

/// Describes how stencil values are tested and updated on a particular face.
pub const StencilFaceState = extern struct {
    compare: CompareFunction,
    failOp: StencilOperation,
    depthFailOp: StencilOperation,
    passOp: StencilOperation,
};

/// Describes depth-stencil state (depth test/write, stencil front/back faces, etc.).
pub const DepthStencilState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    format: TextureFormat,
    depthWriteEnabled: bool,
    depthCompare: CompareFunction,

    stencilFront: StencilFaceState,
    stencilBack: StencilFaceState,
    stencilReadMask: u32,
    stencilWriteMask: u32,

    depthBias: i32,
    depthBiasSlopeScale: f32,
    depthBiasClamp: f32,
};

/// Describes multisampling state in a render pipeline.
pub const MultiSampleState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    count: u32,
    mask: u32,
    alphaToCoverageEnabled: bool,
};

/// Blend operations for color/alpha channels.
pub const BlendOperation = enum(u32) {
    Add = 0x00000000,
    Subtract = 0x00000001,
    ReverseSubtract = 0x00000002,
    Min = 0x00000003,
    Max = 0x00000004,
    Force32 = 0x7FFFFFFF,
};

/// Blend factor used in alpha/color blending.
pub const BlendFactor = enum(u32) {
    Zero = 0x00000000,
    One = 0x00000001,
    Src = 0x00000002,
    OneMinusSrc = 0x00000003,
    SrcAlpha = 0x00000004,
    OneMinusSrcAlpha = 0x00000005,
    Dst = 0x00000006,
    OneMinusDst = 0x00000007,
    DstAlpha = 0x00000008,
    OneMinusDstAlpha = 0x00000009,
    SrcAlphaSaturated = 0x0000000A,
    Constant = 0x0000000B,
    OneMinusConstant = 0x0000000C,
    Force32 = 0x7FFFFFFF,
};

/// A single component (color or alpha) in the blending pipeline.
pub const BlendComponent = extern struct {
    operation: BlendOperation,
    srcFactor: BlendFactor,
    dstFactor: BlendFactor,
};

/// Describes the combined color/alpha blending operations.
pub const BlendState = extern struct {
    color: BlendComponent,
    alpha: BlendComponent,
};

/// Masks which color channels are written to in a color attachment.
pub const ColorWriteMask = enum(u32) {
    const NONE = 0x00000000;
    const RED = 0x00000001;
    const GREEN = 0x00000002;
    const BLUE = 0x00000004;
    const ALPHA = 0x00000008;

    None = NONE,
    Red = RED,
    Green = GREEN,
    Blue = BLUE,
    Alpha = ALPHA,
    All = NONE | RED | GREEN | BLUE | ALPHA,
    Force32 = 0x7FFFFFFF,
};

/// Describes how a particular color attachment is configured in a render pipeline.
pub const ColorTargetState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    format: TextureFormat,
    blend: ?*const BlendState,
    writeMask: ColorWriteMask,
};

/// Describes the fragment stage of a rendering pipeline.
pub const FragmentState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule.ShaderModuleImpl,
    entryPoint: ?[*]const u8,

    constantCount: usize = 0,
    constants: ?[*]const ConstantEntry = null,

    targetCount: usize = 0,
    targets: ?[*]const ColorTargetState = null,
};

/// A fallback or undefined depth-slice representation.
pub const DepthSlice = enum(u32) {
    Undefined = 0xffffffff,
};

/// Basic success/error status codes for some asynchronous or immediate ops.
pub const Status = enum(u32) {
    Success = 0x00000001,
    Error = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Result codes when requesting an adapter from an `Instance`.
pub const RequestAdapterStatus = enum(u32) {
    Success = 0x00000001,
    InstanceDropped = 0x00000002,
    Unavailable = 0x00000003,
    Error = 0x00000004,
    Unknown = 0x00000005,
    Force32 = 0x7FFFFFFF,
};

/// SType enumerates special structures used to extend descriptors at runtime.
const SType = enum(u32) {
    Invalid = 0x00000000,
    SurfaceDescriptorFromMetalLayer = 0x00000001,
    SurfaceDescriptorFromWindowsHWND = 0x00000002,
    SurfaceDescriptorFromXlibWindow = 0x00000003,
    SurfaceDescriptorFromCanvasHTMLSelector = 0x00000004,
    ShaderModuleSPIRVDescriptor = 0x00000005,
    ShaderModuleWGSLDescriptor = 0x00000006,
    PrimitiveDepthClipControl = 0x00000007,
    SurfaceDescriptorFromWaylandSurface = 0x00000008,
    SurfaceDescriptorFromAndroidNativeWindow = 0x00000009,
    SurfaceDescriptorFromXcbWindow = 0x0000000A,
    RenderPassDescriptorMaxDrawCount = 0x0000000F,
    Force32 = 0x7FFFFFFF,
};

/// Status codes returned by `Surface.getCurrentTexture()`.
pub const SurfaceGetCurrentTextureStatus = enum(u32) {
    Success = 0,
    Timeout = 1,
    Outdated = 2,
    Lost = 3,
    OutOfMemory = 4,
    DeviceLost = 5,
    Force32 = 0x7FFFFFFF,
};

/// Backends for WGPU: Vulkan, Metal, D3D, etc.
pub const BackendType = enum(u32) {
    Undefined = 0x00000000,
    Null = 0x00000001,
    WebGPU = 0x00000002,
    D3D11 = 0x00000003,
    D3D12 = 0x00000004,
    Metal = 0x00000005,
    Vulkan = 0x00000006,
    OpenGL = 0x00000007,
    OpenGLES = 0x00000008,
    Force32 = 0x7FFFFFFF,
};

/// How alpha is handled when composing surfaces with OS visuals.
pub const CompositeAlphaMode = enum(u32) {
    Auto = 0x00000000,
    Opaque = 0x00000001,
    Premultiplied = 0x00000002,
    Unpremultiplied = 0x00000003,
    Inherit = 0x00000004,
    Force32 = 0x7FFFFFFF,
};

/// Present modes controlling V-sync or triple-buffer semantics.
pub const PresentMode = enum(u32) {
    Undefined = 0x00000000,
    Fifo = 0x00000001,
    FifoRelaxed = 0x00000002,
    Immediate = 0x00000003,
    Mailbox = 0x00000004,
    Force32 = 0x7FFFFFFF,
};

/// Dimensional view of textures (1D/2D/3D/cube).
pub const TexureViewDimension = enum(u32) {
    Undefined = 0x00000000,
    @"1D" = 0x00000001,
    @"2D" = 0x00000002,
    @"2DArray" = 0x00000003,
    Cube = 0x00000004,
    CubeArray = 0x00000005,
    @"3D" = 0x00000006,
    Force32 = 0x7FFFFFFF,
};

/// Which aspect(s) of a texture is accessible (e.g., depth only, stencil only, or both).
pub const TextureAspect = enum(u32) {
    All = 0x00000000,
    StencilOnly = 0x00000001,
    DepthOnly = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Commonly used texture formats.
pub const TextureFormat = enum(u32) {
    Undefined = 0x00000000,
    R8Unorm = 0x00000001,
    R8Snorm = 0x00000002,
    R8Uint = 0x00000003,
    R8Sint = 0x00000004,
    R16Uint = 0x00000005,
    R16Sint = 0x00000006,
    R16Float = 0x00000007,
    RG8Unorm = 0x00000008,
    RG8Snorm = 0x00000009,
    RG8Uint = 0x0000000A,
    RG8Sint = 0x0000000B,
    R32Float = 0x0000000C,
    R32Uint = 0x0000000D,
    R32Sint = 0x0000000E,
    RG16Uint = 0x0000000F,
    RG16Sint = 0x00000010,
    RG16Float = 0x00000011,
    RGBA8Unorm = 0x00000012,
    RGBA8UnormSrgb = 0x00000013,
    RGBA8Snorm = 0x00000014,
    RGBA8Uint = 0x00000015,
    RGBA8Sint = 0x00000016,
    BGRA8Unorm = 0x00000017,
    BGRA8UnormSrgb = 0x00000018,
    RGB10A2Uint = 0x00000019,
    RGB10A2Unorm = 0x0000001A,
    RG11B10Ufloat = 0x0000001B,
    RGB9E5Ufloat = 0x0000001C,
    RG32Float = 0x0000001D,
    RG32Uint = 0x0000001E,
    RG32Sint = 0x0000001F,
    RGBA16Uint = 0x00000020,
    RGBA16Sint = 0x00000021,
    RGBA16Float = 0x00000022,
    RGBA32Float = 0x00000023,
    RGBA32Uint = 0x00000024,
    RGBA32Sint = 0x00000025,
    Stencil8 = 0x00000026,
    Depth16Unorm = 0x00000027,
    Depth24Plus = 0x00000028,
    Depth24PlusStencil8 = 0x00000029,
    Depth32Float = 0x0000002A,
    Depth32FloatStencil8 = 0x0000002B,
    BC1RGBAUnorm = 0x0000002C,
    BC1RGBAUnormSrgb = 0x0000002D,
    BC2RGBAUnorm = 0x0000002E,
    BC2RGBAUnormSrgb = 0x0000002F,
    BC3RGBAUnorm = 0x00000030,
    BC3RGBAUnormSrgb = 0x00000031,
    BC4RUnorm = 0x00000032,
    BC4RSnorm = 0x00000033,
    BC5RGUnorm = 0x00000034,
    BC5RGSnorm = 0x00000035,
    BC6HRGBUfloat = 0x00000036,
    BC6HRGBFloat = 0x00000037,
    BC7RGBAUnorm = 0x00000038,
    BC7RGBAUnormSrgb = 0x00000039,
    ETC2RGB8Unorm = 0x0000003A,
    ETC2RGB8UnormSrgb = 0x0000003B,
    ETC2RGB8A1Unorm = 0x0000003C,
    ETC2RGB8A1UnormSrgb = 0x0000003D,
    ETC2RGBA8Unorm = 0x0000003E,
    ETC2RGBA8UnormSrgb = 0x0000003F,
    EACR11Unorm = 0x00000040,
    EACR11Snorm = 0x00000041,
    EACRG11Unorm = 0x00000042,
    EACRG11Snorm = 0x00000043,
    ASTC4x4Unorm = 0x00000044,
    ASTC4x4UnormSrgb = 0x00000045,
    ASTC5x4Unorm = 0x00000046,
    ASTC5x4UnormSrgb = 0x00000047,
    ASTC5x5Unorm = 0x00000048,
    ASTC5x5UnormSrgb = 0x00000049,
    ASTC6x5Unorm = 0x0000004A,
    ASTC6x5UnormSrgb = 0x0000004B,
    ASTC6x6Unorm = 0x0000004C,
    ASTC6x6UnormSrgb = 0x0000004D,
    ASTC8x5Unorm = 0x0000004E,
    ASTC8x5UnormSrgb = 0x0000004F,
    ASTC8x6Unorm = 0x00000050,
    ASTC8x6UnormSrgb = 0x00000051,
    ASTC8x8Unorm = 0x00000052,
    ASTC8x8UnormSrgb = 0x00000053,
    ASTC10x5Unorm = 0x00000054,
    ASTC10x5UnormSrgb = 0x00000055,
    ASTC10x6Unorm = 0x00000056,
    ASTC10x6UnormSrgb = 0x00000057,
    ASTC10x8Unorm = 0x00000058,
    ASTC10x8UnormSrgb = 0x00000059,
    ASTC10x10Unorm = 0x0000005A,
    ASTC10x10UnormSrgb = 0x0000005B,
    ASTC12x10Unorm = 0x0000005C,
    ASTC12x10UnormSrgb = 0x0000005D,
    ASTC12x12Unorm = 0x0000005E,
    ASTC12x12UnormSrgb = 0x0000005F,
    Force32 = 0x7FFFFFFF,
};

/// Bitmask usage flags describing how a texture can be used.
pub const TextureUsage = enum(u32) {
    None = 0x00000000,
    CopySrc = 0x00000001,
    CopyDst = 0x00000002,
    TextureBinding = 0x00000004,
    StorageBinding = 0x00000008,
    RenderAttachment = 0x00000010,
    Force32 = 0x7FFFFFFF,
};

/// A texture can be 1D, 2D, or 3D in dimension.
pub const TextureDimension = enum(u32) {
    Undefined = 0x00000000,
    @"1D" = 0x00000001,
    @"2D" = 0x00000002,
    @"3D" = 0x00000003,
    Force32 = 0x7FFFFFFF,
};

/// Structure used to chain descriptors together at runtime for extension.
pub const ChainedStruct = extern struct {
    next: ?*const ChainedStruct = null,
    sType: SType,
};

/// Outbound structure used similarly to `ChainedStruct`, for returning extended info.
pub const ChainedStructOut = extern struct {
    next: ?*const ChainedStructOut,
    sType: SType,
};

/// Minimal string type used in this API: pointer + length.
pub const StringView = extern struct {
    data: [*]const u8,
    length: usize,

    /// Convert a StringView to a slice of const u8.
    pub fn toSlice(stringView: StringView) []const u8 {
        var slice: []const u8 = undefined;
        slice.ptr = stringView.data;
        slice.len = stringView.length;
        return slice;
    }

    /// Construct a StringView from any slice of const u8.
    pub fn fromSlice(slice: []const u8) StringView {
        return StringView{
            .data = slice.ptr,
            .length = slice.len,
        };
    }
};

/// Represents an asynchronous operation ID or handle.
pub const Future = u64;

/// Modes describing how a callback for asynchronous operations is invoked.
pub const CallBackMode = enum(u32) {
    WaitAnyOnly = 0x00000001,
    AllowProcessEvents = 0x00000002,
    AllowSpontaneous = 0x00000003,
    Force32 = 0x7FFFFFFF,
};

/// Info needed to request an adapter asynchronously with a certain callback mode.
pub const RequestAdapterCallbackInfo = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    mode: CallBackMode,
    callback: ?*const Instance.RequestAdapterCallback,
    userdata1: ?*anyopaque,
    userdata2: ?*anyopaque,
};

/// Options controlling how we search for a compatible adapter (e.g., backend, fallback, etc.).
pub const RequestAdapterOptions = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    featureLevel: FeatureLevel = .Compatibility,
    powerPreference: PowerPreference = .Undefined,
    forceFallbackAdapter: bool = false,
    backendType: BackendType = .Undefined,
    compatibleSurface: ?Surface.SurfaceImpl = null,
};

/// The minimal or "compatibility" level an adapter must support, e.g. ES 3.1 or better.
pub const FeatureLevel = enum(u32) {
    Compatibility = 0x00000001,
    Core = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// GPU power preference: none, low-power, high-performance, etc.
const PowerPreference = enum(u32){
    Undefined = 0x00000000,
    LowPower = 0x00000001,
    HighPerformance = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Defines how to handle uncaptured errors (e.g. device lost, out of memory).
pub const UncapturedErrorCallbackInfo = struct {
    nextInChain: ?*const ChainedStruct = null,
    callback: ErrorCallback,
    userdata: ?*anyopaque = null,
};

const ErrorCallback = *const fn(
    err_type: ErrorType,
    message: [*c]const u8,
    userdata: ?*anyopaque
) callconv(.C) void;

/// Classifications of error for WebGPU operations.
pub const ErrorType = enum(u32) {
    NoError = 0x00000000,
    Validation = 0x00000001,
    OutOfMemory = 0x00000002,
    Internal = 0x00000003,
    Unknown = 0x00000004,
    DeviceLost = 0x00000005,
    Force32 = 0x7FFFFFFF,
};

/// A descriptor for specifying mandatory device limits.
pub const RequiredLimits = struct {
    nextInChain: ?ChainedStruct,
    limits: Limits,
};

/// Feature names that can be enabled on an adapter or device.
pub const FeatureName = enum(u32) {
    Undefined = 0x00000000,
    DepthClipControl = 0x00000001,
    Depth32FloatStencil8 = 0x00000002,
    TimestampQuery = 0x00000003,
    TextureCompressionBC = 0x00000004,
    TextureCompressionBCSliced3D = 0x00000005,
    TextureCompressionETC2 = 0x00000006,
    TextureCompressionASTC = 0x00000007,
    TextureCompressionASTCSliced3D = 0x00000008,
    IndirectFirstInstance = 0x00000009,
    ShaderF16 = 0x0000000A,
    RG11B10UfloatRenderable = 0x0000000B,
    BGRA8UnormStorage = 0x0000000C,
    Float32Filterable = 0x0000000D,
    Float32Blendable = 0x0000000E,
    ClipDistances = 0x0000000F,
    DualSourceBlending = 0x00000010,
    Force32 = 0x7FFFFFFF,

    // Some extended feature codes
    PushConstants = 196609,
    TextureAdapterSpecificFormatFeatures = 196610,
    MultiDrawIndirect = 196611,
    MultiDrawIndirectCount = 196612,
    VertexWritableStorage = 196613,
    TextureBindingArray = 196614,
    SampledTextureAndStorageBufferArrayNonUniformIndexing = 196615,
    PipelineStatisticsQuery = 196616,
    StorageResourceBindingArray = 196617,
    PartiallyBoundBindingArray = 196618,
    TextureFormat16bitNorm = 196619,
    TextureCompressionAstcHdr = 196620,
    MappablePrimaryBuffers = 196622,
    BufferBindingArray = 196623,
    UniformBufferAndStorageTextureArrayNonUniformIndexing = 196624,
    VertexAttribute64bit = 196633,
    TextureFormatNv12 = 196634,
    RayTracingAccelerationStructure = 196635,
    RayQuery = 196636,
    ShaderF64 = 196637,
    ShaderI16 = 196638,
    ShaderPrimitiveIndex = 196639,
    ShaderEarlyDepthTest = 196640,
};

/// Collection of required GPU resource and usage limits.
pub const Limits = extern struct {
    maxTextureDimension1D: u32 = 0,
    maxTextureDimension2D: u32 = 0,
    maxTextureDimension3D: u32 = 0,
    maxTextureArrayLayers: u32 = 0,
    maxBindGroups: u32 = 0,
    maxBindGroupsPlusVertexBuffers: u32 = 0,
    maxBindingsPerBindGroup: u32 = 0,
    maxDynamicUniformBuffersPerPipelineLayout: u32 = 0,
    maxDynamicStorageBuffersPerPipelineLayout: u32 = 0,
    maxSampledTexturesPerShaderStage: u32 = 0,
    maxSamplersPerShaderStage: u32 = 0,
    maxStorageBuffersPerShaderStage: u32 = 0,
    maxStorageTexturesPerShaderStage: u32 = 0,
    maxUniformBuffersPerShaderStage: u32 = 0,
    maxUniformBufferBindingSize: u64 = 0,
    maxStorageBufferBindingSize: u64 = 0,
    minUniformBufferOffsetAlignment: u32 = 0,
    minStorageBufferOffsetAlignment: u32 = 0,
    maxVertexBuffers: u32 = 0,
    maxBufferSize: u64 = 0,
    maxVertexAttributes: u32 = 0,
    maxVertexBufferArrayStride: u32 = 0,
    maxInterStageShaderComponents: u32 = 0,
    maxInterStageShaderVariables: u32 = 0,
    maxColorAttachments: u32 = 0,
    maxColorAttachmentBytesPerSample: u32 = 0,
    maxComputeWorkgroupStorageSize: u32 = 0,
    maxComputeInvocationsPerWorkgroup: u32 = 0,
    maxComputeWorkgroupSizeX: u32 = 0,
    maxComputeWorkgroupSizeY: u32 = 0,
    maxComputeWorkgroupSizeZ: u32 = 0,
    maxComputeWorkgroupsPerDimension: u32 = 0,
};

/// A 64-bit handle for submission indices on a given queue.
const SubmissionIndex = u64;

/// Holds a queue and the submission index to track GPU operation completions.
pub const WrappedSubmissionIndex = extern struct {
    queue: *const lazyQueue().Queue,
    submissionIndex: SubmissionIndex,
};

/// Load operations for attachments in render passes.
pub const LoadOp = enum(u32) {
    Undefined = 0x00000000,
    Clear = 0x00000001,
    Load = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// Store operations for attachments in render passes.
pub const StoreOp = enum(u32) {
    Undefined = 0x00000000,
    Store = 0x00000001,
    Discard = 0x00000002,
    Force32 = 0x7FFFFFFF,
};

/// A color struct used for specifying clear color values, etc.
pub const Color = extern struct {
    r: f64,
    g: f64,
    b: f64,
    a: f64,
};
