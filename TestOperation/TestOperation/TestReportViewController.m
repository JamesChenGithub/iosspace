//
//  TestReportViewController.m
//  TestOperation
//
//  Created by AlexiChen on 2020/6/18.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "TestReportViewController.h"

@interface TestReportViewController ()

@property (nonatomic, weak) IBOutlet UIButton  *report;
@property (nonatomic, weak) IBOutlet UIButton  *suspend;
@property (nonatomic, weak) IBOutlet UITextView  *logView;
@property (nonatomic, assign) NSInteger reportId;
@property (nonatomic, assign) BOOL suspending;


@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_semaphore_t suspendSem;


@end

@implementation TestReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    int a = 10;
    void (^block)(void) = ^{
        NSLog(@"self %d", a);
    };
    block();
    
    // Do any additional setup after loading the view.
    self.serialQueue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
    self.logView.layoutManager.allowsNonContiguousLayout = NO;
    self.suspendSem = dispatch_semaphore_create(1);
}

//- (IBAction)onReport:(UIButton *)btn {
// 方案1 :
//    NSString *log = [NSString stringWithFormat:@"事件 : %d", (int)self.reportId];
//    self.reportId++;
//    [btn setTitle:[NSString stringWithFormat:@"Report : %d", (int)self.reportId] forState:UIControlStateNormal];
//    dispatch_async(self.serialQueue, ^{
//        NSLog(@"发送上报 ：%@", log);
//
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            usleep(1000 * (arc4random() % 1000));
//            dispatch_async(dispatch_get_main_queue(), ^{
//                NSString *donTxt = [NSString stringWithFormat:@"发送上报成功 ：%@", log];
//                NSLog(@"%@", donTxt);
//                self.logView.text = [NSString stringWithFormat:@"%@%@\n", self.logView.text,donTxt];
//                [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 1)];
//            });
//
//        });
//    });
//}


- (IBAction)onReport:(UIButton *)btn {
    self.reportId++;
    NSString *log = [NSString stringWithFormat:@"事件 : %d", (int)self.reportId];
    [btn setTitle:[NSString stringWithFormat:@"Report : %d", (int)self.reportId] forState:UIControlStateNormal];
    

    dispatch_async(self.serialQueue, ^{
        
        int maxtry = 4;
        int hastry = 0;
        __block BOOL succ = NO;
        do {
            
            if (self.suspending) {
                dispatch_semaphore_wait(self.suspendSem, DISPATCH_TIME_FOREVER);
            }
            
            hastry++;
            NSLog(@"发送上报 ：%@, %d", log, hastry);
            dispatch_group_t group = dispatch_group_create();
            dispatch_group_enter(group);
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                int sleepus = 1000 * (arc4random() % 1000);
                usleep(sleepus);
                dispatch_group_leave(group);
                succ = (arc4random() % maxtry ) > 1;
            });
            
            dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
            
        } while (!succ && hastry < maxtry);
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *donTxt = [NSString stringWithFormat:@"上报结果 : %@ : %@", succ?@"成功" : @"失败", log];
            NSLog(@"%@", donTxt);
            self.logView.text = [NSString stringWithFormat:@"%@%@\n", self.logView.text,donTxt];
            [self.logView scrollRangeToVisible:NSMakeRange(self.logView.text.length, 1)];
        });
        
    });
}

- (IBAction)onSusppend:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        dispatch_suspend(self.serialQueue);
        self.suspending = YES;
        
    } else {
        dispatch_resume(self.serialQueue);
        self.suspending = NO;
        dispatch_semaphore_signal(self.suspendSem);
    }
    
}

@end
