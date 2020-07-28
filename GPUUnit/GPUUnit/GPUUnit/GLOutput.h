//
//  GLOutput.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLContext.h"
#import "GLFrameBuffer.h"


#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
// For now, just redefine this on the Mac
typedef NS_ENUM(NSInteger, UIImageOrientation) {
    UIImageOrientationUp,            // default orientation
    UIImageOrientationDown,          // 180 deg rotation
    UIImageOrientationLeft,          // 90 deg CCW
    UIImageOrientationRight,         // 90 deg CW
    UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    UIImageOrientationDownMirrored,  // horizontal flip
    UIImageOrientationLeftMirrored,  // vertical flip
    UIImageOrientationRightMirrored, // vertical flip
};
#endif


dispatch_queue_attr_t GLDefaultQueueAttribute(void);
void runOnMainQueueWithoutDeadlocking(void (^block)(void));
void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runSynchronouslyOnContextQueue(GLContext *context, void (^block)(void));
void runAsynchronouslyOnContextQueue(GLContext *context, void (^block)(void));
void reportAvailableMemoryForGPUUnit(NSString *tag);


@class GPUImageMovieWriter;

@interface GLOutput : NSObject{
    GLFrameBuffer       *_outputFrameBuffer;
    NSMutableArray      *_targets;
    NSMutableArray      *_targetTexturesIndices;
    CGSize              _inputTextureSize;
    CGSize              _cachedMaximumOutputSize;
    CGSize              _forcedMaximumSize;
    
    BOOL                _overrideInputSize;
    BOOL                _allTargetsWantMonochromeData;
    BOOL                _usingNextFrameForImageCapture;
    
}

@property (nonatomic, assign) BOOL shouldSmoothlyScaleOutput;
@property (nonatomic, assign) BOOL shouldIgnoreUpdatesToThisTarget;
@property (nonatomic, strong) GPUImageMovieWriter *audioEncodingTarget;
@property (nonatomic, weak) id<GLInput> targetToIgnoreForUpdates;
@property (nonatomic, copy) void(^frameProcessingCompletionBlock)(GLOutput*, CMTime);
@property (nonatomic, assign) BOOL enabled;
@property (nonatomic, assign) GLTextureOptions outputTextureOptions;


- (void)setInputFrameBufferForTarget:(id<GLInput>)target atIndex:(NSInteger)index;
- (GLFrameBuffer *)frameBufferOutput;
- (void)removeOutputFrameBuffer;
- (void)notifyTargetsAboutNewOutputTextures;

- (NSArray *)targets;

- (void)addTarget:(id<GLInput>)target;
- (void)addTarget:(id<GLInput>)target atTextureLocation:(NSInteger)textLocation;

- (void)removeTarget:(id<GLInput>)target;
- (void)removeAllTargets;

- (void)forceProcessingAtSize:(CGSize)frameSize;
- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;

- (void)useNextFrameForImageCapture;
- (CGImageRef)newCGImageFromCurrentlyProcessedOutput;
- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (UIImage *)imageFromCurrentFramebuffer;
- (UIImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter;
- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter;
#else
- (NSImage *)imageFromCurrentFramebuffer;
- (NSImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
- (NSImage *)imageByFilteringImage:(NSImage *)imageToFilter;
- (CGImageRef)newCGImageByFilteringImage:(NSImage *)imageToFilter;
#endif

- (BOOL)providesMonochromeOutput;


@end


