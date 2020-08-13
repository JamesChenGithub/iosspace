//
//  XTRenderLayer.h
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/4.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>

@interface XTRenderLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;
- (instancetype)initWithFrame:(CGRect)frame;
- (void)resetRenderBuffer;
@end


