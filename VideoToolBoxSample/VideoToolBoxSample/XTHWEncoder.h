//
//  XTHWEncoder.h
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/3.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


@protocol  XTHWEncoderDelegate <NSObject>

//回调sps和pps数据
- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps;

//回调H264数据和是否是关键帧
- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame;

@end

@interface XTHWEncoder : NSObject

@property (weak, nonatomic) id<XTHWEncoderDelegate> delegate;

- (void)startEncoder:(int32_t)width height:(int32_t)height;
- (void)encode:(CMSampleBufferRef)sampleBuffer;
- (void)stopEncode;
@end


