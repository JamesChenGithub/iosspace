//
//  GLContext.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLContext.h"

extern dispatch_queue_attr_t GLDefaultQueueAttribute(void);

@interface GLContext () {
    NSMutableDictionary     *_sharderProgramCache;
    NSMutableArray          *_shaderProgramUsageHistory;
    EAGLSharegroup          *_shareGroup;
    GLFrameBufferCache      *_framebufferCache;
    CVOpenGLESTextureCacheRef  _coreVideoTextureCache;
}

@end

@implementation GLContext

static void *kGLContextContextQueueKey;
- (instancetype)init{
    if (self = [super init]) {
        
        kGLContextContextQueueKey = &kGLContextContextQueueKey;
        _contextQueue = dispatch_queue_create("com.glunit.contextqueue", GLDefaultQueueAttribute());
        
        dispatch_queue_set_specific(_contextQueue, kGLContextContextQueueKey, (__bridge void *)self, NULL);
        
        _sharderProgramCache = [NSMutableDictionary dictionary];
        _shaderProgramUsageHistory = [NSMutableArray array];
    }
    return self;
}

+ (void *)contextKey {
    return kGLContextContextQueueKey;
}

+ (GLContext *)sharedImageProcessingContext {
    static GLContext *sharedContext = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedContext = [[GLContext alloc] init];
    });
    return sharedContext;
}

+ (dispatch_queue_t)sharedContextQueue {
    return [[GLContext sharedImageProcessingContext] contextQueue];
}

+ (GLFrameBufferCache *)sharedFramebufferCache {
    return [[GLContext sharedImageProcessingContext] framebufferCache];
}

+ (void)useImageProcessingContext {
    [[GLContext sharedImageProcessingContext] useAsCurrentContext];
}

- (void)useAsCurrentContext {
    
    if ([EAGLContext currentContext] != self.context) {
        [EAGLContext setCurrentContext:self.context];
    }
}

+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram {
    GLContext *sharedcontext = [GLContext sharedImageProcessingContext];
    [sharedcontext setContextShaderProgram:shaderProgram];
}

- (void)setContextShaderProgram:(GLProgram *)shaderProgram {
    [self useAsCurrentContext];
    
    if (self.currentShaderProgram != shaderProgram) {
        self.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

+ (GLint)maximumTextureSizeForThisDevice {
    static GLint maxTextureSize = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [GLContext useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });
    return maxTextureSize;
}

+ (GLint)maximumVaryingVectorsForThisDevice {
    static GLint maxVaryingVectors = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [GLContext useImageProcessingContext];
        glGetIntegerv(GL_MAX_VARYING_VECTORS, &maxVaryingVectors);
    });
    return maxVaryingVectors;
}

+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension {
    static dispatch_once_t onceToken;
    static NSArray *extensionNames = nil;
    dispatch_once(&onceToken, ^{
        [GLContext useImageProcessingContext];
        
        NSString *extstr = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames = [extstr componentsSeparatedByString:@" "];
    });
    return [extensionNames containsObject:extension];
}


+ (BOOL)deviceSupportsRedTextures{
    static BOOL supportRedTexture = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportRedTexture = [GLContext deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });
    return supportRedTexture;
}

+ (BOOL)deviceSupportsFramebufferReads{
    static BOOL supportsFramebufferReads = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportsFramebufferReads = [GLContext deviceSupportsOpenGLESExtension:@"GL_EXT_shader_framebuffer_fetch"];
    });
    return supportsFramebufferReads;
}

+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize{
    GLint maxturesize = [GLContext maximumTextureSizeForThisDevice];
    
    if (inputSize.width < maxturesize && inputSize.height < maxturesize) {
        return inputSize;
    }
    
    CGSize adjustSize;
    if (inputSize.width > inputSize.height) {
        adjustSize.width = (CGFloat)maxturesize;
        adjustSize.height = (GLfloat)(maxturesize/inputSize.width) * inputSize.height;
    } else {
        adjustSize.height = (CGFloat)maxturesize;
        adjustSize.width = (GLfloat)(maxturesize/inputSize.height) * inputSize.width;
    }
    return adjustSize;
}

- (void)presentBufferForDisplay {
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString const*)fragmentShaderString {
    NSString *key = [NSString stringWithFormat:@"V : %@ - F : %@", vertexShaderString, fragmentShaderString];
    GLProgram *prog = [_sharderProgramCache objectForKey:key];
    
    if (prog == nil) {
        prog = [[GLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [_sharderProgramCache setObject:prog forKey:key];
    }
    
    return prog;
    
}

- (void)useSharegroup:(EAGLSharegroup *)sharegroup {
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    _shareGroup = sharegroup;
}

- (EAGLContext *)createContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_shareGroup];
    NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The GPUImage framework requires OpenGL ES 2.0 support to work.");
    return context;
}

+ (BOOL)supportsFastTextureUpload {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
#endif
}

- (EAGLContext *)context {
    if (_context == nil) {
        _context = [self createContext];
        [EAGLContext setCurrentContext:_context];
        glDisable(GL_DEPTH_TEST);
    }
    return _context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache {
    if (_coreVideoTextureCache == NULL)    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)[self context], NULL, &_coreVideoTextureCache);
#endif
        
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
        
    }
    
    return _coreVideoTextureCache;
}


- (GLFrameBufferCache *)framebufferCache {
    if (_framebufferCache == nil) {
        _framebufferCache = [[GLFrameBufferCache alloc] init];
    }
    return _framebufferCache;
}

@end
