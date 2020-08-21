//
//  ViewController.m
//  MetalRenderContext
//
//  Created by 陈耀武 on 2020/8/21.
//  Copyright © 2020 陈耀武. All rights reserved.
//

#import "TriangleViewController.h"
#import "MetalRenderView.h"
#import "MetalRender.h"

@interface TriangleRender : MetalRender

@end

@implementation TriangleRender



@end

@interface TriangleViewController ()

@property (nonatomic, strong) TriangleRender *render;

@end
@implementation TriangleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSStringFromClass(self.class);
    self.view.backgroundColor = [UIColor lightGrayColor];
    // Do any additional setup after loading the view.
    
    MetalRenderView *view = (MetalRenderView *)self.view;
    self.render = [[TriangleRender alloc] initWithLayer:view.metalLayer andContext:[MetalRenderContext sharedContext].metalDevice vertextFunc:nil fragementFunc:nil];
    
    [self.render draw];
}


@end
