//
//  RenderView.m
//  MetalVideo
//
//  Created by 陈耀武 on 2020/8/20.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "RenderView.h"
#import <Metal/Metal.h>

@interface RenderView ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) CAMetalLayer  *metalLayer;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLRenderPipelineState> pipelineState;

@property (nonatomic, strong) id<MTLTexture> texture;
@property (nonatomic, strong) id<MTLTexture> textureY;
@property (nonatomic, strong) id<MTLTexture> textureUV;

@property (nonatomic, strong) MTLTextureDescriptor *textureDes;
@property (nonatomic, strong) MTLTextureDescriptor *textureYDes;
@property (nonatomic, strong) MTLTextureDescriptor *textureUVDes;

@property (nonatomic, assign) int textureWidth;
@property (nonatomic, assign) int textureHeight;


@end

@implementation RenderView

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.metalLayer.frame = self.bounds;
    self.metalLayer.drawableSize = self.bounds.size;
}

-(void)prepareLayer {
    self.device = MTLCreateSystemDefaultDevice();
    self.metalLayer = (CAMetalLayer *)self.layer;
    
    self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.metalLayer.framebufferOnly = YES;
    self.metalLayer.drawableSize = self.bounds.size;
    self.metalLayer.device = self.device;
}

- (void)preparePipelineState{
    id<MTLLibrary> library = [self.device newDefaultLibrary];
    id<MTLFunction> vertextFunc = [library newFunctionWithName:@"texture_vertex"];
    id<MTLFunction> fragementFunc = [library newFunctionWithName:@"nv12_fragment"];
    
    MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = vertextFunc;
    desc.fragmentFunction = fragementFunc;
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    id<MTLRenderPipelineState> pipelineState = [self.device newRenderPipelineStateWithDescriptor:desc error:nil];
    self.pipelineState = pipelineState;
}

- (void)prepareCommandQueue {
    self.commandQueue = [self.device newCommandQueue];
}

- (void)commonInit{
    [self prepareLayer];
    [self preparePipelineState];
    [self prepareCommandQueue];
}


-(void)renderRGBAWith:(uint8_t*)RGBBuffer width:(int)width height:(int)height {
    if (!self.textureDes || self.textureWidth != width || self.textureHeight != height) {
        self.textureDes = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm width:width height:height mipmapped:NO];
    }
    
    self.texture = [self.device newTextureWithDescriptor:self.textureDes];
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [self.texture replaceRegion:region mipmapLevel:0 withBytes:RGBBuffer bytesPerRow:width * 4];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *renderPassDes = [[MTLRenderPassDescriptor alloc] init];
    renderPassDes.colorAttachments[0].texture = [drawable texture];
    renderPassDes.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDes.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    renderPassDes.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    
    float vertexArray[] = {
        -1.0, -1.0,0, 1.0,
        1.0, -1.0, 0, 1.0,
        -1.0,  1.0, 0, 1.0,
        1.0,  1.0, 0, 1.0,
    };
    
    id<MTLBuffer> vertextBuffer = [self.device newBufferWithBytes:vertexArray length:sizeof(vertexArray) options:MTLResourceCPUCacheModeDefaultCache];
    [renderEncoder setVertexBuffer:vertextBuffer offset:0 atIndex:0];
    
    float textureCoord[] = {
        0,0,
        1,0,
        0,1,
        1,1
    };
    
    id<MTLBuffer> textureCoordBuffer = [self.device newBufferWithBytes:textureCoord length:sizeof(textureCoord) options:MTLResourceCPUCacheModeDefaultCache];
    
    [renderEncoder setVertexBuffer:textureCoordBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:self.texture atIndex:0];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [renderEncoder endEncoding];
    
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

-(void)renderNV12With:(uint8_t*)yBuffer uvBuffer:(uint8_t*)uvBuffer width:(int)width height:(int)height {
    if (!self.textureY || self.textureWidth != width || self.textureHeight != height) {
        self.textureYDes  = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:width height:height mipmapped:NO];
    }
    
    self.textureY = [self.device newTextureWithDescriptor:self.textureYDes];
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [self.textureY replaceRegion:region mipmapLevel:0 withBytes:yBuffer bytesPerRow:width];
    
    if (!self.textureUV || self.textureWidth != width || self.textureHeight != height) {
        self.textureUVDes  = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Unorm width:width/2 height:height/2 mipmapped:NO];
    }
    
    region = MTLRegionMake2D(0, 0, width/2, height/2);
    self.textureUV = [self.device newTextureWithDescriptor:self.textureUVDes];
    [self.textureUV replaceRegion:region mipmapLevel:0 withBytes:uvBuffer bytesPerRow:width];
    
    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
    
    MTLRenderPassDescriptor *renderPassDes = [[MTLRenderPassDescriptor alloc] init];
    renderPassDes.colorAttachments[0].texture = [drawable texture];
    renderPassDes.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDes.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0);
    renderPassDes.colorAttachments[0].storeAction = MTLStoreActionStore;
    
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDes];
    [renderEncoder setRenderPipelineState:self.pipelineState];
    
    //    float[] coordinate = new float[]{
    //        -1.0f, -1.0f,     //左下角坐标
    //         1.0f, -1.0f,     //右下角坐标
    //        -1.0f,  1.0f,     //左上角坐标
    //         1.0f,  1.0f      //右上角坐标
    //    }
    //    float[] TEXTURE_NO_ROTATION[] = {
    //            0.0f, 0.0f,//左下角
    //            1.0f, 0.0f,//右下角
    //            0.0f, 1.0f,//左上角
    //            1.0f, 1.0f,//右上角
    //    };
    
    float vertexArray[] = {
        -1.0, -1.0, 0, 1.0,
        1.0, -1.0, 0, 1.0,
        -1.0,  1.0, 0, 1.0,
        1.0,  1.0, 0, 1.0,
    };
    
    id<MTLBuffer> vertextBuffer = [self.device newBufferWithBytes:vertexArray length:sizeof(vertexArray) options:MTLResourceCPUCacheModeDefaultCache];
    [renderEncoder setVertexBuffer:vertextBuffer offset:0 atIndex:0];
    
    float textureCoord[] = {
        0,1,
        1,1,
        0,0,
        1,0
    };
    id<MTLBuffer>textureCoordBuffer = [self.device newBufferWithBytes:textureCoord length:sizeof(textureCoord) options:MTLResourceCPUCacheModeDefaultCache];
    
    [renderEncoder setVertexBuffer:textureCoordBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:self.textureY atIndex:0];
    [renderEncoder setFragmentTexture:self.textureUV atIndex:1];
    
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}
@end
