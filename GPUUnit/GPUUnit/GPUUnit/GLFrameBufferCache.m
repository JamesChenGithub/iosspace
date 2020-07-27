//
//  GLFrameBufferCache.m
//  GPUUnit
//
//  Created by AlexiChen on 2020/7/27.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "GLFrameBufferCache.h"
#import "GLFrameBuffer.h"

@interface GLFrameBufferCache()
{
    NSMutableDictionary *_frameBufferCache;
    NSMutableDictionary *_frameBufferTypeCounts;
    NSMutableArray      *_activeImageCaptureList;
    
    id  memoryWarningObserver;
    dispatch_queue_t frameBufferCacheQueue;
}

@end

@implementation GLFrameBufferCache

@end
