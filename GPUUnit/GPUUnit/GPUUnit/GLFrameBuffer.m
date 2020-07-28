//
//  GLFrameBuffer.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLFrameBuffer.h"
#import "GLContext.h"
#import "GLOutput.h"

@interface GLFrameBuffer () {
    GLuint _frameBuffer;
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
    NSUInteger _readLockCount;
#else
#endif
    
    NSUInteger _framebufferReferenceCount;
    BOOL _referenceCountingDisabled;
    GLuint _texture;
}

- (void)generateFramebuffer;
- (void)generateTexture;
- (void)destroyFramebuffer;

@end

void dataProviderReleaseCallback (void *info, const void *data, size_t size);
void dataProviderUnlockCallback (void *info, const void *data, size_t size);
GLTextureOptions kDefaultGLTextureOptions() {
    GLTextureOptions option;
    option.minFilter = GL_LINEAR;
    option.magFilter = GL_LINEAR;
    option.wrapS = GL_CLAMP_TO_EDGE;
    option.wrapT = GL_CLAMP_TO_EDGE;
    option.internalFormat = GL_RGBA;
    option.format = GL_BGRA;
    option.type = GL_UNSIGNED_BYTE;
    return option;
}

@implementation GLFrameBuffer

- (instancetype)initWithSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTextur{
    if (self = [super init]) {
        _textureOptions = fboTextureOptions;
        _size = framebufferSize;
        
        _framebufferReferenceCount = 0;
        _referenceCountingDisabled = NO;
        _missingFramebuffer = onlyGenerateTextur;
        
        if (_missingFramebuffer) {
            runSynchronouslyOnVideoProcessingQueue(^{
                [GLContext useImageProcessingContext];
                [self generateTexture];
                self->_frameBuffer = 0;
            });
        } else {
            [self generateFramebuffer];
        }
        
    }
    return self;
}

- (instancetype)initWithSize:(CGSize)framebufferSize overriddenTexture:(GLuint)inputTexture {
    if (self = [super init]) {
        _textureOptions = kDefaultGLTextureOptions();
        _size = framebufferSize;
        _framebufferReferenceCount = 0;
        _referenceCountingDisabled = YES;
        _texture = inputTexture;
    }
    return self;
}

- (instancetype)initWithSize:(CGSize)framebufferSize {
    GLTextureOptions defaultOption = kDefaultGLTextureOptions();
    return [self initWithSize:framebufferSize textureOptions:defaultOption onlyTexture:NO];
}

- (void)dealloc
{
    [self destroyFramebuffer];
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE);
    glGenTextures(1, &_texture);
    glBindBuffer(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
}

- (void)generateFramebuffer {
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        
        glGenFramebuffers(1, &(self->_frameBuffer));
        glBindFramebuffer(GL_FRAMEBUFFER, self->_frameBuffer);
        
        if ([GLContext supportsFastTextureUpload]) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [[GLContext sharedImageProcessingContext] coreVideoTextureCache];
            
            CFDictionaryRef empty;
            CFMutableDictionaryRef atts;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            atts = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(atts, kCVPixelBufferIOSurfacePropertiesKey, empty);
            
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)(self->_size.width), (int)(self->_size.height), kCVPixelFormatType_32BGRA, atts, &(self->_renderTarget));
            if (err) {
                NSLog(@"FBO size : %f, %f", self->_size.width, self->_size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, self->_renderTarget, NULL, GL_TEXTURE_2D, self->_textureOptions.internalFormat, (int)(self->_size.width), (int)(self->_size.height), self->_textureOptions.format, self->_textureOptions.type, 0, &(self->_renderTexture));
            
            if (err) {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }
            
            CFRelease(atts);
            CFRelease(empty);
            
            self->_texture = CVOpenGLESTextureGetName(self->_renderTexture);
            glBindTexture(CVOpenGLESTextureGetTarget(self->_renderTexture),self->_texture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, self->_textureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, self->_textureOptions.wrapT);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self->_texture, 0);
#endif
            
        } else {
            [self generateTexture];
            glBindTexture(GL_TEXTURE_2D, self->_texture);
            glTexImage2D(GL_TEXTURE_2D, 0, self->_textureOptions.internalFormat, (int)(self->_size.width), (int)(self->_size.height), 0, self->_textureOptions.format, self->_textureOptions.type, 0);
            
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self->_texture, 0);
        }
#ifndef NS_BLOCK_ASSERTIONS
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
#endif
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer {
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        if (self->_frameBuffer) {
            glDeleteFramebuffers(1, &(self->_frameBuffer));
            self->_frameBuffer = 0;
        }
        
        if ([GLContext supportsFastTextureUpload] && !self->_missingFramebuffer) {
            #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            if (self->_renderTarget) {
                CFRelease(self->_renderTarget);
                self->_renderTarget = NULL;
            }
            
            if (self->_renderTexture) {
                CFRelease(self->_renderTexture);
                self->_renderTexture = NULL;
            }
#endif
            
        } else {
            glDeleteTextures(1, &self->_texture);
        }
    });
}

- (void)activateFramebuffer {
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

- (void)lock {
    if (_referenceCountingDisabled) {
        return;
    }
    _framebufferReferenceCount++;
}

- (void)unlock {
    if (_referenceCountingDisabled) {
        return;
    }
    
    _framebufferReferenceCount--;
    NSAssert(_framebufferReferenceCount > 0, @"Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using");
    if (_framebufferReferenceCount < 1) {
        [[GLContext sharedFramebufferCache] returnFramebufferToCache:self];
    }
}

- (void)clearAllLocks {
    _framebufferReferenceCount = 0;
}

- (void)disableReferenceCounting {
    _referenceCountingDisabled = YES;
}

- (void)enableReferenceCounting {
    _referenceCountingDisabled = NO;
}

void dataProviderReleaseCallback (void *info, const void *data, size_t size) {
    free((void *)data);
}
void dataProviderUnlockCallback (void *info, const void *data, size_t size) {
    GLFrameBuffer *fb = (__bridge_transfer GLFrameBuffer *)info;
    
    [fb restoreRenderTarget];
    [fb unlock];
    [[GLContext sharedFramebufferCache] removeFramebufferFromActiveImageCaptureList:fb];
}

- (CGImageRef)newCGImageFromFramebufferContents{
    NSAssert(_textureOptions.internalFormat == GL_BGRA, @"For conversion to a CGImage the output texture format for this filter must be GL_RGBA.");
    NSAssert(_textureOptions.type == GL_UNSIGNED_BYTE, @"For conversion to a CGImage the type of the output texture of this filter must be GL_UNSIGNED_BYTE.");
    
    __block CGImageRef cgImgFromBytes;
    
    runSynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        
        NSUInteger totalBytesForImage = (int)self->_size.width * (int)self->_size.width * 4;
        
        GLubyte *rawImagePixels;
        
        CGDataProviderRef dataProvider = NULL;
        if ([GLContext supportsFastTextureUpload]) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(self->_renderTarget);
            NSUInteger paddedBytesForImage = paddedWidthOfImage * (int)self->_size.height * 4;
            
            glFlush();
            
            CFRetain(self->_renderTarget);
            [self lockForReading];
            
            rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress(self->_renderTarget);
            dataProvider = CGDataProviderCreateWithData((__bridge_retained void *)self, rawImagePixels, paddedBytesForImage, dataProviderUnlockCallback);
            [[GLContext sharedFramebufferCache] addFramebufferToActiveImageCaptureList:self];
#else
#endif
        } else {
            [self activateFramebuffer];
            rawImagePixels = (GLubyte *)malloc(totalBytesForImage);
            glReadPixels(0, 0, (int)self->_size.width, (int)self->_size.height, GL_RGBA, GL_UNSIGNED_BYTE, rawImagePixels);
            dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, totalBytesForImage, dataProviderReleaseCallback);
            [self unlock];
        }
        
        CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();
        
        if ([GLContext supportsFastTextureUpload]) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
            cgImgFromBytes = CGImageCreate((int)self->_size.width, (int)self->_size.height, 8, 32, 4*(int)self->_size.width, defaultRGBColorSpace, kCGBitmapByteOrderDefault | kCGImageAlphaLast, dataProvider, NULL, NO, kCGRenderingIntentDefault);
#else
#endif
        }
        
        CGDataProviderRelease(dataProvider);
        CGColorSpaceRelease(defaultRGBColorSpace);
    });
    return cgImgFromBytes;
}

- (void)restoreRenderTarget {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [self unlockAfterReading];
    CFRelease(_renderTarget);
#else
#endif
}

- (void)lockForReading {
    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        if ([GLContext supportsFastTextureUpload])
        {
            if (_readLockCount == 0)
            {
                CVPixelBufferLockBaseAddress(_renderTarget, 0);
            }
            _readLockCount++;
        }
    #endif
}

- (void)unlockAfterReading {
    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        if ([GLContext supportsFastTextureUpload])
        {
            NSAssert(_readLockCount > 0, @"Unbalanced call to -[GLFrameBuffer unlockAfterReading]");
            _readLockCount--;
            if (_readLockCount == 0)
            {
                CVPixelBufferUnlockBaseAddress(_renderTarget, 0);
            }
        }
    #endif
}

- (NSUInteger)bytesPerRow {
    if ([GLContext supportsFastTextureUpload]) {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
        return CVPixelBufferGetBytesPerRow(_renderTarget);
#else
        return _size.width * 4;
#endif
    } else {
        return _size.width * 4;
    }
}

- (GLubyte *)byteBuffer {
    #if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    [self lockForReading];
    GLubyte *buffer = CVPixelBufferGetBaseAddress(_renderTarget);
    [self unlockAfterReading];
    return buffer; // TODO: do more with this on the non-texture-cache side
#else
    return NULL;
#endif
}

- (CVPixelBufferRef)pixelBuffer {
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    return _renderTarget;
#else
    return NULL; // TODO: do more with this on the non-texture-cache side
#endif
}

- (GLuint)texture {
    return _texture;
}


@end
