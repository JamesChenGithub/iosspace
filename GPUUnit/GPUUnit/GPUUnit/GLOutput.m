//
//  GLOutput.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLOutput.h"
#import <mach/mach.h>


dispatch_queue_attr_t GLDefaultQueueAttribute(void)
{
#if TARGET_OS_IPHONE
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
#endif
    return nil;
}

void runOnMainQueueWithoutDeadlocking(void (^block)(void))
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void)) {
    dispatch_queue_t vpqueue = [GLContext sharedContextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([GLContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(vpqueue, block);
        }
}
void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void)) {
    dispatch_queue_t vpqueue = [GLContext sharedContextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([GLContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(vpqueue, block);
        }
}
void runSynchronouslyOnContextQueue(GLContext *context, void (^block)(void)) {
    dispatch_queue_t vpqueue = [context contextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([GLContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(vpqueue, block);
        }
}
void runAsynchronouslyOnContextQueue(GLContext *context, void (^block)(void)) {
    dispatch_queue_t vpqueue = [context contextQueue];
    
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([GLContext contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(vpqueue, block);
        }
}
void reportAvailableMemoryForGPUUnit(NSString *tag) {
    if (!tag)
        tag = @"Default";
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info,  &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"%@ - Memory used: %u", tag, (unsigned int)info.resident_size); //in bytes
    } else {
        NSLog(@"%@ - Error: %s", tag, mach_error_string(kerr));
    }
}



@implementation GLOutput

- (instancetype)init {
    if (self = [super init]) {
        _targets = [[NSMutableArray alloc] init];
        _targetTexturesIndices = [[NSMutableArray alloc] init];
        _enabled = YES;
        _allTargetsWantMonochromeData = YES;
        _usingNextFrameForImageCapture = NO;
        
        _outputTextureOptions = kDefaultGLTextureOptions();
    
    }
    return self;
}

- (void)dealloc
{
    [self removeATllargets];
}

- (void)setInputFrameBufferForTarget:(id<GLInput>)target atIndex:(NSInteger)index {
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:index];
}

- (GLFrameBuffer *)framebufferForOutput;
{
    return _outputFrameBuffer;
}

- (void)removeOutputFrameBuffer {
    _outputFrameBuffer = nil;
}

- (void)notifyTargetsAboutNewOutputTextures {
    for (id<GLInput> curtarget in _targets) {
        NSInteger idx = [_targets indexOfObject:curtarget];
        NSInteger txtIdc = [[_targetTexturesIndices objectAtIndex:idx] integerValue];
        
        [self setInputFrameBufferForTarget:curtarget atIndex:txtIdc];
    }
}

- (NSArray *)targets {
    return [NSArray arrayWithArray:_targets];
}

- (void)addTarget:(id<GLInput>)newTarget {
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
    
    if ([newTarget shouldIgnoreUpdatesToThisTarget])
    {
        _targetToIgnoreForUpdates = newTarget;
    }
}

- (void)addTarget:(id<GLInput>)newTarget atTextureLocation:(NSInteger)textLocation {
    if ([_targets containsObject:newTarget]) {
        return;
    }
    
    _cachedMaximumOutputSize = CGSizeZero;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [self setInputFrameBufferForTarget:newTarget atIndex:textLocation];
        [self->_targets addObject:newTarget];
        [self->_targetTexturesIndices addObject:@(textLocation)];
        self->_allTargetsWantMonochromeData = self->_allTargetsWantMonochromeData && [newTarget wantsMonochromeInput];
    });
}

- (void)removeTarget:(id<GLInput>)targetToRemove {
    if(![_targets containsObject:targetToRemove])
    {
        return;
    }
    
    if (_targetToIgnoreForUpdates == targetToRemove)
    {
        _targetToIgnoreForUpdates = nil;
    }
    
    _cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [_targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[_targetTexturesIndices objectAtIndex:indexOfObject] integerValue];

    runSynchronouslyOnVideoProcessingQueue(^{
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
        [targetToRemove setInputRotation:kGLNoRotation atIndex:textureIndexOfTarget];

        [self->_targetTexturesIndices removeObjectAtIndex:indexOfObject];
        [self->_targets removeObject:targetToRemove];
        [targetToRemove endProcessing];
    });
}

- (void)removeAllTargets;
{
    _cachedMaximumOutputSize = CGSizeZero;
    runSynchronouslyOnVideoProcessingQueue(^{
        for (id<GLInput> targetToRemove in self->_targets) {
            NSInteger indexOfObject = [self->_targets indexOfObject:targetToRemove];
            NSInteger textureIndexOfTarget = [[self->_targetTexturesIndices objectAtIndex:indexOfObject] integerValue];
            
            [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
            [targetToRemove setInputRotation:kGLNoRotation atIndex:textureIndexOfTarget];
        }
        [self->_targets removeAllObjects];
        [self->_targetTexturesIndices removeAllObjects];
        
        self->_allTargetsWantMonochromeData = YES;
    });
}

- (void)forceProcessingAtSize:(CGSize)frameSize {
    
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize{
    
}

- (void)useNextFrameForImageCapture {
    
}

- (CGImageRef)newCGImageByFilteringCGImage:(CGImageRef)imageToFilter {
    // TODO
    return imageToFilter;
}

- (BOOL)providesMonochromeOutput {
    return NO;
}
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
- (UIImage *)imageFromCurrentFramebuffer {
    UIDeviceOrientation devOr = [[UIDevice currentDevice] orientation];
    UIImageOrientation imgOr = UIImageOrientationLeft;
    
    switch (devOr) {
        case UIDeviceOrientationPortrait:
            imgOr = UIImageOrientationUp;
            break;
            case UIDeviceOrientationPortraitUpsideDown:
            imgOr = UIImageOrientationDown;
            break;
            case UIDeviceOrientationLandscapeLeft:
            imgOr = UIImageOrientationLeft;
            break;
            case UIDeviceOrientationLandscapeRight:
            imgOr = UIImageOrientationRight;
            break;
        default:
            imgOr = UIImageOrientationUp;
            break;
    }
    
    return [self imageFromCurrentFramebufferWithOrientation:imgOr];
}


- (UIImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation {
    
    CGImageRef cgImgFromBytes = [self newCGImageFromCurrentlyProcessedOutput];
    UIImage *finalImg = [UIImage imageWithCGImage:cgImgFromBytes scale:1.0 orientation:imageOrientation];
    CGImageRelease(cgImgFromBytes);
    return finalImg;
}

- (UIImage *)imageByFilteringImage:(UIImage *)imageToFilter{
    CGImageRef img = [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
    UIImage *proImg = [UIImage imageWithCGImage:img scale:[imageToFilter scale] orientation:[imageToFilter imageOrientation]];
    CGImageRelease(img);
    return proImg;
}

- (CGImageRef)newCGImageByFilteringImage:(UIImage *)imageToFilter{
    return [self newCGImageByFilteringCGImage:[imageToFilter CGImage]];
}

#else

- (NSImage *)imageFromCurrentFramebuffer;
{
    return [self imageFromCurrentFramebufferWithOrientation:UIImageOrientationLeft];
}

- (NSImage *)imageFromCurrentFramebufferWithOrientation:(UIImageOrientation)imageOrientation;
{
    CGImageRef cgImageFromBytes = [self newCGImageFromCurrentlyProcessedOutput];
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:cgImageFromBytes size:NSZeroSize];
    CGImageRelease(cgImageFromBytes);
    
    return finalImage;
}

- (NSImage *)imageByFilteringImage:(NSImage *)imageToFilter;
{
    CGImageRef image = [self newCGImageByFilteringCGImage:[imageToFilter CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil]];
    NSImage *processedImage = [[NSImage alloc] initWithCGImage:image size:NSZeroSize];
    CGImageRelease(image);
    return processedImage;
}

- (CGImageRef)newCGImageByFilteringImage:(NSImage *)imageToFilter
{
    return [self newCGImageByFilteringCGImage:[imageToFilter CGImageForProposedRect:NULL context:[NSGraphicsContext currentContext] hints:nil]];
}

#endif

- (void)setAudioEncodingTarget:(GPUImageMovieWriter *)audioEncodingTarget{
    // TODO
}

- (void)setOutputTextureOptions:(GLTextureOptions)outputTextureOptions {
    _outputTextureOptions = outputTextureOptions;
    if (_outputFrameBuffer.texture) {
        glBindTexture(GL_TEXTURE_2D, _outputFrameBuffer.texture);
        //_outputTextureOptions.format
        //_outputTextureOptions.internalFormat
        //_outputTextureOptions.magFilter
        //_outputTextureOptions.minFilter
        //_outputTextureOptions.type
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _outputTextureOptions.wrapS);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _outputTextureOptions.wrapT);
        glBindTexture(GL_TEXTURE_2D, 0);
    }
}

@end
