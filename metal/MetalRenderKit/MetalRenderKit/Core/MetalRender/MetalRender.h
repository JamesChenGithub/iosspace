//
//  MetalRender.h
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MetalRenderContext.h"

NS_ASSUME_NONNULL_BEGIN


@interface MetalRenderEncoder : NSObject

@end

@interface MetalRender : NSObject

@property (nonatomic, strong) CAMetalLayer *renderLayer;
@property (nonatomic, strong) MetalRenderContext *renderContext;
@property (nonatomic, strong) id<MTLRenderPipelineState> renderPipelineState;

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalRenderContext *)kitContext vertextFunc:(NSString *)vertextFuncName fragementFunc:(NSString *)fragementFuncName;

- (void)draw;

@end

NS_ASSUME_NONNULL_END
