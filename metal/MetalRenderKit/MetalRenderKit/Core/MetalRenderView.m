//
//  MetalRenderView.m
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "MetalRenderView.h"
#import <Metal/Metal.h>

@implementation MetalRenderView

+ (Class)layerClass {
    return [CAMetalLayer class];
}

- (CAMetalLayer *)metalLayer {
    return (CAMetalLayer *)self.layer;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    if (self.window) {
        scale = self.window.screen.scale;
    }
    
    CGSize size = self.bounds.size;
    self.metalLayer.drawableSize = CGSizeMake(size.width * scale, size.height * scale);
}

@end
