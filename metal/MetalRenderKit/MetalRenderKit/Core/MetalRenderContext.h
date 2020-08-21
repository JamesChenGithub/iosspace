//
//  MetalRenderContext.h
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN



@interface MetalRenderContext : NSObject

@property (strong) id<MTLDevice> metalDevice;
@property (strong) id<MTLLibrary> metalLibrary;
@property (strong) id<MTLCommandQueue> metalCommandQueue;


+ (instancetype)sharedContext;

- (id<MTLTexture>)textureFromPixelBuffer:(CVPixelBufferRef)videoPixelBuffer;

@end

NS_ASSUME_NONNULL_END
