//
//  GLFrameBuffer.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLFrameBuffer.h"
#import "GLContext.h"

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
            // TODO
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
//    runSynchronouslyOnVideoProcessingQueue()
  
}

@end
