//
//  ViewController.m
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/13.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "ViewController.h"
#import "XVideoCamera.h"
#import "XCommon.h"

@interface ViewController () {
    XVideoCamera *_videoCamera;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        STRONGIFY_OR_RETURN(self);
        self->_videoCamera = [[XVideoCamera alloc] init];
        [self->_videoCamera startCapture];
        AVCaptureVideoPreviewLayer *layer = [self->_videoCamera previewLayer:AVLayerVideoGravityResizeAspect];
        layer.frame = self.view.bounds;
        [self.view.layer addSublayer:layer];
    });
    
}



@end
