//
//  MetalRender.m
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "MetalRender.h"


@implementation MetalRender

- (instancetype)initWithLayer:(CAMetalLayer *)layer andContext: (MetalRenderContext *)kitContext vertextFunc:(NSString *)vertextFuncName fragementFunc:(NSString *)fragementFuncName {
    if (self = [super init]) {
        self.renderLayer = layer;
        self.renderContext = kitContext;
        [self buildMetal];
        [self configPipelineWith:vertextFuncName fragementFunc:fragementFuncName];
    }
    return self;
}


- (void)buildMetal {
    _renderLayer.device = _renderContext.metalDevice;
    _renderLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
}

- (void)configPipelineWith:(NSString *)vertextFuncName fragementFunc:(NSString *)fragementFuncName {

    id<MTLLibrary> library = _renderContext.metalLibrary;
    
    id<MTLFunction> vertextFunc = [library newFunctionWithName:vertextFuncName];
    id<MTLFunction> fragementFunc = [library newFunctionWithName:fragementFuncName];
    
    MTLRenderPipelineDescriptor *pipelineDes = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDes.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDes.vertexFunction = vertextFunc;
    pipelineDes.fragmentFunction = fragementFunc;
    
    NSError *err = nil;
    _renderPipelineState = [_renderContext.metalDevice newRenderPipelineStateWithDescriptor:pipelineDes error:&err];
    if (!_renderPipelineState) {
        NSLog(@"new pipelinestate error : %@", err);
    }
}
- (void)draw {
    
}

@end
