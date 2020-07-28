//
//  GLContext.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>
#import "GLProgram.h"
#import "GLFrameBuffer.h"
#include "GLFrameBufferCache.h"


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

@protocol GLInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(GLFrameBuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;
- (void)setInputRotation:(GLRotationMode)newInputRotation atIndex:(NSInteger)textureIndex;
- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end


#define GPUUnitRotationSwapsWidthAndHeight(rotation) ((rotation) == kGLRotateLeft || (rotation) == kGLRotateRight || (rotation) == kGLRotateRightFlipVertical || (rotation) == kGLRotateRightFlipHorizontal)


@class GLProgram;

@interface GLContext : NSObject

@property (nonatomic, readonly) dispatch_queue_t contextQueue;
@property (nonatomic, strong  ) GLProgram *currentShaderProgram;
@property (nonatomic, strong  ) EAGLContext *context;
@property (nonatomic, readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property (nonatomic, readonly) GLFrameBufferCache *framebufferCache;


+ (void *)contextKey;
+ (GLContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (GLFrameBufferCache *)sharedFramebufferCache;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;
+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;
- (void)setContextShaderProgram:(GLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (GLint)maximumVaryingVectorsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;
- (void)useSharegroup:(EAGLSharegroup *)sharegroup;
// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;


@end



