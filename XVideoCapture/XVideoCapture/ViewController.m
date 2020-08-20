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
#import "SettingViewController.h"

@interface ViewController () {
    XVideoCamera *_videoCamera;
}
@property (nonatomic, strong) SettingViewController *actionVC;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    UIViewController *viewController = [[UIStoryboard storyboardWithName:@"Main"
                               bundle:NULL] instantiateViewControllerWithIdentifier:@"SettingViewController"];

    
    self.actionVC = (SettingViewController *)viewController;
    WEAKIFY(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        STRONGIFY_OR_RETURN(self);
        self->_videoCamera = [[XVideoCamera alloc] init];
        [self->_videoCamera startCaptureInView:self.view fillMode:AVLayerVideoGravityResizeAspect];
    });
    
}


- (IBAction)onShowSetting:(UIBarButtonItem *)sender {
    
    
    //   CGRect rect = self.view.bounds;
    //    rect.size.width = 160;
    //    rect.origin.x = self.view.bounds.size.width - rect.size.width;
    //    self.actionVC.view.frame = rect;
    [UIView animateWithDuration:0.3 animations:^{
        if (self.childViewControllers.count > 0) {
            [self.actionVC willMoveToParentViewController:nil];
            [self.actionVC.view removeFromSuperview];
            [self.actionVC removeFromParentViewController];
            sender.title = @"VK Step";
        } else {
            UIView *view = [self.actionVC view];
            [self.actionVC willMoveToParentViewController:self];
            [self addChildViewController:self.actionVC];
            [self.view addSubview:view];
            [self.actionVC didMoveToParentViewController:self];
            self.actionVC.view.translatesAutoresizingMaskIntoConstraints = NO;
            
            NSDictionary *viewsDictionary = @{@"actionview":self.actionVC.view};
            NSArray *constraint_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[actionview(160)]" options:0 metrics:nil views:viewsDictionary];
            [self.actionVC.view addConstraints:constraint_H];
            
            int topspace = 64;
            UIUserInterfaceIdiom dev = [[UIDevice currentDevice] userInterfaceIdiom];
            UIInterfaceOrientation direct = [UIApplication sharedApplication].statusBarOrientation;
            if (dev == UIUserInterfaceIdiomPhone && (direct == UIInterfaceOrientationLandscapeLeft || direct == UIInterfaceOrientationLandscapeRight)) {
                topspace = 40;
            }
            
            NSString *vf = [NSString stringWithFormat:@"V:|-%d-[actionview]-0-|", topspace];
            NSArray *vcon = [NSLayoutConstraint constraintsWithVisualFormat:vf options:0 metrics:nil views:viewsDictionary];
            NSArray *hcon = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[actionview]-0-|" options:0 metrics:nil views:viewsDictionary];
            
            [self.view addConstraints:vcon];
            [self.view addConstraints:hcon];
            self.actionVC.view.backgroundColor = [UIColor lightGrayColor];
        }
    }];
    
}


@end
