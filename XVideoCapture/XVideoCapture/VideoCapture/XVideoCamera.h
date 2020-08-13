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

@interface XVideoCamera : NSObject

- (void)startCapture;
- (void)stopCapture;
- (AVCaptureVideoPreviewLayer *)previewLayer:(AVLayerVideoGravity)avg;

@end

NS_ASSUME_NONNULL_END
