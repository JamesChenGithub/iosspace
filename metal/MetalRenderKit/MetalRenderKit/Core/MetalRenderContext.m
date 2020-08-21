//
//  MetalRenderContext.m
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "MetalRenderContext.h"

@implementation MetalRenderContext

+ (instancetype)sharedContext {
    static MetalRenderContext *sharedKit = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedKit = [[MetalRenderContext alloc] init];
    });
    return sharedKit;
}

- (instancetype)init {
    if (self = [super init]) {
        _metalDevice = MTLCreateSystemDefaultDevice();
        _metalLibrary = [_metalDevice newDefaultLibrary];
        _metalCommandQueue = [_metalDevice newCommandQueue];
    }
    return self;
}

- (id<MTLTexture>)textureFromPixelBuffer:(CVPixelBufferRef)videoPixelBuffer {
    id<MTLTexture> texture = nil;
    size_t width = CVPixelBufferGetWidth(videoPixelBuffer);
    size_t height = CVPixelBufferGetHeight(videoPixelBuffer);
    MTLPixelFormat pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    CVMetalTextureCacheRef textureCache;
    CVMetalTextureRef metalTextureRef = NULL;
    
    CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, _metalDevice, nil, &textureCache);
    
    CVReturn status = CVMetalTextureCacheCreateTextureFromImage(NULL, textureCache, videoPixelBuffer, NULL, pixelFormat, width, height, 0, &metalTextureRef);
    
    if (status == kCVReturnSuccess) {
        texture = CVMetalTextureGetTexture(metalTextureRef);
    }
    CFRelease(metalTextureRef);
    CFRelease(textureCache);
    
    return texture;
}
@end
