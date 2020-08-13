//
//  XOpenGLContext.m
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XOpenGLContext.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
#import <OpenGLES/EAGL.h>
#import <pthread.h>
#import "XCommon.h"

//@interface XOpenGLContextProxy : NSProxy
//@property (nonatomic, strong) XOpenGLContext *proxtyInstance;
//- (instancetype)initWithInstance:(XOpenGLContext *)context;
//- (void)destroy;
//@end

PROXY_DECLARAION(XOpenGLContext)

static void *XRenderQueueKey;

@interface XOpenGLContext()
{
    SInt32 _refCnt;
    pthread_mutex_t _refCntMutex;
}
@property (nonatomic, strong) EAGLContext       *glContext;
@property (nonatomic, strong) dispatch_queue_t  renderQueue;
@property (nonatomic, assign) BOOL isSync;
@property (nonatomic, assign) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@end


@implementation XOpenGLContext

PROXY_Singleton_IMPLEMENT(XOpenGLContext)


- (id)init
{
    self = [super init];
    if(self){
        pthread_mutex_init ( &_refCntMutex, NULL);
        XRenderQueueKey = &XRenderQueueKey;
        self.renderQueue = dispatch_queue_create("com.LiteAV.renderQueue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_renderQueue, XRenderQueueKey, (__bridge void *)self, NULL);

    }
    return self;
}

- (void)destoryClean{
    pthread_mutex_lock(&_refCntMutex);
    _glContext = nil;
    if (_coreVideoTextureCache) {
        CVOpenGLESTextureCacheRef cache = _coreVideoTextureCache;
        _coreVideoTextureCache = NULL;
        CFRelease(cache);
    }
    pthread_mutex_unlock(&_refCntMutex);
}

- (void)dealloc
{
    pthread_mutex_destroy(&_refCntMutex);
}


- (void)setupGLContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    if (nil == context) {
        NSLog(@"Switch to OpenGLES 2.0 context");
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    if(nil == context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
    }
    self.glContext = context;
}

- (EAGLContext *)openGLContext
{
    return self.glContext;
}

+ (BOOL)supportsFastTextureUpload
{
//#if TARGET_IPHONE_SIMULATOR
//    return NO;
//#else
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop
    
//#endif
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
{
    if (_coreVideoTextureCache == NULL)
    {
#if defined(__IPHONE_6_0)
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _glContext, NULL, &_coreVideoTextureCache);
#else
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)_glContext, NULL, &_coreVideoTextureCache);
#endif
        
        if (err){
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _coreVideoTextureCache;
}

#pragma mark - render queue
- (void)runSyncOnRenderQueue:(void (^)(void))block
{
    if(dispatch_get_specific(XRenderQueueKey) && _isSync){
        block();
    }
    else{
        _isSync = YES;
        dispatch_sync(self.renderQueue, ^{
            block();
        });
    }
}

- (void)runAsyncOnRenderQueue:(void (^)(void))block
{
    if(dispatch_get_specific(XRenderQueueKey) && !_isSync){
        block();
    }
    else{
        _isSync = NO;
        dispatch_async(self.renderQueue, ^{
            block();
        });
    }
}

- (void)increaseReference {
    pthread_mutex_lock(&_refCntMutex);
    _refCnt += 1;
    if (_refCnt == 1) {
        [self setupGLContext];
    }
    pthread_mutex_unlock(&_refCntMutex);
}

- (void)decreaseReference {
    pthread_mutex_lock(&_refCntMutex);
    if (_refCnt > 0) {
        _refCnt -= 1;
        if (_refCnt == 0) {
            _glContext = nil;
            if (_coreVideoTextureCache) {
                CVOpenGLESTextureCacheRef cache = _coreVideoTextureCache;
                _coreVideoTextureCache = NULL;
                CFRelease(cache);
            }
        }
    }
    pthread_mutex_unlock(&_refCntMutex);
}

@end

PROXY_IMPLEMENT(XOpenGLContext)
