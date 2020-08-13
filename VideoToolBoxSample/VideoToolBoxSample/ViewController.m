//
//  ViewController.m
//  VideoToolBoxSample
//
//  Created by 陈耀武 on 2020/8/3.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "XTHWEncoder.h"
#import "XTHWDecoder.h"
#import "XTRenderLayer.h"

@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate, XTHWEncoderDelegate, XTHWDecoderDelegate>

@property (nonatomic, strong) dispatch_queue_t captureQueue;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureDeviceOutput;
@property (nonatomic, strong) AVCaptureConnection *connection;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) XTRenderLayer *playerLayer;

@property (nonatomic, strong) XTHWDecoder *h264Decoder;
@property (nonatomic, strong) XTHWEncoder *h264Encoder;

@property (nonatomic, weak) IBOutlet UIView *captureView;
@property (nonatomic, weak) IBOutlet UIView *renderView;



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configDecoder];
    [self configEncoder];
    
    self.captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  
}

- (void)configEncoder {
    if (!self.h264Encoder) {
        self.h264Encoder = [[XTHWEncoder alloc] init];
        [self.h264Encoder startEncoder:640 height:480];
        self.h264Encoder.delegate = self;
    }
}

- (void)configDecoder {
      if (!self.h264Decoder) {
          self.h264Decoder = [[XTHWDecoder alloc] init];
          self.h264Decoder.delegate = self;
      }
}

- (IBAction)onStart:(UIButton *)sender {
    if (sender.selected) {
        // 停止
        [self stopCapture];
    } else {
        // 开始
        [self startCapture];
    }
    sender.selected = !sender.selected;
}



//兼容iOS10以上获取AVCaptureDevice
- (AVCaptureDevice *)cameraWithPostion:(AVCaptureDevicePosition)position{
    NSString *version = [UIDevice currentDevice].systemVersion;
    if (version.doubleValue >= 10.0) {
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


- (void)initCapture {
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *inputCamera = [self cameraWithPostion:AVCaptureDevicePositionFront];
    self.captureDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:inputCamera error:nil];
    
    if ([self.captureSession canAddInput:self.captureDeviceInput]) {
        [self.captureSession addInput:self.captureDeviceInput];
    }
    
    self.captureDeviceOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureDeviceOutput setAlwaysDiscardsLateVideoFrames:NO];
    
    [self.captureDeviceOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)}];
//    [self.captureDeviceOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    [self.captureDeviceOutput setSampleBufferDelegate:self queue:self.captureQueue];
    
    if ([self.captureSession canAddOutput:self.captureDeviceOutput]) {
        [self.captureSession addOutput:self.captureDeviceOutput];
    }
    
    self.connection = [self.captureDeviceOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.connection  setVideoOrientation:AVCaptureVideoOrientationPortrait];
}

- (void)initPreviewLayer {
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [self.previewLayer setFrame:self.captureView.bounds];
    [self.captureView.layer addSublayer:self.previewLayer];
}

- (void)initRenderPlayer{
    self.playerLayer = [[XTRenderLayer alloc] initWithFrame:self.renderView.bounds];
    [self.renderView.layer addSublayer:self.playerLayer];
}

- (void)startCapture {
    [self configEncoder];
    [self configDecoder];
    
    [self initCapture];
    [self initPreviewLayer];
    [self initRenderPlayer];
    
    [self.captureSession startRunning];
}

- (void)stopCapture {
    [self.captureSession stopRunning];
    self.captureSession = nil;
    self.captureDeviceInput = nil;
    self.captureDeviceOutput = nil;
    self.connection = nil;
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer = nil;
    
    [self.h264Encoder stopEncode];
    [self.h264Decoder endDecode];
    
    self.h264Encoder = nil;
    self.h264Decoder = nil;
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    if (self.connection == connection) {
        [self.h264Encoder encode:sampleBuffer];
    }
}

#pragma mark - 编码回调
- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [self.h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] size:(uint32_t)h264Data.length];
    
    
    //pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [self.h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] size:(uint32_t)h264Data.length];
}
- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [self.h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] size:(uint32_t)h264Data.length];
}


#pragma mark - 解码回调
- (void)gotDecodedFrame:(CVImageBufferRef)imageBuffer{
    if(imageBuffer)
    {
        //解码回来的数据绘制播放
        self.playerLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}
@end
