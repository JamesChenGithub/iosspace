//
//  GLContext.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, GLRotationMode) {
    kGLNoRotation,
    kGLRotateLeft,
    kGLRotateRight,
    kGLFlipVertical,
    kGLFlipHorizonal,
    kGLRotateRightFlipVertical,
    kGLRotateRightFlipHorizontal,
    kGLRotate180
};

#define GPUUnitRotationSwapsWidthAndHeight(rotation) ((rotation) == kGPUImageRotateLeft || (rotation) == kGPUImageRotateRight || (rotation) == kGPUImageRotateRightFlipVertical || (rotation) == kGPUImageRotateRightFlipHorizontal)


@class EAGLContext;
@class GLProgram;

@interface GLContext : NSObject

@property (nonatomic, readonly) dispatch_queue_t contextQueue;
@property(readonly, nonatomic) EAGLContext *context;
@property(readonly, nonatomic) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly) GPUImageFramebufferCache *framebufferCache;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(strong, nonatomic) GLProgram *currentShaderProgram;
@end


