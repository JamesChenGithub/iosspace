//
//  SearialThread.m
//  RunloopDemo
//
//  Created by AlexiChen on 2020/7/15.
//  Copyright © 2020 cimain. All rights reserved.
//

#import "SearialThread.h"

@interface SearialThread ()

@property (nonatomic, strong) NSRunLoop *threadRunLoop;

@end

@implementation SearialThread

- (instancetype)initWith:(NSString *)name {
    if (self = [super init]) {
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [NSThread detachNewThreadWithBlock:^{
            dispatch_semaphore_signal(sem);
            @autoreleasepool {
                [[NSThread currentThread] setName:name];
                self.threadRunLoop = [NSRunLoop currentRunLoop];
                [self.threadRunLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
                [self.threadRunLoop run];
            }
            NSLog(@"thread loop over");
        }];
        
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        
    }
    return self;
}



- (void)async:(void(^)(void))block {
    [self async:block inMode:NSRunLoopCommonModes];
    
}

- (void)sync:(void(^)(void))block{
    [self sync:block inMode:NSRunLoopCommonModes];
}

- (void)async:(void(^)(void))block inMode:(NSString *)mode {
    if (block && self.threadRunLoop) {
        if (mode.length == 0) {
            mode = NSDefaultRunLoopMode;
        }
        [self.threadRunLoop performInModes:@[mode] block:block];
    }
}
- (void)sync:(void(^)(void))block inMode:(NSString *)mode {
    if (block && self.threadRunLoop) {
        if (mode.length == 0) {
            mode = NSDefaultRunLoopMode;
        }
        dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        [self.threadRunLoop performInModes:@[mode] block:^{
            if (block) {
                block();
            }
            dispatch_semaphore_signal(sem);
        }];
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    }
}


@end
