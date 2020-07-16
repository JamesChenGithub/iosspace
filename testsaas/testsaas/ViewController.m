//
//  ViewController.m
//  testsaas
//
//  Created by AlexiChen on 2020/7/2.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"
#import <TXLiteAVSDK_TRTC/TRTCCloud.h>


@interface ViewController ()<TRTCCloudDelegate>

@property (nonatomic, strong) TRTCVideoEncParam *encParams;
@property (nonatomic, strong) TRTCParams *accountParams;

@property (nonatomic, weak) IBOutlet UIView *preView;
@property (nonatomic, weak) IBOutlet UISegmentedControl *accountMode;
@property (nonatomic, weak) IBOutlet UISegmentedControl *gsensorMode;
@property (nonatomic, weak) IBOutlet UISegmentedControl *resMode;
@property (nonatomic, weak) IBOutlet UISegmentedControl *renderMode;
@property (nonatomic, weak) IBOutlet UISegmentedControl *rotationMode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}
- (IBAction)onEnterExitRoom:(UIButton *)sender {
    
    if (self.accountMode.selectedSegmentIndex == 0) {
        self.accountParams = [[TRTCParams alloc] init];
        self.accountParams.sdkAppId = 1400037025;
        self.accountParams.userId = @"anchor";
        self.accountParams.userSig = @"eJxNzF9PgzAUh*Hv0luNHv4NMfFCO9A5uCCDIcaEQFtG2aSsVDNm-O42BKO373N*5wsl4eaqJER8dKpQY8-QLQJ0OWVOWad4zZnUsexII*QsZd9zWpSqsCT9NxjovphIN8MGAMsF05mRnXouWVHWavpnOI5j6pNZP5kcuOg0mGA4hmkB-KHi72yaeLZ7Awv79*XAdzpHfopXMd6uH9q0W0svr7BI-bg*noMov8emyIKq5RA9L7ymydzGj1c7IsBO6Nt1*jQSlYVnMdpHtdzsgyp-WT6KJHw9HbYHfkFwC3fo*wfrUFjs";
        self.accountParams.roomId = 988;
        self.accountParams.role = TRTCRoleAnchor;
        //        // 主播
        //        1400037025
        //        988
        //        anchor
        //        {"errorCode":0,"errorInfo":"","data":{"userSig":"eJxNzF9PgzAUh*Hv0luNHv4NMfFCO9A5uCCDIcaEQFtG2aSsVDNm-O42BKO373N*5wsl4eaqJER8dKpQY8-QLQJ0OWVOWad4zZnUsexII*QsZd9zWpSqsCT9NxjovphIN8MGAMsF05mRnXouWVHWavpnOI5j6pNZP5kcuOg0mGA4hmkB-KHi72yaeLZ7Awv79*XAdzpHfopXMd6uH9q0W0svr7BI-bg*noMov8emyIKq5RA9L7ymydzGj1c7IsBO6Nt1*jQSlYVnMdpHtdzsgyp-WT6KJHw9HbYHfkFwC3fo*wfrUFjs","token":"YW5jaG9yMA==","privMap":255,"privMapEncrypt":"eJxNjl1PgzAUhv8LtxpXKIVhsouKiEMWY3RDlyWko60rGx9pyzZi-O9WwqJX5*R5zvvmfFlv6esNKYqmq3Wu*5ZZtxawrgcsKKu14IJJA0ld7Bo5GtK2guZE51DSfwFF9-mgDLNdAAD0gYNGyc6tkCwnXA99NkLIMSejPTKpRFMb4QAb2Q4E4E9qUbEhErj*FHjupbJTTG47bhTGOP7IUEnioF-ClDUvhgRn-uCtD2bDm8npd*DZ5VPxaVKLaBnOQ7faqmgujmEmeZaEyWIlZQL7zaR0KAmmXCOV0bhsSz-CIsL7d*o9qTuBq2ewvldhR3cpj2C6AoogD7blI7rywkOsmmZmff8AcYdpmw__"}}
    } else {
        self.accountParams = [[TRTCParams alloc] init];
        self.accountParams.sdkAppId = 1400037025;
        self.accountParams.userId = @"audience";
        self.accountParams.userSig = @"eJxNzVtrgzAYgOH-kusxv0RjdXc9SNv1QDdXsCCE1MQtiNHZuGlH--uCONbb9-kOP*htGz-yLKtabZjpa4meEKCHISshtVG5ko2NvBVK6kyOxutaCcYNcxtxt3IRBRvINuwBgDsBQkeUXa0ayXhuhouYUkrsyKhfsrmoSlsggCkmLsA-GlXKYSX0JgH4of-3T73bvItO8-XLgufB*Zo6VXAslieRbL3PNt90e*y6enqIbFzQZeoQkxARfK8-prvXmeeHz6vjvsedN9PXJnWirG8h66FfxedyU3IDZSHiQ4Juv02AWaM_";
        self.accountParams.roomId = 988;
        self.accountParams.role = TRTCRoleAudience;
        //        {"errorCode":0,"errorInfo":"","data":{"userSig":"eJxNzVtrgzAYgOH-kusxv0RjdXc9SNv1QDdXsCCE1MQtiNHZuGlH--uCONbb9-kOP*htGz-yLKtabZjpa4meEKCHISshtVG5ko2NvBVK6kyOxutaCcYNcxtxt3IRBRvINuwBgDsBQkeUXa0ayXhuhouYUkrsyKhfsrmoSlsggCkmLsA-GlXKYSX0JgH4of-3T73bvItO8-XLgufB*Zo6VXAslieRbL3PNt90e*y6enqIbFzQZeoQkxARfK8-prvXmeeHz6vjvsedN9PXJnWirG8h66FfxedyU3IDZSHiQ4Juv02AWaM_","token":"YXVkaWVuY2Uw","privMap":255,"privMapEncrypt":"eJxNjt1ugkAQRt*F2zZ1ARe1CRcbFaW1*FvAxoRsYcBVxC3s2mLTd**W0LRzNTlnvsn3qW1m6zsax2dZiEjUHLR7DWm3DWYJFIKlDEoFqUwYFDG0jnLOkoiKyCyTf5EqOUaNUkzvIoTMHjJwK*GDsxIimormo44xNtRJay9QVuxcKGEgHeuGidCfFOwETWTQ7fWRNbBaLisoX2WqFCHE3Yb*kQa*3Br*JhbWXrGR6fRDzrOfddchzdj2b1uWqeTT*HnoTq61WU7TbDnfztNd53JYvsEhzB7NytvXV7Typo7n*VZAT45O2JgYw3XIgzFZsJnEN6NZKqzTAFbX2s8nD4Gf4zgAqefv*Ytra1-fTw1sdw__"}}
        
    }
    
    [[TRTCCloud sharedInstance] setDelegate:self];
    
    
    if (sender.selected) {
        [[TRTCCloud sharedInstance] exitRoom];
        self.gsensorMode.enabled = YES;
        self.resMode.enabled = YES;
        self.accountMode.enabled = YES;
        sender.selected = NO;
    } else {
        self.encParams = [[TRTCVideoEncParam alloc] init];
        self.encParams.resMode = self.resMode.selectedSegmentIndex;
        self.encParams.videoResolution = TRTCVideoResolution_640_480;
        self.encParams.videoBitrate = 500;
        self.encParams.videoFps = 15;
        
        [[TRTCCloud sharedInstance] setGSensorMode:self.gsensorMode.selectedSegmentIndex];
        
        [[TRTCCloud sharedInstance] setVideoEncoderParam:self.encParams];
        
        self.gsensorMode.enabled = NO;
        self.resMode.enabled = NO;
        self.accountMode.enabled = NO;
        
        sender.selected = YES;
        [[TRTCCloud sharedInstance] enterRoom:self.accountParams appScene:TRTCAppSceneLIVE];
    }
    
}

- (IBAction)onRoleMode:(UISegmentedControl *)sender {
    BOOL anchor = sender.selectedSegmentIndex == 0;
    self.gsensorMode.hidden = !anchor;
    self.resMode.hidden = !anchor;
    self.renderMode.hidden = !anchor;
    self.rotationMode.hidden = !anchor;
}

- (void)onEnterRoom:(NSInteger)result {
    if (self.accountMode.selectedSegmentIndex == 0) {
        [[TRTCCloud sharedInstance] startLocalPreview:YES view:self.preView];
        [[TRTCCloud sharedInstance] setLocalViewFillMode:self.renderMode.selectedSegmentIndex];
        [[TRTCCloud sharedInstance] setLocalViewRotation:self.rotationMode.selectedSegmentIndex];
    }
}

- (void)onUserVideoAvailable:(NSString *)userId available:(BOOL)available {
    if (self.accountMode.selectedSegmentIndex == 1) {
        if (available) {
            [[TRTCCloud sharedInstance] startRemoteView:userId view:self.preView];
        } else {
            [[TRTCCloud sharedInstance] stopRemoteView:userId];
        }
    }
}

- (void)onExitRoom:(NSInteger)reason {
    
}

- (IBAction)onGsensorMode:(id)sender {
    
}

- (IBAction)onResMode:(id)sender {
    
}


- (IBAction)onRenderMode:(id)sender {
    if (self.accountMode.selectedSegmentIndex == 0) {
        [[TRTCCloud sharedInstance] setLocalViewFillMode:self.renderMode.selectedSegmentIndex];
    } else {
        [[TRTCCloud sharedInstance] setRemoteViewFillMode:@"anchor" mode:self.renderMode.selectedSegmentIndex];
    }
}

- (IBAction)onRotationMode:(id)sender {
    if (self.accountMode.selectedSegmentIndex == 0) {
        [[TRTCCloud sharedInstance] setLocalViewRotation:self.rotationMode.selectedSegmentIndex];
    } else {
        [[TRTCCloud sharedInstance] setRemoteViewRotation:@"anchor" rotation:self.rotationMode.selectedSegmentIndex];
    }
}


@end
