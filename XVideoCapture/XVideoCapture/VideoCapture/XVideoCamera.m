//
//  XVideoCamera.m
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "XVideoCamera.h"
#import <UIKit/UIDevice.h>
#import "XCommon.h"

@interface XVideoCamera () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    BOOL                        _frontCamera;           // 是否是前置摄像头
    BOOL                        _enableFaceDetect;      // 是否开启人脸检测
    NSInteger                   _videoFps;              // 采集帧率
    AVCaptureSessionPreset      _sessionPreset;         // 采集分辨率
    AVCaptureVideoOrientation   _captureOrientation;    // 采集方向
}

@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, strong) dispatch_queue_t faceDetectQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation XVideoCamera

static void *XVideoCameraKey;

+ (NSString *)domain {
    return NSStringFromClass([self class]);
}

- (instancetype)init {
    if (self = [super init]) {
        _frontCamera = YES;
        _videoFps = 15;
        _sessionPreset = AVCaptureSessionPreset640x480;
        _captureOrientation = AVCaptureVideoOrientationPortrait;
        _captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

//兼容iOS10以上获取AVCaptureDevice
- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position{
    
    if (@available(iOS 10.0, *)) {
        // iOS10以上
        AVCaptureDeviceDiscoverySession *devicesIOS10 = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:position];
        NSArray *devicesIOS  = devicesIOS10.devices;
        for (AVCaptureDevice *device in devicesIOS) {
            if ([device position] == position) {
                return device;
            }
        }
        return nil;
    } else {
        // iOS10以下
        NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in devices)
        {
            if ([device position] == position)
            {
                return device;
            }
        }
        return nil;
    }
}

#define   ResetParams()    do {  _captureSession =  nil;\
_captureDeviceInput = nil;\
_captureDeviceOutput = nil;\
_captureConnection =  nil;\
}while(0)

- (BOOL)configSession:(NSError * _Nullable * _Nullable)outError; {
    
    if (_captureSession == nil) {
        AVCaptureSession *session = nil;
        AVCaptureDeviceInput *deviceInput = nil;
        AVCaptureVideoDataOutput *deviceOutput = nil;
        AVCaptureConnection *connection = nil;
        
        session = [[AVCaptureSession alloc] init];
        [session beginConfiguration];
        if ([session canSetSessionPreset:_sessionPreset]) {
            session.sessionPreset = _sessionPreset;
        } else {
            ResetParams();
            [session commitConfiguration];
            *outError = [NSError errorWithDomain:[XVideoCamera domain] code:-1 userInfo:@{@"errmsg" : @"can't setSessionPreset"}];
            return NO;
        }
        
        AVCaptureDevicePosition camPos = _frontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
        AVCaptureDevice *inputCamera = [self cameraWithPostion:camPos];
        
        NSError *error = nil;
        deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:&error];
        if (error) {
            ResetParams();
            [session commitConfiguration];
            *outError = [NSError errorWithDomain:[XVideoCamera domain] code:-2 userInfo:@{@"errmsg" : @"AVCaptureDeviceInput create failed"}];
            return NO;
        }
        
        if ([session canAddInput:deviceInput]) {
            [session addInput:deviceInput];
        } else {
            ResetParams();
            [session commitConfiguration];
            *outError = [NSError errorWithDomain:[XVideoCamera domain] code:-2 userInfo:@{@"errmsg" : @"can't addInput"}];
            return NO;
        }
        
        
        deviceOutput = [[AVCaptureVideoDataOutput alloc] init];
        [deviceOutput  setAlwaysDiscardsLateVideoFrames:YES];
        NSDictionary *captureSettings = @{(NSString *) kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)};
        [deviceOutput setVideoSettings:captureSettings];
        [deviceOutput setSampleBufferDelegate:self queue:_captureQueue];
        
        if ([session canAddOutput:deviceOutput]) {
            [session addOutput:deviceOutput];
        } else {
            ResetParams();
            [session commitConfiguration];
            *outError = [NSError errorWithDomain:[XVideoCamera domain] code:-2 userInfo:@{@"errmsg" : @"can't addOutput"}];
            return NO;
        }
        
        connection = [deviceOutput connectionWithMediaType:AVMediaTypeVideo];
        if (connection) {
            [connection  setVideoOrientation:_captureOrientation];
        } else {
            ResetParams();
            [session commitConfiguration];
            *outError = [NSError errorWithDomain:[XVideoCamera domain] code:-2 userInfo:@{@"errmsg" : @"connection failed"}];
            return NO;
        }
        
        _captureSession = session;
        _captureDeviceInput = deviceInput;
        _captureDeviceOutput = deviceOutput;
        _captureConnection = connection;
        [session commitConfiguration];
    }
    
    return YES;
    
}

+ (void)requestForAccess:(void(^)(BOOL))completion {
    if (@available(iOS 7.0, macOS 10.14, *)) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (status == AVAuthorizationStatusDenied) { // denied
            completion(NO);
        } else if (status == AVAuthorizationStatusRestricted) { // restricted
            completion(NO);
        } else if (status == AVAuthorizationStatusNotDetermined) { // not determined
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:completion];
        } else if (status == AVAuthorizationStatusAuthorized) {
            completion(YES);
        }
    } else {
        completion(YES);
    }
}

#pragma mark - 对外接口

- (void)startCapture {
    WEAKIFY(self);
    [XVideoCamera requestForAccess:^(BOOL succ) {
        STRONGIFY_OR_RETURN(self);
        if (succ) {
            NSError *error = nil;
            BOOL succ = [self configSession:&error];
            if (succ) {
                [self.captureSession startRunning];
            } else {
                DebugLog(@"startCapture failed : %@", error);
            }
        } else {
            DebugLog(@"startCapture failed : not authorizated");
        }
    }];
    
}

- (void)stopCapture {
    if (_captureSession) {
        [_captureDeviceOutput setSampleBufferDelegate:nil queue:nil];
        [_captureSession stopRunning];
    }
    ResetParams();
}

- (AVCaptureVideoPreviewLayer *)previewLayer:(AVLayerVideoGravity)avg {
    if (_previewLayer == nil) {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    }
    [_previewLayer setVideoGravity:avg];
    return _previewLayer;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
}

- (void)captureOutput:(AVCaptureOutput *)output didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection API_AVAILABLE(ios(6.0)) {
    
}
@end
