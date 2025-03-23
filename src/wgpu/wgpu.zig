//! [webgpu-native headers](https://webgpu-native.github.io/webgpu-headers/webgpu_8h_source.html)
//! [JS API](https://developer.mozilla.org/en-US/docs/Web/API/WebGPU_API)
const std = @import("std");
const log = std.log.scoped(.@"wgpu");
const Allocator = std.mem.Allocator;

const c = @import("../zgl.zig").c;

const WGPUBool = u32;

// wgpu objects, contains all the methods
// https://webgpu-native.github.io/webgpu-headers/group__Objects.html
pub const Adapter = @import("Adapter.zig").Adapter;
pub const BindGroup = @import("BindGroup.zig").BindGroup; // complete
pub const BindGroupLayout = @import("BindGroupLayout.zig").BindGroupLayout;
pub const Buffer = @import("Buffer.zig").Buffer;
pub const CommandBuffer = @import("CommandBuffer.zig").CommandBuffer;
pub const CommandEncoder = @import("CommandEncoder.zig").CommandEncoder;
pub const ComputePassEncoder = @import("ComputePassEncoder.zig").ComputePassEncoder;
pub const ComputePipeline = @import("ComputePipeline.zig").ComputePipeline;
pub const Device = @import("Device.zig").Device;
pub const Instance = @import("Instance.zig").Instance;
pub const PipelineLayout = @import("PipelineLayout.zig").PipelineLayout;
pub const QuerySet = @import("QuerySet.zig").QuerySet;
pub const Queue = @import("Queue.zig").Queue;
pub const RenderBundle = @import("RenderBundle.zig").RenderBundle;
pub const RenderBundleEncoder = @import("RenderBundleEncoder.zig").RenderBundleEncoder;
pub const RenderPassEncoder = @import("RenderPassEncoder.zig").RenderPassEncoder;
pub const RenderPipeline = @import("RenderPipeline.zig").RenderPipeline;
pub const Sampler = @import("Sampler.zig").Sampler;
pub const ShaderModule = @import("ShaderModule.zig").ShaderModule;
pub const Surface = @import("Surface.zig").Surface;
pub const Texture = @import("Texture.zig").Texture;
pub const TextureView = @import("TextureView.zig").TextureView;

test "api coverage" { // only measures functions as of yet
    
    //std.testing.log_level = .warn;

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();


    const c_info = @typeInfo(c);

    @setEvalBranchQuota(1000000);

    var number_of_c_functions: usize = 0;
    var number_of_implemented_fns: usize = 0;

    var wgpu_functions = std.StringHashMap([]const u8).init(allocator);
    defer {
        var key_iterator = wgpu_functions.keyIterator();

        while (key_iterator.next()) |key| {
            allocator.free(key.*);
        }

        wgpu_functions.deinit();
    }

    inline for (c_info.@"struct".decls) |decl| {


        comptime if (std.mem.indexOf(u8, decl.name, "wgpu") == null) continue;
        comptime if (std.mem.indexOf(u8, decl.name, "_") != null) continue;

        const decl_type = @TypeOf(@field(c, decl.name));

        // log.debug("{s}", .{decl.name});
        // if (decl_type != type) continue;

        const decl_type_info = @typeInfo(decl_type);

        if (decl_type_info != .@"fn") continue;

        log.debug("{s}", .{decl.name});

        var name = try allocator.dupe(u8, decl.name); // freed by HM
        // defer allocator.free(name);

        for (name, 0..) |char, i| {
            name[i] = std.ascii.toLower(char);
        }


        try wgpu_functions.put(name, name);
        number_of_c_functions += 1;

        log.debug("{s}", .{name});
    }

    inline for (@typeInfo(@This()).@"struct".decls) |decl| {
        // log.info("decl = {s}", .{decl.name});
        const t = @field(@This(), decl.name);

        if (@TypeOf(t) != type) {
            log.debug("{s} is not a type", .{decl.name});
            continue;
        }

        // log.info("t = {}", .{t});
        // log.info("t is a type = {}", .{@typeInfo(t) == .@"struct"});
        const t_info = @typeInfo(t);
        switch (t_info) {

            .@"struct" => {
                // log.debug("{s} has declarations:", .{decl.name});

                // inline for (t_info.@"struct".decls) |inner_decl| {
                //     // const inner_t = @field(t, inner_decl.name);
                //     //
                //     // if (@TypeOf(inner_t) != type) {
                //     //     continue;
                //     // }
                //
                //     log.debug("    - {s}", .{inner_decl.name});
                // }

            },
            .pointer => {
                // log.debug("{s} has declarations:", .{decl.name});

                const t_child = @typeInfo(t_info.pointer.child);


                if (t_child == .@"opaque") {

                    inline for (t_child.@"opaque".decls) |inner_decl| {
                        // log.debug("    - {s}", .{inner_decl.name});

                        const wgpu_name = try std.fmt.allocPrint(allocator, "wgpu{s}{s}", .{decl.name, inner_decl.name});
                        defer allocator.free(wgpu_name);

                        for (wgpu_name, 0..) |char, i| wgpu_name[i] = std.ascii.toLower(char);
                        // log.debug("{s}", .{wgpu_name});

                        if (wgpu_functions.get(wgpu_name) != null)  {
                            number_of_implemented_fns += 1;
                        }
                    }

                }

            },

            else => {}
        }


    }

    number_of_implemented_fns += 1;
    try std.testing.expectEqual(number_of_c_functions, number_of_implemented_fns);

}

// Descriptors ================================================================
// TODO: Convert to from and to extern and better zig structs with slices and bools

pub const BindGroupDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    layout: ?BindGroupLayout = null, 
    entryCount: usize = 0, // TODO: use slice
    entries: ?[*]const BindGroupEntry = null
};

pub const BufferDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    usage: Flag = @intFromEnum(BufferUsage.None), // TODO: take a []Usage
    size: u64 = 0,
    mappedAtCreation: bool = false,
};

pub const CommandBufferDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
};

pub const CommandEncoderDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
}; 

pub const ComputePassEncoderDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    timestampWrites: ?*const ComputePassTimeStampWrites = null,
};

pub const ComputePipelineDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    layout: ?PipelineLayout = null,
    compute: ProgrammableStageDescriptor
};

pub const DeviceDescriptor = struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    requiredFeatureCount: usize = 0,
    requiredFeatures: ?[*]const FeatureName = null,
    requiredLimits: ?*const RequiredLimits = null,
    defaultQueue: QueueDescriptor = .{
        .label = .{ .data = "", .length = 0},
        .nextInChain = null
    },
    deviceLostCallback: ?*const DeviceLostCallback = null,
    deviceLostUserdata: ?*anyopaque = null,
    uncapturedErrorCallbackInfo: ?UncapturedErrorCallbackInfo = null
};

pub const InstanceDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    timedWaitAnyEnable: WGPUBool = @intCast(@intFromBool(false)),
    timedWaitAnyMaxCount: usize = 0
};

pub const RenderPassDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    colorAttachmentCount: usize = 0,
    colorAttachments: ?[*]const RenderPassColorAttachment = null,
    depthStencilAttachment: ?*const RenderPassDepthStencilAttachment = null,
    occlusionQuerySet: ?QuerySet = null,
    timestampWrites: ?*const RenderPassTimestampWrites = null
};

pub const RenderPipelineDescriptor = struct {
    nextInChain: ?*const ChainedStruct = null,
    label: []const u8 = "",
    layout: ?PipelineLayout = null,
    vertex: VertexState,
    primitive: PrimitiveState,
    depthStencil: ?*const DepthStencilState = null,
    multisample: MultiSampleState,
    fragment: ?*const FragmentState = null,

    pub fn ToExtern(self: RenderPipelineDescriptor) c.WGPURenderPipelineDescriptor {
        return c.WGPURenderPipelineDescriptor {
            .nextInChain = @ptrCast(self.nextInChain),
            .vertex = self.vertex.ToExtern(),
            .layout = @ptrCast(self.layout),
            .label = c.WGPUStringView{.data = self.label.ptr, .length = self.label.len },
            .fragment = @ptrCast(self.fragment),
            .primitive = c.WGPUPrimitiveState{
                .nextInChain = @ptrCast(self.primitive.nextInChain),
                .topology = @intFromEnum(self.primitive.topology),
                .cullMode = @intFromEnum(self.primitive.cullMode),
                .frontFace = @intFromEnum(self.primitive.frontFace),  
                .unclippedDepth = @intCast(@intFromBool(self.primitive.unclippedDepth)),
                .stripIndexFormat = @intFromEnum(self.primitive.stripIndexFormat)
            },
            .multisample = c.WGPUMultisampleState{
                .nextInChain = @ptrCast(self.multisample.nextInChain),
                .mask = self.multisample.mask,
                .alphaToCoverageEnabled = @intFromBool(self.multisample.alphaToCoverageEnabled),
                .count = self.multisample.count
            },
            .depthStencil = null
        };
    }
};

pub const QueueDescriptor = struct {
    nextInChain: ?ChainedStruct = null,
    label: StringView = .{}
};


pub const ShaderModuleDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
};

pub const SurfaceDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{}
};

pub const TextureUsages = struct {
    CopySrc: bool = false,
    CopyDst: bool = false,
    TextureBinding: bool = false,
    StorageBinding: bool = false,
    RenderAttachment: bool = false,

    pub fn calcFlag(self: *const TextureUsages) Flag {
        var f: Flag = 0;

        inline for (@typeInfo(TextureUsages).@"struct".fields) |field| {

            if (@field(self.*, field.name)) {
                
                f |= @intFromEnum(@field(TextureUsage, field.name));
            }

        }

        return f;
    }
};

// does not match c api
pub const TextureDescriptor = struct {
    next_in_chain: ?*const ChainedStruct = null,
    label: StringView = .{},
    usages: TextureUsages,
    dimension: TextureDimension,
    size: Extend3D,
    format: TextureFormat,
    mip_level_count: u32,
    sample_count: u32,
    view_formats: []const TextureFormat,

    
    pub const ExternalStruct = extern struct {
        nextInChain: ?*const ChainedStruct,
        label: StringView,
        usage: Flag,
        dimension: TextureDimension,
        size: Extend3D,
        format: TextureFormat,
        mipLevelCount: u32,
        sampleCount: u32,
        viewFormatCount: usize,
        viewFormats: [*c]const TextureFormat,
    };

    pub fn External(self: *const TextureDescriptor) ExternalStruct {

        return ExternalStruct {
            .nextInChain = self.next_in_chain,
            .label = self.label,
            .usage = self.usages.calcFlag(),
            .dimension = self.dimension,
            .size = self.size,
            .format = self.format,
            .mipLevelCount = self.mip_level_count,
            .sampleCount = self.sample_count,
            .viewFormatCount = self.view_formats.len,
            .viewFormats = self.view_formats.ptr
        };
        

    }

    
};

pub const TextureViewDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    label: StringView = .{},
    format: TextureFormat,
    dimension: TextureViewDimension,
    baseMipLevel: u32,
    mipLevelCount: u32,
    baseArrayLayer: u32,
    arrayLayerCount: u32,
    aspect: TextureAspect,
    usage: TextureUsage,
};

//=============================================================================

extern "c" fn wgpuCreateInstance(desc: ?*const InstanceDescriptor) ?Instance;
pub fn CreateInstance(descriptor: ?*const InstanceDescriptor) WGPUError!Instance {
    
    log.info("Creating instance...", .{});
    
    const maybe_instance = wgpuCreateInstance(descriptor);

    if (maybe_instance) |instance| {
        log.info("Got instance: {}", .{instance});
        return instance;
    } else {
        log.err("Failed to Create Instance", .{});
        return error.FailedToCreateInstance;
    }
}

pub const Extend3D = extern struct {
    width: u32,
    height: u32,
    depth_or_array_layers: u32
};

pub const MapMode = enum(Flag) {
    None = 0x0000000000000000,
    Read = 0x0000000000000001,
    Write = 0x0000000000000002,
};

pub const MapAsyncStatus =  enum(u32) {
    Success = 0x00000001,
    InstanceDropped = 0x00000002,
    Error = 0x00000003,
    Aborted = 0x00000004,
    Unknown = 0x00000005,
    Force32 = 0x7FFFFFFF
};

pub const Flag = u64;

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
    FailedToCreateBindGroup,
    FailedToGetBindGroupLayout,
    FailedToCreateComputePassEncoder,
    FailedToGetBufferMappedRange,

    FailedToMapBufferBecauseOfError,
    FailedToMapBufferBecauseOfAbort,
    FailedToMapBufferBecauseOfDroppedInstance,
    FailedToMapBufferBecauseOfUnknown,
    FailedToMapBufferBecauseOfForce32,

    FailedToFinishCommandEncoder,

    FailedToCreateCommandEncoder
    
};

pub const ConstantEntry = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    key: [*]const u8,
    value: f64,
};

pub const VertexStepMode = enum(u32) {
    VertexBufferNotUsed = 0x00000000,
    Undefined = 0x00000001,
    Vertex = 0x00000002,
    Instance = 0x00000003,
    Force32 = 0x7FFFFFFF
};


pub const VertexFormat = enum(u32) {
    Uint8 = 0x00000001,
    Uint8x2 = 0x00000002,
    Uint8x4 = 0x00000003,
    Sint8 = 0x00000004,
    Sint8x2 = 0x00000005,
    Sint8x4 = 0x00000006,
    Unorm8 = 0x00000007,
    Unorm8x2 = 0x00000008,
    Unorm8x4 = 0x00000009,
    Snorm8 = 0x0000000A,
    Snorm8x2 = 0x0000000B,
    Snorm8x4 = 0x0000000C,
    Uint16 = 0x0000000D,
    Uint16x2 = 0x0000000E,
    Uint16x4 = 0x0000000F,
    Sint16 = 0x00000010,
    Sint16x2 = 0x00000011,
    Sint16x4 = 0x00000012,
    Unorm16 = 0x00000013,
    Unorm16x2 = 0x00000014,
    Unorm16x4 = 0x00000015,
    Snorm16 = 0x00000016,
    Snorm16x2 = 0x00000017,
    Snorm16x4 = 0x00000018,
    Float16 = 0x00000019,
    Float16x2 = 0x0000001A,
    Float16x4 = 0x0000001B,
    Float32 = 0x0000001C,
    Float32x2 = 0x0000001D,
    Float32x3 = 0x0000001E,
    Float32x4 = 0x0000001F,
    Uint32 = 0x00000020,
    Uint32x2 = 0x00000021,
    Uint32x3 = 0x00000022,
    Uint32x4 = 0x00000023,
    Sint32 = 0x00000024,
    Sint32x2 = 0x00000025,
    Sint32x3 = 0x00000026,
    Sint32x4 = 0x00000027,
    Unorm10_10_10_2 = 0x00000028,
    Unorm8x4BGRA = 0x00000029,
    Force32 = 0x7FFFFFFF
};

pub const VertextAttribute = extern struct {
    format: VertexFormat,
    offset: u64,
    shaderLocation: u32
};

pub const VertexBufferLayout = extern struct {
    stepMode: VertexStepMode,
    arrayStride: u64,
    attributeCount: usize, // TODO: use slice
    attributes: [*]const VertextAttribute
};

// const ExternalVertexState = extern struct {
//     nextInChain: ?*const ChainedStruct = null,
//     module: ShaderModule,
//     entryPoint: StringView = .{},
//     constantCount: usize = 0,
//     constants: ?[*]const ConstantEntry = null,
//     bufferCount: usize = 0,
//     buffers: ?[*]const VertexBufferLayout = null,
// };

pub const VertexState = struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule,
    entryPoint: []const u8 = "", 
    constants: ?[]const ConstantEntry = null,
    buffers: ?[]const VertexBufferLayout = null,

    pub fn ToExtern(self: VertexState) c.WGPUVertexState {

        return c.WGPUVertexState {
            .nextInChain = @ptrCast(self.nextInChain),
            .module = @ptrCast(self.module),
            .entryPoint = c.WGPUStringView{ .data = self.entryPoint.ptr, .length = self.entryPoint.len },
            .constantCount = if (self.constants) |cts| cts.len else 0,
            .constants = if (self.constants) |cts| @ptrCast(cts.ptr) else null,
            .bufferCount = if (self.buffers) |bfs| bfs.len else 0,
            .buffers = @ptrCast(self.buffers)

        };

    }
};

pub const ProgrammableStageDescriptor = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule,
    entryPoint: StringView = .{ .data = "", .length = 0 },
    constantCount: usize = 0,
    constants: ?[*]const ConstantEntry = null,
};

pub const PrimitiveTopology = enum(u32) {
    Undefined = 0x00000000,
    PointList = 0x00000001,
    LineList = 0x00000002,
    LineStrip = 0x00000003,
    TriangleList = 0x00000004,
    TriangleStrip = 0x00000005,
    Force32 = 0x7FFFFFFF
};


pub const IndexFormat = enum(u32) {
    Undefined = 0x00000000,
    Uint16 = 0x00000001,
    Uint32 = 0x00000002,
    Force32 = 0x7FFFFFFF
};


/// in wgpu-native its defined differently.
/// fixed in 
pub const FrontFace = enum(u32) {
    Undefined = 0x00000000,
    CCW = 0x00000001,
    CW = 0x00000002,
    Force32 = 0x7FFFFFFF
};


pub const CullMode = enum(u32) {
    Undefined = 0x00000000,
    None = 0x00000001,
    Front = 0x00000002,
    Back = 0x00000003,
    Force32 = 0x7FFFFFFF
};

pub const PrimitiveState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    topology: PrimitiveTopology = .Undefined,
    stripIndexFormat: IndexFormat = .Undefined,
    frontFace: FrontFace = .Undefined,
    cullMode: CullMode = .None,
    unclippedDepth: bool = false,
    

};


pub const CompareFunction = enum(u32) {
    Undefined = 0x00000000,
    Never = 0x00000001,
    Less = 0x00000002,
    Equal = 0x00000003,
    LessEqual = 0x00000004,
    Greater = 0x00000005,
    NotEqual = 0x00000006,
    GreaterEqual = 0x00000007,
    Always = 0x00000008,
    Force32 = 0x7FFFFFFF
};


pub const StencilOperation = enum(u32) {
    Keep = 0x00000000,
    Zero = 0x00000001,
    Replace = 0x00000002,
    Invert = 0x00000003,
    IncrementClamp = 0x00000004,
    DecrementClamp = 0x00000005,
    IncrementWrap = 0x00000006,
    DecrementWrap = 0x00000007,
    Force32 = 0x7FFFFFFF
};

pub const StencilFaceState = extern struct {
    compare: CompareFunction,
    failOp: StencilOperation,
    depthFailOp: StencilOperation,
    passOp: StencilOperation,
};

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
    depthBiasClamp: f32
};

pub const MultiSampleState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    count: u32,
    mask: u32,
    alphaToCoverageEnabled: bool,
};

/// Supported Features should be freed by deinit() when no longer needed.
pub const SupportedFeatures = extern struct {
    featureCount: usize,
    features: [*c]const FeatureName,
    
    extern "c" fn wgpuSupportedFeaturesFreeMembers(supportedFeatures: SupportedFeatures) void;
    pub fn deinit(self: SupportedFeatures) void {
        wgpuSupportedFeaturesFreeMembers(self);
    }

    pub fn toSlice(self: SupportedFeatures) []const FeatureName {
        var slice: []const FeatureName = undefined;

        slice.ptr = self.features;
        slice.len = self.featureCount;

        return slice;
    }

    
    pub fn format(self: *const SupportedFeatures, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, self);
        }
        for (self.toSlice()) |feature| {
            try writer.print("  - {s}\n", .{@tagName(feature)});
        }
    }


    
};

pub const BlendOperation = enum(u32) {
    Undefined = 0x00000000,
    Add = 0x00000001,
    Subtract = 0x00000002,
    ReverseSubtract = 0x00000003,
    Min = 0x00000004,
    Max = 0x00000005,
    Force32 = 0x7FFFFFFF
};


pub const BlendFactor = enum(u32) {
    Undefined = 0x00000000,
    Zero = 0x00000001,
    One = 0x00000002,
    Src = 0x00000003,
    OneMinusSrc = 0x00000004,
    SrcAlpha = 0x00000005,
    OneMinusSrcAlpha = 0x00000006,
    Dst = 0x00000007,
    OneMinusDst = 0x00000008,
    DstAlpha = 0x00000009,
    OneMinusDstAlpha = 0x0000000A,
    SrcAlphaSaturated = 0x0000000B,
    Constant = 0x0000000C,
    OneMinusConstant = 0x0000000D,
    Src1 = 0x0000000E,
    OneMinusSrc1 = 0x0000000F,
    Src1Alpha = 0x00000010,
    OneMinusSrc1Alpha = 0x00000011,
    Force32 = 0x7FFFFFFF
};

pub const BlendComponent = extern struct {
    operation: BlendOperation,
    srcFactor: BlendFactor,
    dstFactor: BlendFactor
};


pub const BlendState = extern struct {
    color: BlendComponent,
    alpha: BlendComponent
};


pub const ColorWriteMask = enum(Flag) {
    const NONE = 0x00000000;
    const RED = 0x00000001;
    const GREEN = 0x00000002;
    const BLUE = 0x00000004;
    const ALPHA = 0x00000008;
    const ALL = 0x000000000000000F;

    None = 0x0000000000000000,
    Red = 0x0000000000000001,
    Green = 0x0000000000000002,
    Blue = 0x0000000000000004,
    Alpha = 0x0000000000000008,
    All = 0x000000000000000F,
}; 

pub const ColorTargetState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    format: TextureFormat,
    blend: ?*const BlendState,
    writeMask: ColorWriteMask
}; 


pub const ShaderSourceWGSL = extern struct {
    chain: ChainedStruct,
    code: StringView = .{ .data = "", .length = 0},
};

pub const FragmentState = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    module: ShaderModule,
    entryPoint: StringView = .{ .data = "", .length = 0 },
    constantCount: usize = 0,
    constants: ?[*]const ConstantEntry = null,
    targetCount: usize = 0,
    targets:  ?[*]const ColorTargetState = null
};

pub const DepthSlice = enum(u32) {
    Undefined = 0xffffffff,
};

pub const Status = enum(u32) {
    Success = 0x00000001,
    Error = 0x00000002,
    Force32 = 0x7FFFFFFF
};


pub const RequestAdapterStatus = enum(u32) {
    Success = 0x00000001,
    InstanceDropped = 0x00000002,
    Unavailable = 0x00000003,
    Error = 0x00000004,
    Unknown = 0x00000005,
    Force32 = 0x7FFFFFFF
};

const SType = enum(u32) {
    ShaderSourceSPIRV = 0x00000001,
    ShaderSourceWGSL = 0x00000002,
    RenderPassMaxDrawCount = 0x00000003,
    SurfaceSourceMetalLayer = 0x00000004,
    SurfaceSourceWindowsHWND = 0x00000005,
    SurfaceSourceXlibWindow = 0x00000006,
    SurfaceSourceWaylandSurface = 0x00000007,
    SurfaceSourceAndroidNativeWindow = 0x00000008,
    SurfaceSourceXCBWindow = 0x00000009,
    Force32 = 0x7FFFFFFF
};

pub const SurfaceGetCurrentTextureStatus = enum(u32) {
    /// Yay! Everything is good and we can render this frame.
    SuccessOptimal = 0x00000001,

    /// Still OK - the surface can present the frame, but in a suboptimal way. The surface may need reconfiguration.
    SuccessSuboptimal = 0x00000002,
    
    /// Some operation timed out while trying to acquire the frame.
    Timeout = 0x00000003,

    /// The surface is too different to be used, compared to when it was originally created.
    Outdated = 0x00000004,

    ///The connection to whatever owns the surface was lost.
    Lost = 0x00000005,

    /// The system ran out of memory.
    OutOfMemory = 0x00000006,
    
    /// The @ref WGPUDevice configured on the @ref WGPUSurface was lost.
    DeviceLost = 0x00000007,

    /// The surface is not configured, or there was an @ref OutStructChainError.
    Error = 0x00000008,
    Force32 = 0x7FFFFFFF
};


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
    Force32 = 0x7FFFFFFF
};


pub const CompositeAlphaMode = enum(u32) {
    /// Lets the WebGPU implementation choose the best mode (supported, and with the best performance) between
    Auto = 0x00000000,

    /// The alpha component of the image is ignored and teated as if it is always 1.0.
    Opaque = 0x00000001,

    /// The alpha component is respected and non-alpha components are assumed to be already multiplied with 
    /// the alpha component. For example, (0.5, 0, 0, 0.5) is semi-transparent bright red.
    Premultiplied = 0x00000002,

    /// The alpha component is respected and non-alpha components are assumed to 
    /// NOT be already multiplied with the alpha component. For example, (1.0, 0, 0, 0.5) is semi-transparent bright red.
    Unpremultiplied = 0x00000003,
    
    /// The handling of the alpha component is unknown to WebGPU and should be handled by the application 
    /// using system-specific APIs. This mode may be unavailable (for example on Wasm).
    Inherit = 0x00000004,

    Force32 = 0x7FFFFFFF
};

///https://webgpu-native.github.io/webgpu-headers/group__Enumerations.html#ga9a635cf4a9ef07c0211b7cdbfb3eb60c
pub const PresentMode = enum(u32) {
    // TODO: document meaning
    Undefined = 0x00000000,
    Fifo = 0x00000001,
    FifoRelaxed = 0x00000002,
    Immediate = 0x00000003,
    Mailbox = 0x00000004,
    Force32 = 0x7FFFFFFF
};




pub const TextureViewDimension = enum(u32) {
    Undefined = 0x00000000,
    @"1D" = 0x00000001,
    @"2D" = 0x00000002,
    @"2DArray" = 0x00000003,
    Cube = 0x00000004,
    CubeArray = 0x00000005,
    @"3D" = 0x00000006,
    Force32 = 0x7FFFFFFF
};


pub const TextureAspect = enum(u32) {
    Undefined = 0x00000000,
    All = 0x00000001,
    StencilOnly = 0x00000002,
    DepthOnly = 0x00000003,
    Force32 = 0x7FFFFFFF
};

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
    Force32 = 0x7FFFFFFF
};


pub const TextureUsage = enum(Flag) {
    // TODO: document meaning
    None = 0x00000000,
    CopySrc = 0x00000001,
    CopyDst = 0x00000002,
    TextureBinding = 0x00000004,
    StorageBinding = 0x00000008,
    RenderAttachment = 0x00000010,
    Force32 = 0x7FFFFFFF
};

pub const TextureDimension = enum(u32) {
    Undefined = 0x00000000,
    @"1D" = 0x00000001,
    @"2D" = 0x00000002,
    @"3D" = 0x00000003,
    Force32 = 0x7FFFFFFF
};

pub const ChainedStruct = extern struct {
    next: ?*const ChainedStruct = null,
    sType: SType,
};

pub const ChainedStructOut = extern struct {
    next: ?*const ChainedStructOut,
    sType: SType,
};

pub const StringView = extern struct {
    data: ?[*:0]const u8 = null,
    length: usize = 0,

    pub fn toSlice(stringView: StringView) []const u8 {
        var slice: []const u8 = "";

        if (stringView.data) |data| slice.ptr = data;
        slice.len = stringView.length;

        return slice;
    }

    pub fn fromSlice(slice: []const u8) StringView {
        return StringView {
            .data = @ptrCast(slice),
            .length = slice.len
        };
    }
};

pub const Future = u64;

/// The callback mode controls how a callback for an asynchronous operation may be fired. 
/// See Asynchronous Operations for how these are used.
pub const CallBackMode = enum(u32) { // TODO: fix doc.

    /// Callbacks created with `WGPUCallbackMode_WaitAnyOnly`:
    ///     - fire when the asynchronous operation's future is passed to a call to `::wgpuInstanceWaitAny`
    /// AND the operation has already completed or it completes inside the call to `::wgpuInstanceWaitAny`.
    WaitAnyOnly = 0x00000001,

    /// Callbacks created with `WGPUCallbackMode.AllowProcessEvents`:
    ///  - fire for the same reasons as callbacks created with `WGPUCallbackMode_WaitAnyOnly`
    ///  - fire inside a call to `::wgpuInstanceProcessEvents` if the asynchronous operation is complete.
    AllowProcessEvents = 0x00000002,

    /// Callbacks created with `WGPUCallbackMode_AllowSpontaneous`:
    /// - fire for the same reasons as callbacks created with `WGPUCallbackMode_AllowProcessEvents`
    /// - **may** fire spontaneously on an arbitrary or application thread, when the WebGPU implementations discovers that the asynchronous operation is complete.
    /// 
    /// Implementations _should_ fire spontaneous callbacks as soon as possible.
    /// 
    /// @note Because spontaneous callbacks may fire at an arbitrary time on an arbitrary thread, applications should take extra care when acquiring locks or mutating state inside the callback. It undefined behavior to re-entrantly call into the webgpu.h API if the callback fires while inside the callstack of another webgpu.h function that is not `wgpuInstanceWaitAny` or `wgpuInstanceProcessEvents`.
    AllowSpontaneous = 0x00000003,
    Force32 = 0x7FFFFFFF
};

pub const RequestAdapterOptions = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    featureLevel: FeatureLevel = .Compatibility,
    powerPreference: PowerPreference = .Undefined,

    /// If true, requires the adapter to be a "fallback" adapter as defined by the JS spec.
    /// If this is not possible, the request returns null.
    forceFallbackAdapter: bool = false,

    /// If set, requires the adapter to have a particular backend type.
    /// If this is not possible, the request returns null.
    backendType: BackendType = .Undefined,

    /// If set, requires the adapter to be able to output to a particular surface.
    /// If this is not possible, the request returns null.
    compatibleSurface: ?Surface = null,

};

/// "Feature level" for the adapter request. If an adapter is returned, 
/// it must support the features and limits in the requested feature level.
pub const FeatureLevel = enum(u32) {
    /// "Compatibility" profile which can be supported on OpenGL ES 3.1.
    Compatibility = 0x00000001,
    /// "Core" profile which can be supported on Vulkan/Metal/D3D12.
    Core = 0x00000002,
    Force32 = 0x7FFFFFFF
};

const PowerPreference = enum(u32){
    Undefined = 0x00000000,
    LowPower = 0x00000001,
    HighPerformance = 0x00000002,
    Force32 = 0x7FFFFFFF
};

pub const UncapturedErrorCallbackInfo = struct {
    nextInChain: ?*const ChainedStruct = null,
    callback: ErrorCallback,
    userdata: ?*anyopaque = null,
};

const ErrorCallback = *const fn(
    type: ErrorType,
    message: [*c]const u8, // TODO: Change to StringView
    userdata: ?*anyopaque
) callconv(.C) void;


pub const ErrorType = enum(u32) {
    NoError = 0x00000000,
    Validation = 0x00000001,
    OutOfMemory = 0x00000002,
    Internal = 0x00000003,
    Unknown = 0x00000004,
    DeviceLost = 0x00000005,
    Force32 = 0x7FFFFFFF
};


pub const RequiredLimits = struct {
    nextInChain: ?ChainedStruct,
    limits: Limits
};


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

    // not part of webgpu.h
    WGPUNativeFeature_PushConstants = 0x00030001,
    WGPUNativeFeature_TextureAdapterSpecificFormatFeatures = 0x00030002,
    WGPUNativeFeature_MultiDrawIndirect = 0x00030003,
    WGPUNativeFeature_MultiDrawIndirectCount = 0x00030004,
    WGPUNativeFeature_VertexWritableStorage = 0x00030005,
    WGPUNativeFeature_TextureBindingArray = 0x00030006,
    WGPUNativeFeature_SampledTextureAndStorageBufferArrayNonUniformIndexing = 0x00030007,
    WGPUNativeFeature_PipelineStatisticsQuery = 0x00030008,
    WGPUNativeFeature_StorageResourceBindingArray = 0x00030009,
    WGPUNativeFeature_PartiallyBoundBindingArray = 0x0003000A,
    WGPUNativeFeature_TextureFormat16bitNorm = 0x0003000B,
    WGPUNativeFeature_TextureCompressionAstcHdr = 0x0003000C,
    WGPUNativeFeature_MappablePrimaryBuffers = 0x0003000E,
    WGPUNativeFeature_BufferBindingArray = 0x0003000F,
    WGPUNativeFeature_UniformBufferAndStorageTextureArrayNonUniformIndexing = 0x00030010,
    // TODO: requires wgpu.h api change
    // WGPUNativeFeature_AddressModeClampToZero = 0x00030011,
    // WGPUNativeFeature_AddressModeClampToBorder = 0x00030012,
    // WGPUNativeFeature_PolygonModeLine = 0x00030013,
    // WGPUNativeFeature_PolygonModePoint = 0x00030014,
    // WGPUNativeFeature_ConservativeRasterization = 0x00030015,
    // WGPUNativeFeature_ClearTexture = 0x00030016,
    WGPUNativeFeature_SpirvShaderPassthrough = 0x00030017,
    // WGPUNativeFeature_Multiview = 0x00030018,
    WGPUNativeFeature_VertexAttribute64bit = 0x00030019,
    WGPUNativeFeature_TextureFormatNv12 = 0x0003001A,
    WGPUNativeFeature_RayTracingAccelerationStructure = 0x0003001B,
    WGPUNativeFeature_RayQuery = 0x0003001C,
    WGPUNativeFeature_ShaderF64 = 0x0003001D,
    WGPUNativeFeature_ShaderI16 = 0x0003001E,
    WGPUNativeFeature_ShaderPrimitiveIndex = 0x0003001F,
    WGPUNativeFeature_ShaderEarlyDepthTest = 0x00030020,
    WGPUNativeFeature_Subgroup = 0x00030021,
    WGPUNativeFeature_SubgroupVertex = 0x00030022,
    WGPUNativeFeature_SubgroupBarrier = 0x00030023,
    WGPUNativeFeature_TimestampQueryInsideEncoders = 0x00030024,
    WGPUNativeFeature_TimestampQueryInsidePasses = 0x00030025,


};

pub const Limits = extern struct {
    nextInChain: ?*const ChainedStructOut = null,
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
    maxUniformBuffersPerShaderStage: u32 =0,
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

    
    pub fn format(limits: *const Limits, comptime fmt: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        if (fmt.len != 0) {
            std.fmt.invalidFmtError(fmt, limits);
        }

        inline for (@typeInfo(@TypeOf(limits.*)).@"struct".fields, 0..) |field, i| {
            if (i == 0) continue; // skip printing nextInChain
            try writer.print(" - {s}: {}\n", .{field.name, @field(limits, field.name)});
        }

    }
};


const SubmissionIndex = u64;

pub const WrappedSubmissionIndex = extern struct {
    queue: *const Queue,
    submissionIndex: SubmissionIndex
};


pub const LoadOp = enum(u32) {
    Undefined = 0x00000000,
    Load = 0x00000001,
    Clear = 0x00000002,
    Force32 = 0x7FFFFFFF
};


pub const StoreOp = enum(u32) {
    Undefined = 0x00000000,
    Store = 0x00000001,
    Discard = 0x00000002,
    Force32 = 0x7FFFFFFF
};

pub const BindGroupEntry = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    binding: u32,
    buffer: ?Buffer = null,
    offset: u64 = 0,
    size: u64 = 0,
    sampler: ?Sampler = null,
    textureView: ?TextureView = null,
};


pub const ComputePassTimeStampWrites = extern struct {
    querySet: QuerySet, 
    beginningOfPassWriteIndex: u32 = 0,
    endOfPassWriteIndex: u32 = 0
};


pub const RenderPassDepthStencilAttachment = extern struct {
    view: TextureView,
    depthLoadOp: LoadOp,
    depthStoreOp: StoreOp,
    depthClearValue: f32,
    depthReadOnly: bool,
    stencilLoadOp: LoadOp,
    stencilStoreOp: StoreOp,
    stencilClearValue: u32,
    stencilReadOnly: bool,
};


pub const RenderPassTimestampWrites = extern struct {
    querySet: QuerySet,
    beginningOfPassWriteIndex: u32,
    endOfPassWriteIndex: u32
};

pub const RenderPassColorAttachment = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    view: ?TextureView = null,
    depthSlice: DepthSlice = .Undefined,
    resolveTarget: ?TextureView = null,
    loadOp: LoadOp,
    storeOp: StoreOp,
    clearValue: Color
};

pub const Color = extern struct { 
    r: f64,
    g: f64,
    b: f64,
    a: f64,
};

pub const DeviceLostCallback = fn(
    reason: DeviceLostReason, 
    message: [*c]const u8,
    userdata: ?*anyopaque
) callconv(.C) void;

pub const DeviceLostReason = enum(u32) {
    Unknown = 0x00000001,
    Destroyed = 0x00000002,
    Force32 = 0x7FFFFFFF
};

/// https://gpuweb.github.io/gpuweb/#buffer-usage
pub const BufferUsage = enum(Flag) {
    None = 0x0000000000000000,
    /// The buffer can be mapped for reading. May only be combined with CopyDst.
    MapRead = 0x0000000000000001,
    /// The buffer can be mapped for writing. May only be combined with CopySrc.
    MapWrite = 0x0000000000000002,
    /// The buffer can be used as the source of a copy operation.
    CopySrc = 0x0000000000000004,
    /// The buffer can be used as the destination of a copy or write operation. 
    CopyDst = 0x0000000000000008,
    /// The buffer can be used as an index buffer. 
    Index = 0x0000000000000010,
    /// The buffer can be used as a vertex buffer.
    Vertex = 0x0000000000000020,
    /// The buffer can be used as a uniform buffer.
    Uniform = 0x0000000000000040,
    /// The buffer can be used as a storage buffer.
    Storage = 0x0000000000000080,
    /// The buffer can be used as to store indirect command arguments. 
    Indirect = 0x0000000000000100,
    /// The buffer can be used to capture query results.
    QueryResolve = 0x0000000000000200,
};


// Surface structs ============================================================
pub const SurfaceSourceFromMetalLayer = extern struct {
    chain: ChainedStruct,
    layer: *anyopaque
};

pub const SurfaceSourceFromWindowsHWND = extern struct {
    chain: ChainedStruct,
    hinstance: *anyopaque,
    hwnd: *anyopaque,

};

pub const SurfaceSourceFromXlibWindow = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    window: u64,
};

pub const SurfaceSourceFromWaylandSurface = extern struct {
    chain: ChainedStruct,
    display: *anyopaque,
    surface: *anyopaque
};


/// https://webgpu-native.github.io/webgpu-headers/structWGPUSurfaceConfiguration.html
pub const SurfaceConfiguration = extern struct {
    nextInChain: ?*const ChainedStruct = null,
    device: ?Device = null,
    format: TextureFormat = .Undefined,
    usage: TextureUsage = .RenderAttachment,
    width: u32 = 0,
    height: u32 = 0,
    viewFormatCount: usize = 0, // TODO: use slice
    viewFormats: ?[*]const TextureFormat = null,
    alphaMode: CompositeAlphaMode = .Auto,
    presentMode: PresentMode = .Undefined,
};

pub const SurfaceTexture = extern struct {
    nextInChain: ?*const ChainedStructOut = null,
    texture: ?Texture = null,
    status: SurfaceGetCurrentTextureStatus = .DeviceLost
};
//=============================================================================

/// Convert wgpu type to those defined in webgpu.h and wgpu.h translated by zig
inline fn ToExternalType(ExternalType: type, from: anytype) ExternalType {
    std.debug.print("\n", .{});

    // rules c_type <- zig type
    // 
    // - WGPUBool(u32) <- @intFromBool(bool)
    // - ... <- slice.ptr
    // - ...Count <- slice.len
    // - enum(c_int) <- @intFromEnum(enum)
    //
    // wgpu don't have slice instead they have a manyitem poiner field 
    // and a length field. For example 
    //  buffers: [*c]const Buffer
    //  bufferCount: u64
    // they follow the same naming.
    //  

    const external_info = @typeInfo(ExternalType);
    const from_typeinfo = @typeInfo(@TypeOf(from));

    const exernal_name = @typeName(ExternalType);
    switch (external_info) {

        .@"struct" => {
            
            var out = ExternalType{};


            log.debug("converting {s} to {s}", .{ @typeName(@TypeOf(from)), exernal_name });

            inline for (external_info.@"struct".fields) |field| {

                const native_val = @field(from, field.name);

                log.debug("setting field {s} which is a {} to {any}", .{field.name, field.type, native_val});

                // check if field contains Count
                if (std.mem.indexOf(u8, field.name, "Count")) |_|{
                    log.debug("field contains Count", .{});

                }

                @field(out, field.name) = ToExternalType(field.type, native_val);

            }

            
            return out;

        },

        .pointer => |ptr| {

            log.debug("got a ptr of kind: {}", .{ptr.child});
            log.debug("native = {any}", .{from});


            log.debug("fromType is of type {any}", .{@TypeOf(from)});
            std.debug.assert(from_typeinfo == .pointer or from_typeinfo == .optional);

            return @ptrCast(from);

        },

        .int => {

            switch (from_typeinfo) {
                .bool => return @intFromBool(from),
                .int => return @intCast(from),
                inline else => {
                    @panic("unsupported conversion to int");
                }
                

            }

        },

        inline else => |kind| {
            log.debug("{} isnt yet implemened", .{kind});
        }
        

    }

    @panic("not implemented");


}


test "native zig type to wgpu c type" {
    //std.testing.log_level = .debug;

    const native_buffer_desc = BufferDescriptor{
        .label = StringView.fromSlice("hi"),
        .size = 15,
        .usage = @intFromEnum(BufferUsage.Vertex),
        .mappedAtCreation = true
    };

    const ext_buffer_desc = ToExternalType(c.WGPUBufferDescriptor, &native_buffer_desc);

    try std.testing.expectEqual(@TypeOf(ext_buffer_desc), c.WGPUBufferDescriptor);
    try std.testing.expectEqual(ext_buffer_desc.label.data, native_buffer_desc.label.data.?);
    try std.testing.expectEqual(ext_buffer_desc.size, native_buffer_desc.size);
    try std.testing.expectEqual(ext_buffer_desc.mappedAtCreation, @intFromBool(native_buffer_desc.mappedAtCreation));
    // try std.testing.expectEqual(ext.nextInChain, native.nextInChain)


    // const native_bindgroup_desc = BindGroupDescriptor {};

    // const ext_bindgroup_desc = ToExternalType(c., native_buffer_desc);


}
