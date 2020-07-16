//
//  ViewController.m
//  TestOperation
//
//  Created by AlexiChen on 2020/6/16.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"

@interface LogItem : NSOperation

@property (nonatomic, assign) int logId;
@property (nonatomic, assign) int retry;
@property (nonatomic, assign, getter=isExecuting) BOOL executing;
@property (nonatomic, assign, getter=isFinished) BOOL finished;
@property (nonatomic, assign, getter=isCancelled) BOOL cancelled;

@end

@implementation LogItem

@synthesize finished = _finished;
@synthesize executing = _executing;
@synthesize cancelled = _cancelled;

- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

//- (void)setReady:(BOOL)ready {
//    [self willChangeValueForKey:@"isReady"];
//    _ready = ready;
//    [self didChangeValueForKey:@"isReady"];
//}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setCancelled:(BOOL)cancelled {
    [self willChangeValueForKey:@"isCancelled"];
    _cancelled = cancelled;
    [self didChangeValueForKey:@"isCancelled"];
}


//- (BOOL)isAsynchronous {
//    return YES;
//}

- (void)start {
    
    if (self.isCancelled) {
        self.finished = YES;
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"logItem doAction : %d", self.logId);
        [NSThread sleepForTimeInterval:0.2];
        
        if (self.logId > 0 && self.logId % 2 == 0) {
            self.retry++;
            
            if (self.retry > 3) {
                self.cancelled = YES;
                self.finished = YES;
                self.executing = NO;
                NSLog(@"logItem doAction cancel : %d, %d", self.logId, self.retry);
            } else {
                [self start];
                NSLog(@"logItem doAction retry : %d, %d", self.logId, self.retry);
            }
        } else {
            NSLog(@"logItem doAction done : %d", self.logId);
            
            self.finished = YES;
            self.executing = NO;
        }
        
    });
    self.executing = YES;
}

@end


@interface ViewController ()

@property (nonatomic, strong) NSOperationQueue *reportQueue;

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t concurrentQueue;
@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, strong) dispatch_queue_t serialQueue1;
@property (nonatomic, strong) dispatch_queue_t serialQueue2;

@property (nonatomic, strong) dispatch_block_t testblock;
@property (nonatomic, assign) int testIndex;

@end



@implementation ViewController

static void *serialQueue1Key;

- (void)callApi:(void (^)(void))block {
    [self runSyncOnserialQueue1:block];
}

- (void)asyncCallApi:(void (^)(void))block {
    [self runAsyncOnserialQueue1:block];
}

- (void)runSyncOnserialQueue1:(void (^)(void))block {
    if (dispatch_get_specific(serialQueue1Key)) {
        block();
    } else {
        dispatch_sync(_serialQueue1, block);
    }
}
- (void)runAsyncOnserialQueue1:(void (^)(void))block {
    if (dispatch_get_specific(serialQueue1Key)) {
        block();
    } else {
        dispatch_async(_serialQueue1, block);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    {
//        dispatch_queue_t block_serialQueue = dispatch_queue_create("com.block_serialQueue.com", DISPATCH_QUEUE_SERIAL);
//        dispatch_block_t block = dispatch_block_create(0, ^{
//            [NSThread sleepForTimeInterval:5.f];
//            NSLog(@"block_serialQueue block end");
//        });
//
//        dispatch_async(block_serialQueue, block);
//        //设置DISPATCH_TIME_FOREVER会一直等到前面任务都完成
//        dispatch_block_wait(block, DISPATCH_TIME_FOREVER);
//
//        NSLog(@"test dispatch_block_wait");
//
//
//
//        block = dispatch_block_create(0, ^{
//            NSLog(@"second block_serialQueue block end");
//        });
//        dispatch_async(block_serialQueue, block);
//        dispatch_block_notify(block, dispatch_get_main_queue(), ^{
//            NSLog(@"block_serialQueue block finished");
//        });
////        return;
//    }
    
    {
        self.testblock = dispatch_block_create(DISPATCH_BLOCK_DETACHED, ^{
            NSLog(@"block begin");
            [NSThread sleepForTimeInterval:6];
            self.testIndex++;
            NSLog(@"block end");
        });
        
        dispatch_queue_t sq = dispatch_queue_create("grouptest", DISPATCH_QUEUE_CONCURRENT);
        
//        dispatch_apply(100, sq, ^(size_t i) {
//            self.testblock();
//        });
//        for (int i = 0; i < 100; i++)
        {
            dispatch_async(sq, self.testblock);
        }
    
        //设置DISPATCH_TIME_FOREVER会一直等到前面任务都完成
       
        NSLog(@"dispatch_block_notify =======");
       
        
        dispatch_block_notify(self.testblock, dispatch_get_main_queue(), ^{
            NSLog(@"block finished");
        });
        
        dispatch_block_wait(self.testblock, DISPATCH_TIME_FOREVER);
               NSLog(@"dispatch_block_wait =======");
        
        
//        block = dispatch_block_create(0, ^{
//            NSLog(@"second block_serialQueue block end");
//        });
//        dispatch_async(block_serialQueue, block);
//        dispatch_block_notify(block, dispatch_get_main_queue(), ^{
//            NSLog(@"block_serialQueue block finished");
//        });
        
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            NSLog(@"self.testIndex = %d", self.testIndex);
//        });
        return;
    }

    {
        
        dispatch_queue_t sq = dispatch_queue_create("grouptest", DISPATCH_QUEUE_SERIAL);
    
        for (int i = 0; i < 10; i++) {
        dispatch_async(sq, ^{
//            usleep(NSEC_PER_MSEC);
            NSLog(@"dispatch_suspend 前 async : %d", i);
        });
        }
        
        NSLog(@"测试 dispatch_suspend");
        dispatch_suspend(sq);
        
        for (int i = 10; i < 20; i++) {
            dispatch_async(sq, ^{
                NSLog(@"dispatch_suspend async : %d", i);
            });
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"dispatch_resume");
            dispatch_resume(sq);
        });
        
        
    }
    
    return;
    
    {
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t cq = dispatch_queue_create("grouptest", DISPATCH_QUEUE_CONCURRENT);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"for dispatch_group_async group to cq begin");
            for (int i = 0; i < 100; i++) {
                dispatch_group_enter(group);
                dispatch_group_async(group, cq, ^{
                    usleep(1000*1000 * 10);
                    NSLog(@"i : %d", i);
                    dispatch_group_leave(group);
                });
            }
            NSLog(@"for dispatch_group_async group to cq end");
            
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC));
                NSLog(@"for dispatch_group_wait group log.....");
                NSLog(@"for dispatch_async wait 5秒通知主线程.....");
//            });
            
            
                
            
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                NSLog(@"for dispatch_group_notify end");
            });
        
            
        });
        
        
    }
    return;
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t sq = dispatch_queue_create("grouptest", DISPATCH_QUEUE_CONCURRENT);
    
    
    dispatch_async(sq, ^{
        NSLog(@"测试group begin");
        for (int i = 0; i < 100; i++) {
            dispatch_group_enter(group);
            dispatch_async(sq, ^{
                NSLog(@"测试group >>>>>>> %d", i);
                usleep(1000 * 1000 * (i%5));
                dispatch_group_leave(group);
                NSLog(@"测试group >>>>>>> %d  leave", i);
            });
        }
        NSLog(@"测试group end");
        dispatch_async(sq, ^{
            dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC));
            NSLog(@"dispatch_group_wait =============================结束");
        });
       
        
//        NSLog(@"测试group2222 begin");
//        for (int i = 200; i < 1000; i++) {
//            dispatch_group_enter(group);
//            dispatch_async(sq, ^{
//                usleep(2000 * 1000 * (i%10));
//                NSLog(@"测试group2222 <<<<<<<<<<<<<<<< %d", i);
//                dispatch_group_leave(group);
//            });
//        }
//        NSLog(@"测试group222 end");
//        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//               NSLog(@"测试group222 <<<<<<<<<<<<<<<<<<<< main");
//        });
    });
    
    
       
        
   

    
    return;
//    dispatch_queue_t global_queue = dispatch_get_global_queue(0, 0);
    dispatch_queue_t global_queue = dispatch_queue_create("test", DISPATCH_QUEUE_CONCURRENT);
    
    int count = 15;
    for (int i = 0; i < count; i++) {
        DISPATCH_QUEUE_PRIORITY_DEFAULT;
        dispatch_async(global_queue, ^{
            NSLog(@" i = %d, [%@]", i, [NSThread currentThread]);
            usleep(i);
        });
    }
    
    dispatch_barrier_sync(global_queue, ^{
        NSLog(@" barrier");
    });
    
    for (int i = count; i < 2*count; i++) {
        dispatch_async(global_queue, ^{
            NSLog(@" i = %d, [%@]", i, [NSThread currentThread]);
        });
    }
   
    
    return;
    
    dispatch_queue_t targetQueue = dispatch_queue_create("test.target.queue", DISPATCH_QUEUE_CONCURRENT);
    dispatch_queue_t queue1 = dispatch_queue_create("test.1", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue2 = dispatch_queue_create("test.2", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t queue3 = dispatch_queue_create("test.3", DISPATCH_QUEUE_SERIAL);
    
    dispatch_set_target_queue(queue1, targetQueue);
    dispatch_set_target_queue(queue2, targetQueue);
    dispatch_set_target_queue(queue3, targetQueue);
    
    dispatch_async(queue1, ^{
        NSLog(@"1 in");
        [NSThread sleepForTimeInterval:0.3];
        NSLog(@"1 out");
    });
    
    dispatch_async(queue2, ^{
        NSLog(@"2 in");
        [NSThread sleepForTimeInterval:0.3];
        NSLog(@"2 out");
    });
    
    dispatch_async(queue3, ^{
        NSLog(@"3 in");
        [NSThread sleepForTimeInterval:0.3];
        NSLog(@"3 out");
    });
    
    return;
    
    self.serialQueue = dispatch_queue_create("test_target_queue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t lowqueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_set_target_queue(self.serialQueue, lowqueue);
    
    dispatch_async(self.serialQueue, ^{
        NSLog(@"我是低优先级，先让让");
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"我是高优先级，先执行");
    });
    
    return;
    serialQueue1Key = &serialQueue1Key;
    
    NSLog(@"serialQueue1Key = %p , %p", serialQueue1Key, &serialQueue1Key);
    
    self.serialQueue1 = dispatch_queue_create("test1", DISPATCH_QUEUE_SERIAL);
    self.serialQueue2 = dispatch_queue_create("test2", DISPATCH_QUEUE_SERIAL);
    
   
    dispatch_queue_set_specific(self.serialQueue1, serialQueue1Key, (__bridge void *)self, NULL);
    void *val = dispatch_queue_get_specific(self.serialQueue1, serialQueue1Key);
    if (self == val) {
        NSLog(@"serialQueue1Key is self");
    }
    
    NSLog(@"self = %p", self);
    
    dispatch_async(self.serialQueue2, ^{
           void *ptr = dispatch_get_specific(serialQueue1Key);
           NSLog(@"self.serialQueue2 ptr = %p", ptr);
       });
       
       dispatch_async(self.serialQueue1, ^{
           void *ptr = dispatch_get_specific(serialQueue1Key);
           NSLog(@"self.serialQueue1 ptr = %p", ptr);
       });
       
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (NSInteger i = 0; i < 100; i++) {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                
                if (dispatch_get_specific(serialQueue1Key)) {
                    void *ptr = dispatch_get_specific(serialQueue1Key);
                    NSLog(@"self.serialQueue1 ptr = %p", ptr);
                } else {
                    dispatch_sync(self.serialQueue1, ^(){
                        void *ptr = dispatch_get_specific(serialQueue1Key);
                        NSLog(@"self.serialQueue1 ptr = %p", ptr);
                    });
                }
                usleep(1000);
            });
        }
    });
    
    
    
    return;
    
    //    self.reportQueue = [[NSOperationQueue alloc] init];
    //    self.reportQueue.maxConcurrentOperationCount = 1;
    //
    //    for (int i = 0; i < 10; i++) {
    //        LogItem *item = [[LogItem alloc] init];
    //        item.logId = i;
    //        [self.reportQueue addOperation:item];
    ////        item.ready = YES;
    //    }
    
    // Do any additional setup after loading the view.
    
//    {
//    self.serialQueue = dispatch_queue_create("test", DISPATCH_QUEUE_SERIAL);
//    NSLog(@"[%@]", [NSThread currentThread]);
//    dispatch_sync(self.serialQueue, ^{
//        NSLog(@"[%@]", [NSThread currentThread]);
//    });
//
//    dispatch_async(self.serialQueue, ^{
//        NSLog(@"[%@]", [NSThread currentThread]);
////        dispatch_sync(self.serialQueue, ^{
////            NSLog(@"[%@]", [NSThread currentThread]);
////        });
//    });
    
//    dispatch_apply(10, self.serialQueue, ^(size_t index) {
//        NSLog(@"dispatch_apply : %d [%@] ", index, [NSThread currentThread]);
//    });
//
//    dispatch_barrier_async(self.serialQueue, ^{
//        NSLog(@"dispatch_barrier_async : %@", [NSThread currentThread]);
//    });
//
//    dispatch_apply(20, self.serialQueue, ^(size_t index) {
//        NSLog(@"dispatch_apply : %d [%@] ", 200 + index, [NSThread currentThread]);
//    });
    
//    dispatch_barrier_sync(self.serialQueue, ^{
//        NSLog(@"dispatch_barrier_sync : [%@]", [NSThread currentThread]);
//    });
    
//
//
//        for (int i = 0; i<100; i++) {
//            dispatch_async(self.serialQueue, ^{
//                NSLog(@"%d : [%@]", i, [NSThread currentThread]);
//            });
//            //        usleep( i * 1000 * 500);
//        }
//
//        for (int i = 0; i<10; i++) {
//            dispatch_async(self.serialQueue, ^{
//                NSLog(@"%d : [%@]", i, [NSThread currentThread]);
//            });
//            usleep( i * 1000 * 500);
//        }
//    }
    {
        self.lock = [[NSLock alloc] init];
//
        self.concurrentQueue = dispatch_queue_create("concurrent", DISPATCH_QUEUE_CONCURRENT);
        const char *name = dispatch_queue_get_label(self.concurrentQueue);
        
        NSLog(@"for cal begin");
        int sum = 0;
        for (int i = 1; i < 1000; i++) {
            for (int j = 1; j <= i; j++) {
                sum += j;
            }
        }
        NSLog(@"for cal end = %d", sum);
        
        __block int applySum = 0;
        NSLog(@"for dispatch_apply begin");
        dispatch_apply(1000, self.concurrentQueue, ^(size_t index) {
            int sum = 0;
            for (int j = 1; j <= index; j++) {
                sum += j;
            }
            applySum += sum;
        });
        
        NSLog(@"for dispatch_apply end = %d", applySum);
//        NSLog(@"after dispatch_apply");
//        dispatch_async(self.concurrentQueue, ^{
//            NSLog(@"dispatch_async task");
//        });
//
//        NSLog(@"after dispatch_async");
//        dispatch_barrier_sync(self.concurrentQueue, ^{
//            NSLog(@"dispatch_barrier_async : %@", [NSThread currentThread]);
//        });
//
//        dispatch_apply(200, self.concurrentQueue, ^(size_t index) {
//            NSLog(@"dispatch_apply : %d [%@] ", 200 + index, [NSThread currentThread]);
//            usleep(100 *index);
//        });
        
//        NSLog(@"[%@]", [NSThread currentThread]);
//
//        dispatch_sync(self.concurrentQueue, ^{
//            NSLog(@"[%@]", [NSThread currentThread]);
//        });
//        for (int i = 0; i<100; i++) {
//            dispatch_async(self.concurrentQueue, ^{
//                [self.lock lock];
//                NSLog(@"%d : [%@]", i, [NSThread currentThread]);
//                [self.lock unlock];
//                usleep( 1000 * 10);
//            });
//
//        }
        
//        for (int i = 0; i<100; i++) {
//            dispatch_async(self.concurrentQueue, ^{
//                NSLog(@"%d : [%@]", i, [NSThread currentThread]);
//                usleep( 1000 * 10);
//            });
//
//        }
    }
}


@end
