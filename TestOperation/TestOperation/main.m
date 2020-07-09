//
//  main.m
//  TestOperation
//
//  Created by AlexiChen on 2020/6/16.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

typedef void (^MyBlock)(void);

void (^globalblock)(void) = ^{
    NSLog(@"self = %@", globalblock);
};

void (^globalblock2)(void) = ^{
    NSLog(@"self = %@", @"aaa");
};

int main(int argc, char * argv[]) {
    
    
    
    
    
//    {
//        NSLog(@"%@", globalblock);
//        NSLog(@"%@", globalblock2);
//        MyBlock b = globalblock;
//        NSLog(@"%@", b);
//    }
    
//    {
//        void (^block)(void) = ^{
//            NSLog(@"hello");
//        };
//        MyBlock b = block;
//        NSLog(@"%@", block);
//        NSLog(@"%@", b);
//        NSLog(@"%@", ^{
//            NSLog(@"hello");
//        });
//    }
    
//    {
//        int a = 10;
//        void (^block)(void) = ^{
//            NSLog(@"hello, %d", a);
//        };
//        MyBlock b = block;
//        NSLog(@"%@", b);
//        NSLog(@"%@", block);
//        NSLog(@"%@", ^{
//            NSLog(@"hello, %d", a);
//        });
//    }

//    {
//        __block int a = 10;
//        void (^block)(void) = ^{
//            NSLog(@"hello, %d", ++a);
//        };
//        MyBlock b = block;
//                NSLog(@"%@", b);
//        NSLog(@"%@", block);
//        NSLog(@"%@", ^{
//            NSLog(@"hello, %d", ++a);
//        });
//    }
//    {
//        __block int a = 10;
//        void (^block)(void) = ^{
//            printf("test - %d", a);
//        };
//        block();
//    }
//
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
