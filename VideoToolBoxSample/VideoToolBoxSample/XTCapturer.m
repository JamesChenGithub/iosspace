//
//  XTCapturer.m
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XTCapturer.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface XTCapturer ()

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;
@property (nonatomic, strong) AVCaptureConnection *connection;

@end

@implementation XTCapturer



@end
