//
//  ViewController.m
//  MetalImage
//
//  Created by 陈耀武 on 2020/8/19.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "ViewController.h"
#import "MetalImageFilterView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    MetalImageFilterView *view = (MetalImageFilterView *)self.view;
    view.fillMode = kMetalImageFilterViewFillModePreserveAspectRatio;
    // Do any additional setup after loading the view.
}

@end
