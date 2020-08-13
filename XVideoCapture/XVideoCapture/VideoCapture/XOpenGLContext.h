//
//  XOpenGLContext.h
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>


NS_ASSUME_NONNULL_BEGIN
@class EAGLContext;
@interface XOpenGLContext : NSObject

+ (instancetype)sharedInstance;
+ (void)destorySharedInstance;
- (EAGLContext *)openGLContext;
- (CVOpenGLESTextureCacheRef)coreVideoTextureCache;
+ (BOOL)supportsFastTextureUpload;
- (void)runSyncOnRenderQueue:(void (^)(void))block;
- (void)runAsyncOnRenderQueue:(void (^)(void))block;

- (void)increaseReference;
- (void)decreaseReference;

@end

NS_ASSUME_NONNULL_END
