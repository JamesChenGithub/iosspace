//
//  KVOTest.h
//  RunloopDemo
//
//  Created by AlexiChen on 2020/7/15.
//  Copyright © 2020 cimain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;

@end

@interface Teacher : Person

@property (nonatomic, assign) NSInteger grade;

@end

NS_ASSUME_NONNULL_END
