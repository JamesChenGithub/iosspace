//
//  XTHWDecoder.h
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/3.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@protocol  XTHWDecoderDelegate <NSObject>

//回调sps和pps数据
- (void)gotDecodedFrame:(CVImageBufferRef )imageBuffer;

@end

@interface XTHWDecoder : NSObject
@property (weak, nonatomic) id<XTHWDecoderDelegate> delegate;

-(BOOL)initXTHWDecoder;

//解码nalu
-(void)decodeNalu:(uint8_t *)frame size:(uint32_t)frameSize;

- (void)endDecode;
@end

