//
//  ViewController.m
//  MetalVideo
//
//  Created by 陈耀武 on 2020/8/20.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RenderView.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //    return;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(changeOrientation:) name:UIApplicationDidChangeStatusBarFrameNotification object:nil];
    
    self.session = [[AVCaptureSession alloc]init];
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice*frontCamera;
    for (AVCaptureDevice *device in cameras){
        if (device.position == AVCaptureDevicePositionFront){
            frontCamera = device;
        }
    }
    NSError *error = nil;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
    
    [self.session addInput:videoInput];
    
    AVCaptureVideoDataOutput *avCaptureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    //设置采集RGBA
    //        NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,nil];
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,nil];
    
    avCaptureVideoDataOutput.videoSettings = settings;
    avCaptureVideoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    
    [avCaptureVideoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    
    
    
    [self.session addOutput:avCaptureVideoDataOutput];
    self.videoConnection = [avCaptureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    self.videoConnection.videoOrientation = [self currentCaptureVideoOrientationFromeStatusBarOrientation];
    [self.session startRunning];
    NSLog(@"%@",avCaptureVideoDataOutput.connections);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    if(CVPixelBufferLockBaseAddress(imageBuffer, 0) == kCVReturnSuccess)
    {
        UInt8 *rgbBuffer = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        UInt8 *yBuffer = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        UInt8 *uvBuffer = (UInt8 *)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        
        size_t linesize_yu = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
//                [(RenderView *)self.view renderRGBAWith:rgbBuffer width:width height:height];
        [(RenderView *)self.view renderNV12With:yBuffer uvBuffer:uvBuffer width:width height:height];
        
        
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}
- (void)changeOrientation:(NSNotification*)notification {
    //    self.layer.connection.videoOrientation = [self currentCaptureVideoOrientationFromeStatusBarOrientation];
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    self.videoConnection.videoOrientation = [self currentCaptureVideoOrientationFromeStatusBarOrientation];
}

-(AVCaptureVideoOrientation)currentCaptureVideoOrientationFromeStatusBarOrientation {
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationLandscapeLeft;
    if ( statusBarOrientation != UIInterfaceOrientationUnknown) {
        initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
    }
    return initialVideoOrientation;
}

@end
