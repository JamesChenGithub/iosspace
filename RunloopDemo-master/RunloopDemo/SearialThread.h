//
//  SearialThread.h
//  RunloopDemo
//
//  Created by AlexiChen on 2020/7/15.
//  Copyright © 2020 cimain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearialThread : NSObject

- (instancetype)initWith:(NSString *)name;
- (void)async:(void(^)(void))block;
- (void)sync:(void(^)(void))block;

@end

NS_ASSUME_NONNULL_END
