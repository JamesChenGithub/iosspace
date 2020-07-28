//
//  GLFrameBufferCache.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLFrameBufferCache.h"
#import "GLFrameBuffer.h"
#import "GLOutput.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#endif

@interface GLFrameBufferCache()
{
    NSMutableDictionary *_frameBufferCache;
    NSMutableDictionary *_frameBufferTypeCounts;
    NSMutableArray      *_activeImageCaptureList;
    
    id  _memoryWarningObserver;
    dispatch_queue_t _frameBufferCacheQueue;
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;

@end

@implementation GLFrameBufferCache

- (instancetype)init {
    if (self = [super init]) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        __weak typeof(self) ws = self;
        _memoryWarningObserver = [[NSNotificationCenter defaultCenter]  addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            typeof(self) strongSelf = ws;
            if (strongSelf) {
                [strongSelf  purgeAllUnassignedFramebuffers];
            }
        }];
#else
#endif
        
        _frameBufferCache =[[NSMutableDictionary alloc] init];
        _frameBufferTypeCounts = [[NSMutableDictionary alloc] init];
        _activeImageCaptureList = [[NSMutableArray alloc] init];
        
        _frameBufferCacheQueue = dispatch_queue_create("com.glcontext.framebuffercachequeue", GLDefaultQueueAttribute());
    }
    return self;
}

- (void)dealloc
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#else
#endif
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture {
    if (onlyTexture) {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-NOFB",size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    } else {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (GLFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture {
    return [self fetchFramebufferForSize:framebufferSize textureOptions:kDefaultGLTextureOptions() onlyTexture:onlyTexture];
}

- (GLFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture {
    __block GLFrameBuffer *framebufferFromCache = nil;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        NSNumber *numberOfMatchingTexturesInCache = [self->_frameBufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        if (numberOfMatchingTexturesInCache.integerValue < 1) {
            framebufferFromCache = [[GLFrameBuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        } else {
            NSInteger currentTextureId = (numberOfMatchingTextures - 1);
            while ((framebufferFromCache == nil) && currentTextureId >= 0) {
                NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)currentTextureId];
                framebufferFromCache = [self->_frameBufferCache objectForKey:textureHash];
                if (framebufferFromCache != nil) {
                    [self->_frameBufferCache removeObjectForKey:textureHash];
                }
                currentTextureId--;
            }
            
            currentTextureId++;
            [self->_frameBufferCache setObject:@(currentTextureId) forKey:lookupHash];
            
            if (framebufferFromCache) {
                framebufferFromCache = [[GLFrameBuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
            }
        }
        

        
    });
    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (void)returnFramebufferToCache:(GLFrameBuffer *)framebuffer{
    [framebuffer clearAllLocks];
    __weak typeof(self) ws = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(ws) strongSelf = ws;
        if (strongSelf == nil) {
            return;;
        }
        CGSize framebufferSize = framebuffer.size;
        GLTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions onlyTexture:framebuffer.missingFramebuffer];
        NSNumber *numberOfMatchingTexturesInCache = [self->_frameBufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)numberOfMatchingTextures];
        
        [self->_frameBufferCache setObject:framebuffer forKey:textureHash];
        [self->_frameBufferTypeCounts setObject:[NSNumber numberWithInteger:(numberOfMatchingTextures + 1)] forKey:lookupHash];
        
    });
}

- (void)purgeAllUnassignedFramebuffers {
    __weak typeof(self) ws = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(ws) strongSelf = ws;
        if (strongSelf == nil) {
            return;;
        }
        [self->_frameBufferCache removeAllObjects];
        [self->_frameBufferTypeCounts removeAllObjects];
        #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
                CVOpenGLESTextureCacheFlush([[GLContext sharedImageProcessingContext] coreVideoTextureCache], 0);
        #else
        #endif
    });
}

- (void)addFramebufferToActiveImageCaptureList:(GLFrameBuffer *)framebuffer;
{
    __weak typeof(self) ws = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
//    dispatch_async(framebufferCacheQueue, ^{
        __strong typeof(ws) strongSelf = ws;
        if (strongSelf == nil) {
            return;;
        }
        [self->_activeImageCaptureList addObject:framebuffer];
    });
}

- (void)removeFramebufferFromActiveImageCaptureList:(GLFrameBuffer *)framebuffer;
{
    __weak typeof(self) ws = self;
    runAsynchronouslyOnVideoProcessingQueue(^{
//  dispatch_async(framebufferCacheQueue, ^{
        __strong typeof(ws) strongSelf = ws;
        if (strongSelf == nil) {
            return;;
        }
        [self->_activeImageCaptureList removeObject:framebuffer];
    });
}


@end
