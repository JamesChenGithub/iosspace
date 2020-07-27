//
//  GLFrameBufferCache.h
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface GLFrameBufferCache : NSObject
// Framebuffer management
- (GLFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;

- (GLFrameBuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;

- (void)returnFramebufferToCache:(GLFrameBuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(GLFrameBuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(GLFrameBuffer *)framebuffer;
@end


