//
//  XVideoCamera.h
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN

@class UIView;
@interface XVideoCamera : NSObject

- (void)startCaptureInView:(UIView *)view fillMode:(AVLayerVideoGravity)avg;
- (void)switchCamera;
- (void)stopCapture;

@end

NS_ASSUME_NONNULL_END
