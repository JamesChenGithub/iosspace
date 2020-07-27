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

@end
