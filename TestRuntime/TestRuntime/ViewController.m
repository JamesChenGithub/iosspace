//
//  ViewController.m
//  TestRuntime
//
//  Created by AlexiChen on 2020/7/16.
//  Copyright © 2020 AlexiChen. All rights reserved.
//

#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@interface Speaker : NSObject
@property (nonatomic, copy) NSString *name;
- (void)speak;
@end

@implementation Speaker
- (void)speak {
    NSLog(@"Speaker's name: %@", self.name);
}
- (void)speak2 {
    NSLog(@"speak2");
}
@end

@implementation ViewController

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    // Do any additional setup after loading the view.
////    NSString *trst = @"name";
//    id cls = [Speaker class];
//    void *obj = &cls;
////    NSLog(@"栈区变量");
////    void *start = (void *)&self;
////    void *end = (void *)&obj;
////    long count = ((long)start - (long)end) / 0x8;
////    for (long i = 0; i < count; i++) {
////        void *address = (void *)((long)start - 0x8 * i);
////        if (i == 1) {
////            NSLog(@"%p: %s", address, *(char **)(address));
////        } else {
////            NSLog(@"%p: %@", address, *(void **)address);
////        }
////    }
////    NSLog(@"obj speak");
//    [(__bridge id)obj speak];
//}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    unsigned int count = 0;
    objc_objectptr_t *prolist = class_copyPropertyList([Speaker class], &count);
    for (unsigned int i =0; i < count; i++) {
        const char *properName = property_getName(prolist[i]);
        const char *att = property_getAttributes(prolist[i]);
        NSLog(@"property : %@ , %@", [NSString stringWithUTF8String:properName], [NSString stringWithUTF8String:att]);
    }
    
    Method *methodlist = class_copyMethodList([Speaker class], &count);
    for (unsigned int i =0; i < count; i++) {
        Method method = methodlist[i];
        NSLog(@"method ====> %@", NSStringFromSelector(method_getName(method)));
    }
}

@end
