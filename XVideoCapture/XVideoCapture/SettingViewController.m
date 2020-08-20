//
//  SettingViewController.m
//  XVideoCapture
//
//  Created by 陈耀武 on 2020/8/14.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)onSwitchCamera:(UIButton *)sender {
    
    _vidooCamera;
    sender.selected = !sender.selected;
    
}

@end
