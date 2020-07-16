//
//  ViewController.m
//  WRTCDemo
//
//  Created by AlexiChen on 2020/6/30.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"

#import "WebRtcView.h"
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>

@interface ViewController ()

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation ViewController

- (void)onPlayMusic:(UIButton *)btn {
    if (self.audioPlayer == nil) {
        NSString *mp3path = [[NSBundle mainBundle] pathForResource:@"seve" ofType:@"mp3"];
        NSError *error = nil;
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:mp3path] error:&error];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.audioPlayer play];
        });
        
    } else {
        if ([self.audioPlayer isPlaying]) {
            [self.audioPlayer pause];
        } else {
            [self.audioPlayer play];
        }
    }
    btn.selected = !btn.selected;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSArray *webrtcUrlArray = @[@"webrtc://29734.liveplay.myqcloud.com/live/1400317175_1000056831_alexichen_main?txSecret=fd862733eda4421263b39ff02a38e9f4&txTime=5EFBB1AA",
                                @"webrtc://29734.liveplay.myqcloud.com/live/1400317175_1000056831_alexichen_aux?txSecret=e6134607f1bb6b8b75ae7a473b18d0e3&txTime=5EFBB1AA",
                                ];
    
    
    
    CGRect rect = self.view.bounds;
    
    CGRect webRect = rect;
    webRect.size.height = webRect.size.width * 0.618;
    WKWebView *webView = [[WKWebView alloc] initWithFrame:webRect];
    [self.view addSubview:webView];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:path];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [webView loadRequest:request];
    
    rect.origin.y = webRect.size.height;
    rect.size.height -= webRect.size.height;
    CGRect itemRect = rect;
    
    

    
    
    NSInteger count = webrtcUrlArray.count;// + 1;
    if (count == 1) {
        
    } else if(count == 2) {
        itemRect.size.height /=2;
    } else if(count > 2) {
        itemRect.size.width /=2;
        NSInteger row = count % 2 == 1 ? count/2 + 1 : count/2;
        itemRect.size.height /= row;
    }
    
    for (NSString *url in webrtcUrlArray) {
        WebRtcView *view = [[WebRtcView alloc] initWith:url];
        view.frame = itemRect;
        [self.view addSubview:view];
        
        if (itemRect.origin.x + itemRect.size.width + itemRect.size.width > rect.size.width + rect.origin.x) {
            itemRect.origin.x = 0;
            itemRect.origin.y += itemRect.size.height;
        } else {
            itemRect.origin.x += itemRect.size.width;
        }
    }
    //    UIButton *playMp3 = [[UIButton alloc] init];
    //    [playMp3 setBackgroundColor:[UIColor orangeColor]];
    //    [playMp3 setTitle:@"播放Mp3" forState:UIControlStateNormal];
    //    [playMp3 setTitle:@"停止Mp3" forState:UIControlStateSelected];
    //    [playMp3 addTarget:self action:@selector(onPlayMusic:) forControlEvents:UIControlEventTouchUpInside];
    //    [self.view addSubview:playMp3];
//    playMp3.frame = itemRect;
    
    
}


@end
